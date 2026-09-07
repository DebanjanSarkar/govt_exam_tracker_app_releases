# 🏛️ Govt Exam Tracker App

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Google Drive API](https://img.shields.io/badge/Google%20Drive%20API-4285F4?style=for-the-badge&logo=google-drive&logoColor=white)

A powerful, privacy-first Flutter application designed to help students and aspirants seamlessly organize, track, and manage their government exam details. With advanced features for categorization, document management, and progress tracking, you'll never miss a crucial deadline again.

## ✨ Key Features

* **Secure Authentication:** One-tap login using Google Sign-In.
* **Seamless Cloud Sync:** Backs up your exam data, schedules, and progress directly to your Google Drive across multiple devices.
* **Advanced Tracking:** Log exam dates, application deadlines, syllabus completion, and admit card statuses.
* **Categorization:** Group exams by sector (UPSC, SSC, Banking, State PSCs, Railways, etc.).
* **100% Privacy Focused:** Your data remains yours. By utilizing the Google Drive AppData folder, the app securely syncs your data without ever accessing your personal Drive files.

---

## 🔐 Google OAuth & Drive AppData Scope (For App Verification)

This application uses Google Sign-In and requests the `https://www.googleapis.com/auth/drive.appdata` scope. 

### Why do we need this scope?
The **Govt Exam Tracker App** allows students to input highly personalized data regarding their career and exams. To provide a seamless cross-device experience without hosting a centralized database (which poses privacy risks), the app backs up the user's exam tracking data directly to their own Google Drive.

We explicitly use the `drive.appdata` scope instead of the full Drive scope because:
1. **Privacy & Security:** It only gives the app access to a special, hidden Application Data folder. The app **cannot** see, read, or modify any of the user's personal files, photos, or documents stored in their Google Drive.
2. **User Control:** The data counts against the user's Google Drive storage quota, ensuring they have full ownership of their data. They can delete this hidden app data at any time via their Google Drive settings.
3. **Seamless Experience:** It allows for automatic syncing of user preferences, exam lists, and tracking statuses between devices seamlessly.

*Note for Google Cloud Trust & Safety:* This scope is strictly used for syncing the user's local SQLite database / JSON preferences to their personal AppData folder to enable cross-device compatibility. 

---

## 🛠️ Tech Stack

* **Framework:** [Flutter](https://flutter.dev/)
* **Language:** Dart
* **Authentication:** Google Sign-In (`google_sign_in`)
* **Cloud Sync:** Google APIs (`googleapis`, `googleapis_auth`)
* **Local Storage:** SQLite / SharedPreferences

---

## 🚀 Getting Started

### Prerequisites

To build and run this app locally, you need to have the following installed:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable version)
* Android Studio / VS Code
* A Google Cloud Console project with the **Google Drive API** enabled.

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/DebanjanSarkar/govt_exam_tracker_app_releases.git
   cd govt_exam_tracker_app_releases/govt_exam_tracker_app
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase / Google Cloud Console:**
   * Go to the [Google Cloud Console](https://console.cloud.google.com/).
   * Create a new project and enable the **Google Drive API**.
   * Configure the OAuth Consent Screen and add the `../auth/drive.appdata` scope.
   * Generate OAuth 2.0 Client IDs for Android (and iOS/Web if applicable).
   * Download the `google-services.json` file and place it in `android/app/`.

4. **Run the App:**
   ```bash
   flutter run
   ```

---

## 📂 Codebase Structure (lib/)

The `lib/` directory is structured to ensure scalability and clean architecture:

* `/models`: Contains the Dart data classes for Exams, User Profiles, etc.
* `/screens`: UI components and individual pages of the app.
* `/services`: Contains the core logic for the Google Drive AppData sync (`drive_sync_service.dart`) and Authentication (`auth_service.dart`).
* `/utils`: Helper functions, constants, and theme configurations.
* `/widgets`: Reusable custom UI components used across the app.

---

## 📄 Privacy Policy

We respect your privacy. The **Govt Exam Tracker App** does not collect, sell, or share your personal data with third parties. All exam data is stored locally on your device and synced exclusively to your private Google Drive Application Data folder. 

For the complete privacy policy, please visit: `[Insert Link to your Privacy Policy webpage here]`

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/DebanjanSarkar/govt_exam_tracker_app_releases/issues).


