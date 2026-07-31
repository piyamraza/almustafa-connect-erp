# Almustafa Connect ERP - Teacher Leave Module

## Leave Types

- Leave: no salary deduction
- Unpaid Leave: salary deduction

## Duration

- Full Day
- Half Day

## Completed Features

- Teacher-only dropdown
- Monthly leave management
- Add leave request
- Pending approvals
- Approve and reject
- Approval remarks
- Reviewed by
- Teacher-wise yearly leave history
- Monthly summary
- PDF report
- Print, share and download
- Approved leave marks Staff Attendance as Leave
- Unpaid Leave is included in salary deduction
- Half-day Unpaid Leave deducts 0.5 day

## Data Architecture

Teacher Leave reuses the existing Staff Leave collection,
repository, BLoC, attendance integration and salary integration.

The internal mapping is:

- Leave -> StaffLeaveType.other
- Unpaid Leave -> StaffLeaveType.unpaid

Teacher-facing screens display only Leave and Unpaid Leave.
