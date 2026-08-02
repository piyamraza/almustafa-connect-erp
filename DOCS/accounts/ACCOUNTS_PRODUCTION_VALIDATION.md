# Accounts Module Production Validation

## Integration
- Accounts & Payroll appears in the main sidebar for users with `reportsView`.
- Unauthorized users cannot open the module.
- All Accounts BLoCs and use cases resolve through GetIt.
- Expenses, Payroll, Income, Profit & Loss, Cashbook, and Reports pages open successfully.

## Firestore Security
- Read access to Accounts collections requires `reportsView` or `reportsExport`.
- Write access requires `reportsExport`.
- Super administrators retain access through `rolesManage`.
- Deploy `firestore.rules` after verification.

## Functional Validation
- Create and approve an expense, then mark it paid.
- Create a payroll profile, generate payroll, approve it, and mark it paid.
- Sync fee income and confirm duplicate protection.
- Generate monthly profit and loss.
- Sync the cashbook and confirm running balance.
- Export one PDF and one Excel report.
- Verify dashboard KPIs and recent transactions.

## Release Commands
```powershell
dart format lib
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
firebase deploy --only firestore:rules
```
