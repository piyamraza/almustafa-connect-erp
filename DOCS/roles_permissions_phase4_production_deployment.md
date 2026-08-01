# Roles & Permissions Phase 4 — Production Deployment

## Critical deployment order

1. Open **Roles & Permissions**.
2. Create default roles if they do not already exist.
3. Open **User Assignments**.
4. Assign the currently logged-in Firebase user the **Super Admin** role.
5. Open **Production Readiness**.
6. Run **Migrate User Roles to UID IDs**.
7. Run **Validate Production Readiness**.
8. Continue only when validation reports no blocking issues.
9. Back up Firestore.
10. Deploy the staged rules:

```powershell
firebase deploy --only firestore:rules
```

## Why migration is mandatory

Firestore Security Rules cannot query `user_roles` by the `userId` field.
The authenticated user's assignment must be stored at:

```text
user_roles/{FirebaseAuthUID}
```

The migration utility converts legacy random document IDs to this canonical
format before rules are deployed.

## Rollback

The Phase 4 installer creates a local backup. If deployed rules block valid
traffic, restore the prior rules in Firebase Console or deploy the backup
rules file. Do not delete the active Super Admin assignment.

## Security scope

The staged rules cover role administration, students, teachers, staff,
attendance, fees, exams, date sheets, results, timetable, homework, notices,
academic calendar, parent access, notifications, configuration and audit
logs.

Collection names that do not yet have a dedicated permission mapping fall
back to Super Admin or Settings Manager access. Test every production
workflow against the Firebase Emulator before public deployment.
