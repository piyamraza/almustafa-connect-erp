# User Accounts Management — Deployment

This module uses Firebase callable Cloud Functions because Firebase Authentication
users must be created with the Admin SDK. The Flutter client must never receive
service-account credentials.

## One-time deployment

From the project root:

```powershell
cd functions
npm install
cd ..
firebase deploy --only functions
```

The Firebase project must support Cloud Functions deployment. Firebase may ask
you to enable billing for production deployment.

## Before opening the page

1. Ensure `app_roles` contains active roles.
2. Ensure the currently logged-in administrator has a canonical document:
   `user_roles/{FirebaseAuthUID}`.
3. Assign that administrator `super_admin`, `usersManage`, or `rolesManage`.

## Features

- Create Firebase Authentication user without logging out the administrator.
- Accept email or a username.
- Usernames are converted internally to `username@almustafa.school`.
- Automatically create `user_roles/{UID}`.
- Assign role and branch.
- List Firebase Authentication users.
- Enable or disable accounts.
- Change roles.
- Generate and copy password-reset links.
- Temporary passwords are never stored in Firestore.

## Security

Every callable function independently verifies the caller's active role and
permissions. Hiding the UI is not treated as security.
