# FlapPlanAI — Flutter App

A Flutter port of your FlapPlanAI web frontend: same screens (Login/Register,
Dashboard, Case Entry, Result, Compare Procedures, Case Detail, Profile),
now running natively on **Web, Android, and iOS** from one codebase.

- **Web** → renders as a wide "premium website" layout with a persistent
  sidebar (see `lib/widgets/app_shell.dart`).
- **Mobile** (phone width) → renders as a compact layout with a bottom nav
  bar, same screens, same data.
- **Auth** → Firebase Authentication (email/password). Registering with a
  name writes it to Cloud Firestore (`users/{uid}`), and the Profile screen
  reads it back live — so the name you register with is exactly what you see
  in Profile.
- **Predictions** → calls your deployed model at
  `https://backend-hhbp.onrender.com` and gracefully falls back to a local
  offline model if that service is asleep/unreachable (see "About the
  backend connection" below — **please read**, one detail needs your input).

---

## 0. Why this zip doesn't include `android/`, `ios/`, `web/` folders

I don't have the Flutter SDK available in the environment that generated
this code, so I can't run `flutter create` to scaffold (and verify) the
native platform folders myself. Rather than hand-write Gradle/Xcode/web
boilerplate that I can't test and that goes stale between Flutter versions,
I'm giving you the actual app source (`lib/`, `pubspec.yaml`) and the
standard, reliable way to attach it to a real project:

```bash
# 1. Scaffold a fresh Flutter project (creates android/, ios/, web/, etc.)
flutter create flapplan_ai
cd flapplan_ai

# 2. Replace the generated lib/ and pubspec.yaml with the ones in this zip
rm -rf lib
cp -r /path/to/this-zip/lib .
cp /path/to/this-zip/pubspec.yaml .
cp /path/to/this-zip/analysis_options.yaml .

# 3. Get packages
flutter pub get
```

This takes 2 minutes and guarantees the native scaffolding matches your
installed Flutter/Gradle/Xcode versions exactly.

---

## 1. Connect Firebase

You said you'll use Firebase — here's the full setup:

1. Go to the [Firebase console](https://console.firebase.google.com) and
   create a project (or reuse one).
2. In **Build → Authentication → Sign-in method**, enable **Email/Password**.
3. In **Build → Firestore Database**, create a database (start in
   **production mode**, then set the rules below).
4. Install the FlutterFire CLI and wire this project to your Firebase
   project — this auto-generates a real `lib/firebase_options.dart` and the
   native config files:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   Select your Firebase project, then select the platforms you want
   (Web/Android/iOS). This **overwrites** the placeholder
   `lib/firebase_options.dart` included in this zip with your real project's
   values, and drops `google-services.json` / `GoogleService-Info.plist`
   into `android/app/` and `ios/Runner/` automatically.

5. **Firestore security rules** — each user can only read/write their own
   profile and cases. In the Firebase console under
   **Firestore Database → Rules**, use:

   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{uid} {
         allow read, write: if request.auth != null && request.auth.uid == uid;
         match /cases/{caseId} {
           allow read, write: if request.auth != null && request.auth.uid == uid;
         }
       }
     }
   }
   ```

That's it — run the app (`flutter run -d chrome` for web, or
`flutter run` with a device/emulator connected for mobile) and:

- **Register** with a name → it's saved to `users/{uid}` in Firestore and
  set as the Firebase Auth display name.
- **Profile** screen streams that same document live, so the name (and role)
  you registered with shows up immediately, and stays in sync if edited.
- **Case Entry → Result → Compare → Save case** writes to
  `users/{uid}/cases/{caseId}` and the Dashboard/Case Detail screens read
  from that same collection in real time.

---

## 2. About the backend connection — please check one thing

`lib/services/prediction_service.dart` POSTs each case to:

```
POST https://backend-hhbp.onrender.com/predict
Content-Type: application/json

{
  "age": 52,
  "sex": "Female",
  "diabetes": "No",
  "probing_depth": 4.5,
  "clinical_attachment_loss": 2.5,
  "gingival_index": 1.0,
  "plaque_index": 1.0,
  "bleeding_on_probing": "No",
  "procedure": "Flap Surgery"
}
```

I wasn't able to fetch your backend's API docs (its `robots.txt` blocks
automated tools), so I don't know your model's exact route name or response
shape. To make the app work regardless, `_parseBackendResponse()` in that
file already tries several common shapes automatically:

- `{"probabilities": {"Poor":.., "Fair":.., "Good":.., "Excellent":..}, "predicted_class": "Good"}`
- `{"Poor":.., "Fair":.., "Good":.., "Excellent":..}` at the top level
- `{"probabilities": [0.1, 0.2, 0.5, 0.2]}` (ordered Poor, Fair, Good, Excellent)
- `{"prediction": "Good", "confidence": 0.72}` (single-label classifiers)

**If your backend's real route or field names differ**, there are exactly
two things to change in `prediction_service.dart`:

1. `predictPath` (currently `/predict`) — set it to your actual route.
2. `PatientCase.toApiJson()` in `lib/models/patient_case.dart` — adjust the
   JSON keys to match what your model expects.

If the backend ever fails, times out, or returns something unparseable, the
app automatically falls back to a local, explainable offline model (ported
from your original `prediction.ts`) so the demo never breaks — the Result
screen shows a small amber notice when this happens.

⚠️ **Render free-tier note:** if the service has been idle, the first
request can take 20–50 seconds to "wake up." The app uses a 45-second
timeout and shows a loading message explaining this.

---

## 3. Project structure

```
lib/
  main.dart                 # Firebase init + AuthGate (Login vs Dashboard)
  firebase_options.dart     # placeholder — replaced by `flutterfire configure`
  theme/app_theme.dart      # brand colors (matches your tailwind config) + responsive breakpoints
  models/                   # PatientCase, Prediction, SavedCase, UserProfile
  services/
    auth_service.dart       # Firebase Auth + Firestore profile
    case_service.dart       # Firestore CRUD for saved cases
    prediction_service.dart # calls backend-hhbp.onrender.com, with fallback
    local_prediction_engine.dart # offline model, ported from prediction.ts
  state/app_state.dart      # app-wide session/profile/cases/draft-case state
  widgets/                  # OutcomeBadge, OutcomeBars, DriversPanel, AppShell (responsive shell), etc.
  screens/
    auth/login_screen.dart
    auth/register_screen.dart
    dashboard_screen.dart
    case_entry_screen.dart
    result_screen.dart
    compare_screen.dart
    case_detail_screen.dart
    profile_screen.dart
```

## 4. Running it

```bash
flutter run -d chrome     # premium website layout
flutter run                # pick a connected phone/emulator for mobile UI
flutter build web           # production web build
flutter build apk           # Android release build
flutter build ios           # iOS release build (needs Xcode + signing)
```
