# mobile-2025-final-project-patel-dhani-nathani-khan
Mobile Devices final project for:
Eva Hanif Nathani - 100814690
Saahir Dhani - 100818300
Yash Patel - 100785833
Muhammad Jibran Khan - 100877086

## Firebase auth + cloud sync
- Generate Firebase config: run `flutterfire configure` and commit the generated `firebase_options.dart`, `google-services.json` (Android) and `GoogleService-Info.plist` (iOS). A placeholder `lib/firebase_options.dart` is checked in; replace it with the generated one.
- Enable Email/Password auth and (optionally) allow weak passwords for guest IDs in the Firebase console.
- Firestore structure: `users/{uid}/tasks/{taskId}` documents with the same fields as local SQLite (`title`, `description`, `due` in millis, `status`, `priority`).
- Login flow: email/password sign-in and sign-up, or "Generate Guest ID" (creates a Firebase user where the guest ID is both username and password). On the login card you can paste a guest ID to sign in without entering email.
- Cloud sync: tap the cloud icon on the task list to pull remote tasks then push local changes. The app also pushes to the cloud when it goes to the background and when you open the task list after signing in. Local tasks stay saved regardless of auth.

