# 12_DECISIONS_LOG.md

# Almustafa Connect ERP

## Architecture Decisions Log (ADR)

**Version:** 2.0

**Status:** Active

**Purpose**

This document records important architectural and technical decisions
made during the project. Every major decision must be documented here
before implementation.

------------------------------------------------------------------------

# Decision Format

Each decision should contain:

-   Decision ID
-   Date
-   Status
-   Decision
-   Reason
-   Alternatives Considered
-   Impact

------------------------------------------------------------------------

# ADR-001

## Date

22 July 2026

## Status

Approved

## Decision

Adopt Clean Architecture.

## Reason

To keep the project scalable, testable and maintainable.

## Alternatives

-   MVC
-   MVVM

## Impact

All features will follow: Presentation → Domain → Data

------------------------------------------------------------------------

# ADR-002

## Date

22 July 2026

## Status

Approved

## Decision

Use flutter_bloc for state management.

## Reason

Clear separation of UI and business logic.

------------------------------------------------------------------------

# ADR-003

## Date

22 July 2026

## Status

Approved

## Decision

Use Repository Pattern.

## Reason

Abstract Firebase implementation from business logic.

------------------------------------------------------------------------

# ADR-004

## Date

22 July 2026

## Status

Approved

## Decision

Use GetIt for Dependency Injection.

## Reason

Simple, lightweight and scalable dependency management.

------------------------------------------------------------------------

# ADR-005

## Date

22 July 2026

## Status

Approved

## Decision

Freeze use case naming.

Approved names:

-   login_usecase.dart
-   logout_usecase.dart
-   forgot_password_usecase.dart
-   get_current_user_usecase.dart

Reason: Naming consistency across the project.

------------------------------------------------------------------------

# ADR-006

## Date

22 July 2026

## Status

Approved

## Decision

Documentation First Development.

Rule:

1.  Update documentation.
2.  Implement code.
3.  Test.
4.  Update progress.
5.  Update changelog.
6.  Commit to Git.

------------------------------------------------------------------------

# Pending Decisions

Future decisions to record:

-   Firestore schema
-   Role & Permission model
-   Navigation architecture
-   Error handling strategy
-   Logging strategy
-   Offline support
-   Caching strategy
-   Notification architecture
-   Reporting engine
-   Deployment strategy

------------------------------------------------------------------------

# Notes

Never modify an approved decision without recording:

-   Date
-   Reason
-   New decision
-   Version
