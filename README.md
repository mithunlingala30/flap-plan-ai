# 🦷 FlapPlan AI
### Periodontal Surgery Decision Support — Powered by XGBoost & Flutter

> *Know the outcome before you make the incision.*

---

## ✨ What is FlapPlan AI?

**FlapPlan AI** is a full-stack clinical decision support platform that predicts healing outcomes for periodontal surgery patients — in real time, right at the chairside.

A clinician enters nine standard clinical parameters, and FlapPlan returns:

- A **predicted healing outcome** (Excellent / Good / Fair / Poor)
- **Per-class probability scores** for every outcome tier
- **Top predictive drivers** explaining *why* the model made that call
- An **AI procedure recommender** comparing all surgical options side-by-side
- A **one-click clinical PDF report** ready to download or print

---

## 🖼️ App Screens

| Screen | Purpose |
|:---|:---|
| **Dashboard** | Overview of saved cases, outcome distribution, and quick-entry shortcut |
| **Case Entry** | Nine-field clinical intake form with live validation |
| **Result** | Prediction hero, probability bars, feature drivers, procedure comparison |
| **History** | Full searchable case log with filters, sort, and export to CSV |
| **Analytics** | Aggregate charts — outcome trends, procedure performance, utility distributions |
| **Compare** | Side-by-side procedure comparison for the current draft case |
| **Profile** | Clinician profile and app settings |

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────┐
│                   Flutter Frontend                    │
│  Case Entry → Prediction Request → Result Display    │
│                     (Provider)                        │
└────────────────────┬─────────────────────────────────┘
                     │ HTTP  (45 s timeout + fallback)
                     ▼
┌──────────────────────────────────────────────────────┐
│               FastAPI Backend  (Render)               │
│  Pydantic Validation → Feature Encoding → XGBoost    │
│              → Probabilities + Predicted Class        │
└──────────────────────────────────────────────────────┘
                     │  (offline fallback)
                     ▼
┌──────────────────────────────────────────────────────┐
│          LocalPredictionEngine  (on-device)           │
│   Deterministic heuristic — always available,        │
│   flagged as "Offline Estimate" in the UI            │
└──────────────────────────────────────────────────────┘
```

> The app **never blocks** on the cloud model. If the API is cold-starting or unreachable, the offline engine answers instantly and the result is clearly labelled.

---

## 🔑 Key Features

| Feature | Detail |
|:---|:---|
| 🤖 **XGBoost Classifier** | Gradient-boosted multi-class model trained on 9 clinical parameters |
| 📊 **Probability Breakdown** | Per-class confidence scores rendered as animated progress bars |
| 💡 **Feature Drivers** | Top 3 positive / negative predictors surfaced per prediction |
| 🔀 **Procedure Recommender** | All four surgical procedures ranked by utility score for the same patient |
| 📄 **PDF Report** | Professional A4 clinical report with preview before download |
| 📥 **CSV Export** | Full case history exportable as a structured dataset |
| 🔌 **Offline Mode** | On-device fallback engine — zero dependency on connectivity |
| 🔐 **Auth** | Firebase-backed sign-in for secure multi-clinician access |
| ☁️ **Cloud Deployment** | Backend auto-deploys on Render with `render.yaml` |

---

## 🧬 Clinical Input Parameters

| Parameter | Type | Range / Values |
|:---|:---|:---|
| Age | numeric | 0 – 120 |
| Sex | enum | Female · Male |
| Diabetes Status | enum | No · Yes |
| Probing Depth | mm | ≥ 0.0 |
| Clinical Attachment Loss | mm | ≥ 0.0 |
| Gingival Index | 0 – 3 scale | ≥ 0.0 |
| Plaque Index | 0 – 3 scale | ≥ 0.0 |
| Bleeding on Probing | enum | No · Yes |
| Surgical Procedure | enum | Flap Surgery · GTR · Laser Surgery · Open Debridement |

---

## 📂 Project Structure

```
flap_plan/
├── backend/                   ← FastAPI + XGBoost prediction API
│   ├── app/main.py            ← Routes, Pydantic schemas, prediction logic
│   ├── model/
│   │   ├── train.py           ← Training pipeline
│   │   ├── xgb_model.json     ← Trained model weights
│   │   ├── label_encoder.pkl
│   │   ├── feature_encoders.pkl
│   │   └── metrics.json       ← Evaluation report
│   ├── data/healing_data.csv  ← Patient training dataset
│   ├── render.yaml            ← Render deployment config
│   └── requirements.txt
│
└── frontend/                  ← Flutter cross-platform app
    └── lib/
        ├── models/            ← PatientCase, Prediction, SavedCase
        ├── services/          ← PredictionService, ReportGeneratorService, …
        ├── state/             ← AppState (Provider)
        ├── screens/           ← Dashboard, CaseEntry, Result, History, …
        ├── widgets/           ← OutcomeBars, DriversPanel, SectionCard, …
        └── theme/             ← AppTheme, color tokens
```

---

## ⚡ Quick Start

### Backend

```bash
cd backend
pip install -r requirements.txt
python model/train.py          # train & export model artifacts
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

---

## 🔌 API Reference

| Method | Endpoint | Description |
|:---|:---|:---|
| `GET` | `/` | Root + navigation links |
| `GET` | `/health` | Health check + active model classes |
| `GET` | `/metadata` | Feature schema + example payload |
| `POST` | `/predict` | Single patient outcome prediction |
| `POST` | `/predict/batch` | Bulk cohort prediction |

### Sample Request

```json
POST /predict
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

### Sample Response

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

## ☁️ Deploying the Backend to Render

1. Connect the `backend/` directory to a Render Web Service.
2. Render auto-detects `render.yaml` — no configuration needed.

**Build command:**
```bash
pip install -r requirements.txt && python model/train.py
```

**Start command:**
```bash
uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

---

## 🔮 Roadmap

- 📉 **SHAP Explainability** — Visual per-patient feature importance with waterfall charts
- 🏥 **FHIR / EHR Integration** — Compatibility with hospital data standards
- 📱 **Native Mobile Build** — Packaged iOS & Android releases for chairside use
- 🔔 **Follow-up Alerts** — Post-operative outcome tracking and reminders
- 🌍 **Multi-language Support** — Localisation for international clinical teams

---

## 🛠️ Tech Stack

**Frontend:** Flutter · Dart · Provider · `pdf` · `printing` · Firebase Auth
**Backend:** Python · FastAPI · XGBoost · Pydantic v2 · scikit-learn · Uvicorn
**Infra:** Render (backend) · Firebase (auth + Firestore)

---

<p align="center">
  Made with ❤️ for better periodontal outcomes.
</p>
#   f l a p - p l a n - a i  
 #   f l a p - p l a n - a i  
 #   f l a p - p l a n - a i  
 