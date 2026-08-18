"""
FastAPI backend that serves Healing_Outcome predictions from the trained
XGBoost model.

Run:
    uvicorn main:app --reload --host 0.0.0.0 --port 5000

Interactive docs:
    http://localhost:5000/docs      (Swagger UI)
    http://localhost:5000/redoc     (ReDoc)

Endpoints:
    GET  /health          -> service + model status check
    GET  /metadata         -> expected input fields, categories, classes
    POST /predict          -> predict healing outcome for one patient
    POST /predict/batch     -> predict for a list of patients
"""

import os
import json
from enum import Enum
from typing import List, Optional, Dict

import joblib
import numpy as np
import pandas as pd
import xgboost as xgb
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, ConfigDict, Field

MODEL_DIR = os.path.join(os.path.dirname(__file__), "..", "model")

app = FastAPI(
    title="Periodontal Surgery Healing Outcome API",
    description="Predicts Healing_Outcome (Excellent / Good / Fair / Poor) "
    "after periodontal surgery from patient clinical features, using a "
    "trained XGBoost classifier.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten this for production
    allow_methods=["*"],
    allow_headers=["*"],
)

# ------------------------------------------------------------------
# Load model + preprocessing artifacts once at startup
# ------------------------------------------------------------------
model = xgb.XGBClassifier()
model.load_model(os.path.join(MODEL_DIR, "xgb_model.json"))

label_encoder = joblib.load(os.path.join(MODEL_DIR, "label_encoder.pkl"))
feature_encoders = joblib.load(os.path.join(MODEL_DIR, "feature_encoders.pkl"))

with open(os.path.join(MODEL_DIR, "feature_columns.json")) as f:
    FEATURE_COLUMNS = json.load(f)

CATEGORICAL_COLS = list(feature_encoders.keys())
NUMERIC_COLS = [c for c in FEATURE_COLUMNS if c not in CATEGORICAL_COLS]

VALID_CATEGORIES = {col: list(enc.classes_) for col, enc in feature_encoders.items()}
CLASSES = list(label_encoder.classes_)


# ------------------------------------------------------------------
# Pydantic models — this is what gives FastAPI automatic validation
# and the interactive /docs page
# ------------------------------------------------------------------
SexEnum = Enum("SexEnum", {v: v for v in VALID_CATEGORIES["Sex"]})
DiabetesEnum = Enum("DiabetesEnum", {v: v for v in VALID_CATEGORIES["Diabetes_Status"]})
BleedingEnum = Enum("BleedingEnum", {v: v for v in VALID_CATEGORIES["Bleeding_On_Probing"]})
ProcedureEnum = Enum(
    "ProcedureEnum", {v.replace(" ", "_"): v for v in VALID_CATEGORIES["Surgical_Procedure"]}
)


class PatientInput(BaseModel):
    Age: float = Field(..., ge=0, le=120, description="Patient age in years")
    Sex: SexEnum
    Diabetes_Status: DiabetesEnum
    Probing_Depth_mm: float = Field(..., ge=0, description="Probing depth in mm")
    Clinical_Attachment_Loss_mm: float = Field(..., ge=0, description="Clinical attachment loss in mm")
    Gingival_Index: float = Field(..., ge=0, description="Gingival index score")
    Plaque_Index: float = Field(..., ge=0, description="Plaque index score")
    Bleeding_On_Probing: BleedingEnum
    Surgical_Procedure: ProcedureEnum

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "Age": 55,
                "Sex": "Female",
                "Diabetes_Status": "No",
                "Probing_Depth_mm": 4.5,
                "Clinical_Attachment_Loss_mm": 5.0,
                "Gingival_Index": 2.1,
                "Plaque_Index": 1.8,
                "Bleeding_On_Probing": "No",
                "Surgical_Procedure": "Flap Surgery",
            }
        }
    )


class PredictionResult(BaseModel):
    predicted_outcome: str
    confidence: float
    probabilities: dict


class BatchResultItem(BaseModel):
    predicted_outcome: Optional[str] = None
    confidence: Optional[float] = None
    probabilities: Optional[dict] = None
    error: Optional[str] = None
    index: Optional[int] = None


class HealthResponse(BaseModel):
    model_config = ConfigDict(protected_namespaces=())

    status: str
    model_loaded: bool
    classes: List[str]


class MetadataResponse(BaseModel):
    numeric_fields: List[str]
    categorical_fields: dict
    output_classes: List[str]
    example_payload: dict


# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------
def encode_record(record: PatientInput) -> pd.DataFrame:
    data = record.model_dump()
    row = {}
    for col in NUMERIC_COLS:
        row[col] = float(data[col])
    for col in CATEGORICAL_COLS:
        raw_val = data[col].value if hasattr(data[col], "value") else data[col]
        row[col] = feature_encoders[col].transform([raw_val])[0]
    return pd.DataFrame([row], columns=FEATURE_COLUMNS)


def predict_row(df_row: pd.DataFrame) -> dict:
    probs = model.predict_proba(df_row)[0]
    pred_idx = int(np.argmax(probs))
    return {
        "predicted_outcome": CLASSES[pred_idx],
        "confidence": round(float(probs[pred_idx]), 4),
        "probabilities": {CLASSES[i]: round(float(p), 4) for i, p in enumerate(probs)},
    }


# ------------------------------------------------------------------
# Routes
# ------------------------------------------------------------------
@app.get("/", tags=["Status"])
def root():
    return {
        "message": "Welcome to Periodontal Surgery Healing Outcome API",
        "docs": "/docs",
        "health": "/health",
        "metadata": "/metadata",
    }


@app.get("/health", response_model=HealthResponse, tags=["Status"])
def health():
    return {"status": "ok", "model_loaded": True, "classes": CLASSES}


@app.get("/metadata", response_model=MetadataResponse, tags=["Status"])
def metadata():
    return {
        "numeric_fields": NUMERIC_COLS,
        "categorical_fields": VALID_CATEGORIES,
        "output_classes": CLASSES,
        "example_payload": {
            "Age": 55,
            "Sex": "Female",
            "Diabetes_Status": "No",
            "Probing_Depth_mm": 4.5,
            "Clinical_Attachment_Loss_mm": 5.0,
            "Gingival_Index": 2.1,
            "Plaque_Index": 1.8,
            "Bleeding_On_Probing": "No",
            "Surgical_Procedure": "Flap Surgery",
        },
    }


@app.post("/predict", response_model=PredictionResult, tags=["Prediction"])
def predict(patient: PatientInput):
    try:
        df_row = encode_record(patient)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
    return predict_row(df_row)


@app.post("/predict/batch", response_model=List[BatchResultItem], tags=["Prediction"])
def predict_batch(patients: List[PatientInput]):
    results = []
    for i, patient in enumerate(patients):
        try:
            df_row = encode_record(patient)
            results.append(predict_row(df_row))
        except Exception as e:
            results.append({"error": str(e), "index": i})
    return results


if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get("PORT", 5000))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=False)
