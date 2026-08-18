"""
Train an XGBoost multi-class classifier to predict periodontal surgery
Healing_Outcome (Excellent / Good / Fair / Poor) from clinical features.

Run:
    python3 train.py

Produces (in this same folder):
    xgb_model.json          -> trained XGBoost model
    label_encoder.pkl       -> encoder for the target classes
    feature_encoders.pkl    -> encoders for categorical input columns
    feature_columns.json    -> exact column order the model expects
    metrics.json            -> evaluation metrics from the held-out test set
"""

import os
import json
import joblib
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
)
import xgboost as xgb

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_PATH = os.path.join(BASE_DIR, "..", "data", "healing_data.csv")
RANDOM_STATE = 42

TARGET_COL = "Healing_Outcome"
CATEGORICAL_COLS = ["Sex", "Diabetes_Status", "Bleeding_On_Probing", "Surgical_Procedure"]
NUMERIC_COLS = [
    "Age",
    "Probing_Depth_mm",
    "Clinical_Attachment_Loss_mm",
    "Gingival_Index",
    "Plaque_Index",
]


def main():
    df = pd.read_csv(DATA_PATH)

    # ---- Encode categorical feature columns ----
    feature_encoders = {}
    for col in CATEGORICAL_COLS:
        le = LabelEncoder()
        df[col] = le.fit_transform(df[col])
        feature_encoders[col] = le

    # ---- Encode target ----
    target_encoder = LabelEncoder()
    y = target_encoder.fit_transform(df[TARGET_COL])

    feature_columns = NUMERIC_COLS + CATEGORICAL_COLS
    X = df[feature_columns]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=RANDOM_STATE, stratify=y
    )

    model = xgb.XGBClassifier(
        objective="multi:softprob",
        num_class=len(target_encoder.classes_),
        n_estimators=300,
        max_depth=4,
        learning_rate=0.05,
        subsample=0.8,
        colsample_bytree=0.8,
        eval_metric="mlogloss",
        random_state=RANDOM_STATE,
    )

    model.fit(
        X_train,
        y_train,
        eval_set=[(X_test, y_test)],
        verbose=False,
    )

    # ---- Evaluate ----
    y_pred = model.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    report = classification_report(
        y_test, y_pred, target_names=target_encoder.classes_, output_dict=True
    )
    cm = confusion_matrix(y_test, y_pred).tolist()

    print(f"Test accuracy: {acc:.4f}")
    print(classification_report(y_test, y_pred, target_names=target_encoder.classes_))

    # ---- Feature importance ----
    importances = dict(zip(feature_columns, model.feature_importances_.tolist()))
    importances = dict(sorted(importances.items(), key=lambda x: -x[1]))
    print("\nFeature importances:")
    for k, v in importances.items():
        print(f"  {k}: {v:.4f}")

    # ---- Save artifacts ----
    model.save_model(os.path.join(BASE_DIR, "xgb_model.json"))
    joblib.dump(target_encoder, os.path.join(BASE_DIR, "label_encoder.pkl"))
    joblib.dump(feature_encoders, os.path.join(BASE_DIR, "feature_encoders.pkl"))

    with open(os.path.join(BASE_DIR, "feature_columns.json"), "w") as f:
        json.dump(feature_columns, f, indent=2)

    with open(os.path.join(BASE_DIR, "metrics.json"), "w") as f:
        json.dump(
            {
                "accuracy": acc,
                "classification_report": report,
                "confusion_matrix": cm,
                "classes": target_encoder.classes_.tolist(),
                "feature_importances": importances,
            },
            f,
            indent=2,
        )

    print("\nSaved: xgb_model.json, label_encoder.pkl, feature_encoders.pkl, "
          "feature_columns.json, metrics.json")


if __name__ == "__main__":
    main()
