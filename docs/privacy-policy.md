---
title: Privacy Policy
---

# Privacy Policy — Govt Exam Tracker App

**Last updated:** September 7, 2026

Govt Exam Tracker App ("the App", "we", "our") is a free, local-first mobile application built to help students and aspirants track Indian government exam applications, deadlines, and results. This Privacy Policy explains what information the App handles, how it is stored, and what control you have over it.

By using the App, you agree to the practices described in this policy.

## 1. Information We Collect

### 1.1 Data you enter into the App

The App is built to store the exam-tracking information you choose to enter, including:
- Exam names, categories, and post/application details
- Application portal URLs
- Application, exam, and result dates
- Notes you add about an exam
- Login credentials (username/ID and password) for exam portals, *if you choose to save them*

**This data is stored only on your device**, in a local encrypted database. We do not operate any server that receives, stores, or has access to this information.

### 1.2 Google Account information

If you choose to sign in with Google to enable backup, the App requests basic profile information (your name, email address, and profile picture) solely to identify your signed-in session. We do not use this information for any purpose beyond displaying who is signed in and authorizing Drive backup.

### 1.3 Information we do **not** collect

The App does not collect analytics, advertising identifiers, location data, device identifiers for tracking, or any usage statistics. We do not use third-party advertising or analytics SDKs.

## 2. How Your Data Is Stored

### 2.1 On your device

Exam records and notes are stored in a local SQLite database on your phone. Login credentials you choose to save are stored separately using your device's secure hardware-backed storage (Android Keystore), never as plain text in the database.

### 2.2 Google Drive backup (optional)

If you sign in with Google and use the backup feature, your exam data is uploaded, at your request, to the **Google Drive "Application Data" folder** — a special hidden storage area tied to this specific app.

We use the restricted `drive.appdata` scope for this, which means:
- The App can **only** read and write the backup file it creates itself.
- The App **cannot** see, read, list, or modify any other file in your Google Drive — your photos, documents, or anything else remain completely inaccessible to us.
- This backup file does **not** appear in your normal Google Drive folder view; it is only visible/manageable through the App or your Google Account's app permissions page.
- The backup counts toward your personal Google Drive storage quota, and it is owned by your Google account, not by us.

Backup only happens when you actively choose to trigger it — the App does not silently or continuously upload your data in the background.

## 3. How We Use Your Information

We use the information described above solely to:
- Display and organize your tracked exams within the App
- Let you back up and restore your data across your own devices via your own Google Drive
- Authenticate your Google sign-in session

We do not use your data for advertising, profiling, or any purpose unrelated to the App's core functionality.

## 4. Data Sharing

We do not sell, rent, trade, or share your personal data or exam-tracking information with any third party. We have no advertising partners, analytics vendors, or data brokers integrated into the App. Your data is never transmitted to us or to any server we control.

## 5. Data Retention and Deletion

- **Local data:** Uninstalling the App permanently deletes all locally stored exam data and credentials from your device.
- **Drive backup data:** You can delete your backup at any time by:
  1. Revoking the App's access from your [Google Account permissions page](https://myaccount.google.com/permissions), which also removes the App's ability to access its AppData folder, or
  2. Using an in-app "delete backup" option if available in your current app version.
- We retain no copy of your data anywhere once it is deleted from your device and/or Drive — we never had a copy to begin with.

## 6. Children's Privacy

The App is intended for exam aspirants generally, including those preparing for exams that may be taken by users under 18 (e.g., school-level recruitment exams). We do not knowingly collect any information beyond what is described above, and no data is shared externally regardless of user age. If you are a parent or guardian and believe your child has used the App in a way that concerns you, you can uninstall the App and revoke Drive access at any time as described in Section 5.

## 7. Your Rights and Choices

You control your data at all times:
- You may use the App entirely offline without signing in — Drive backup is optional, not required.
- You may edit or delete any exam record directly within the App.
- You may revoke Google Drive access at any time via your Google Account settings.
- You may uninstall the App at any time to remove all local data.

## 8. Security

We take reasonable technical measures to protect your data, including storing credentials via hardware-backed secure storage and restricting Drive access to the minimum scope (`drive.appdata`) necessary for backup functionality. However, no method of electronic storage is 100% secure, and we cannot guarantee absolute security.

## 9. Changes to This Policy

We may update this Privacy Policy from time to time, for example to reflect new features. Material changes will be reflected by updating the "Last updated" date above. Continued use of the App after changes are posted constitutes acceptance of the revised policy.

## 10. Contact Us

If you have questions about this Privacy Policy or how your data is handled, contact:

**Debanjan Sarkar**
Email: debanjan.dataguy@gmail.com
GitHub: [github.com/DebanjanSarkar](https://github.com/DebanjanSarkar)

---

*This policy describes the Govt Exam Tracker App's actual data practices as implemented in its source code. It is provided for transparency and Google OAuth verification purposes and does not constitute legal advice; if you plan wider public distribution, consider having it reviewed by a legal professional familiar with your jurisdiction.*
