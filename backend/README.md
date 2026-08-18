# 🦷 PerioHeal AI

> **Clinical Project · August 2026**
> A real-time AI backend for periodontal surgery outcome prediction — powered by XGBoost, FastAPI, and a robust clinical preprocessing pipeline.

---

## 💡 What is PerioHeal AI?

**PerioHeal AI** is a full-stack machine learning backend designed for periodontal clinical research and decision support. It enables dental surgeons and researchers to:

- 🧠 **Predict healing outcomes** using a trained multi-class XGBoost classifier
- 📊 **Receive probabilistic risk scores** across four outcome tiers (*Excellent*, *Good*, *Fair*, *Poor*)
- 🔄 **Submit individual patients or entire cohorts** via REST API for batch processing
- 🛡️ **Trust validated inputs** enforced by strict Pydantic v2 data schemas
- 🌐 **Deploy on the cloud** with pre-configured Render support and Python 3.9.10 pinning

---

## 🔑 Key Features

| Feature | Description |
| :--- | :--- |
| 🤖 XGBoost Classifier | Gradient boosted multi-class predictor trained on 9 clinical parameters |
| 📊 Confidence Scoring | Per-class probability distribution alongside the predicted outcome |
| ✅ Input Validation | Pydantic schemas reject malformed or out-of-range clinical inputs automatically |
| 🔄 Batch Prediction | Submit a JSON array of patients — each row is isolated with individual error handling |
| 🌐 Render Ready | `.python-version` + `render.yaml` for 1-click deployment |
| 📚 Auto Docs | Interactive Swagger UI and ReDoc available out-of-the-box |

---

## 🏗️ System Architecture

```
Patient Clinical Data
        │
        ▼
FastAPI Input Validation (Pydantic)
        │
        ▼
Feature Encoding Pipeline
(Label & Categorical Encoders)
        │
        ▼
XGBoost Multi-Class Classifier
        │
        ▼
Predicted Outcome + Class Probabilities
```

---

## 📂 Project Structure

```
periodontal_backend/
├── app/
│   └── main.py              ← FastAPI server, routes & Pydantic schemas
├── model/
│   ├── train.py             ← Training pipeline & model export
│   ├── xgb_model.json       ← Trained XGBoost weights
│   ├── label_encoder.pkl    ← Target class encoder
│   ├── feature_encoders.pkl ← Categorical feature encoders
│   ├── feature_columns.json ← Canonical feature order
│   └── metrics.json         ← Evaluation report & class importances
├── data/
│   └── healing_data.csv     ← Patient training dataset
├── .python-version          ← Pins Python 3.9.10 for Render
├── render.yaml              ← Render cloud deployment config
└── requirements.txt         ← Production dependencies
```

---

## ⚡ Quick Start

### Install Dependencies

```bash
git clone https://github.com/mithunlingala30/backend.git
cd backend
pip install -r requirements.txt
```

### Train the Model

```bash
python model/train.py
```

### Start the API Server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- **Swagger UI**: http://127.0.0.1:8000/docs
- **ReDoc**: http://127.0.0.1:8000/redoc

---

## 🔌 API Endpoints

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/` | API root & navigation links |
| `GET` | `/health` | Health check & active model classes |
| `GET` | `/metadata` | Feature schema & example payload |
| `POST` | `/predict` | Single patient outcome prediction |
| `POST` | `/predict/batch` | Bulk cohort prediction |

---

## 🧬 Sample Prediction

**Request** (`POST /predict`):
```json
{
  "Age": 55,
  "Sex": "Female",
  "Diabetes_Status": "No",
  "Probing_Depth_mm": 4.5,
  "Clinical_Attachment_Loss_mm": 5.0,
  "Gingival_Index": 2.1,
  "Plaque_Index": 1.8,
  "Bleeding_On_Probing": "No",
  "Surgical_Procedure": "Flap Surgery"
}
```

**Response**:
```json
{
  "predicted_outcome": "Good",
  "confidence": 0.4215,
  "probabilities": {
    "Excellent": 0.2012,
    "Fair": 0.1854,
    "Good": 0.4215,
    "Poor": 0.1919
  }
}
```

---

## 🛠️ Clinical Input Reference

| Parameter | Type | Accepted Values |
| :--- | :--- | :--- |
| Age | numeric | 0 – 120 |
| Sex | enum | `"Female"`, `"Male"` |
| Diabetes_Status | enum | `"No"`, `"Yes"` |
| Probing_Depth_mm | numeric | >= 0.0 |
| Clinical_Attachment_Loss_mm | numeric | >= 0.0 |
| Gingival_Index | numeric | >= 0.0 |
| Plaque_Index | numeric | >= 0.0 |
| Bleeding_On_Probing | enum | `"No"`, `"Yes"` |
| Surgical_Procedure | enum | `"Flap Surgery"`, `"GTR"`, `"Laser Surgery"`, `"Open Debridement"` |

---

## ☁️ Deploying to Render

1. Connect `mithunlingala30/backend` to your Render account.
2. Click **New Web Service** — Render auto-detects `render.yaml`.
3. Render sets Python `3.9.10`, runs the build command, and starts Uvicorn.

**Build Command:**
```bash
pip install -r requirements.txt && python model/train.py
```

**Start Command:**
```bash
uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

---

## 🔮 Roadmap

- 📉 **SHAP Explainability** — Visual per-patient feature importance attribution
- 🏥 **FHIR / EHR Integration** — Hospital data standard compatibility
- 📱 **Chairside Mobile App** — Native app for real-time intra-surgical planning
