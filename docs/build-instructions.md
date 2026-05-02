# How to get a working APK

The `Build APK` GitHub Actions workflow runs on every push to
`claude/**` and on tags. It produces a debug APK as a downloadable
artifact.

## First time setup (one-time, ~15 min)

### 1. Create a Firebase project

1. Go to https://console.firebase.google.com and create a project (free Spark plan is enough).
2. Add an Android app with package name `com.touraapp.tour_app`.
3. Download `google-services.json`.
4. Enable **Authentication → Phone** (you'll need to add a test phone number while developing if you don't want to spend SMS quota).
5. Enable **Firestore** (start in production mode).
6. Enable **Cloud Messaging**.
7. Enable **Storage**.

### 2. Generate `firebase_options.dart` locally

You only need Flutter installed for this step (not for build).

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-project-id> --platforms=android
# This writes lib/core/config/firebase_options.dart
cat lib/core/config/firebase_options.dart   # copy the whole file
```

### 3. Add two GitHub Secrets

Repo → Settings → Secrets and variables → Actions → New repository secret:

| Secret name | Contents |
|---|---|
| `FIREBASE_OPTIONS_DART` | Paste the full contents of `lib/core/config/firebase_options.dart` |
| `GOOGLE_SERVICES_JSON` | Paste the full contents of `google-services.json` |

### 4. Trigger a build

Push any commit to your branch, or run the workflow manually:
Actions tab → "Build APK" → Run workflow.

When done, scroll to the bottom of the run page and download
`tour-app-debug` (zipped). Unzip → install on your phone.

## Installing on your phone

1. On Android phone: Settings → Security → enable **Install unknown apps** for your file manager / browser.
2. Transfer `app-debug.apk` to phone (USB, email, Drive, etc.).
3. Tap to install.
4. First launch: grant Notifications, Location (for expense GPS tag), Bluetooth (for BLE fallback).

## Deploying the backend (Cloud Functions + rules)

This still needs to be done locally once:

```bash
npm install -g firebase-tools
firebase login
cd Tour-App
firebase use --add <your-project-id>
firebase deploy --only firestore,functions
```

After this, FCM notifications fire automatically when expenses get
added; the app itself does not need to know about the functions.
