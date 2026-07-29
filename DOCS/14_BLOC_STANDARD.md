# 14_BLOC_STANDARD.md

# Almustafa Connect ERP

## Enterprise BLoC Standard

**Version:** 2.0

**Status:** Approved

------------------------------------------------------------------------

# Purpose

This document defines the standard BLoC architecture for every feature
in the ERP. All future modules must follow this standard.

------------------------------------------------------------------------

# Folder Structure

    presentation/
        bloc/
            feature_bloc.dart
            feature_event.dart
            feature_state.dart

One feature = One BLoC.

------------------------------------------------------------------------

# Responsibilities

## Bloc

-   Handle business flow.
-   Call Use Cases only.
-   Emit states.
-   Never access Firebase directly.

## Event

-   Represents a user or system action.
-   Contains only required data.

## State

-   Represents the current UI state.
-   Must be immutable.

------------------------------------------------------------------------

# Standard Events

-   Started
-   LoadRequested
-   RefreshRequested
-   CreateRequested
-   UpdateRequested
-   DeleteRequested
-   SearchRequested
-   ResetRequested

Authentication may additionally use:

-   LoginRequested
-   LogoutRequested
-   ForgotPasswordRequested
-   CurrentUserRequested

------------------------------------------------------------------------

# Standard States

-   Initial
-   Loading
-   Loaded
-   Success
-   Failure

Authentication may additionally use:

-   Authenticated
-   Unauthenticated
-   PasswordResetEmailSent

------------------------------------------------------------------------

# Error Handling

All failures should expose:

-   message
-   optional error code

UI must display friendly messages only.

------------------------------------------------------------------------

# Dependency Flow

UI → Bloc → UseCase → Repository → Data Source → Service → Firebase

No layer may skip another layer.

------------------------------------------------------------------------

# Rules

1.  One Bloc per feature.
2.  One responsibility per event.
3.  No business logic inside widgets.
4.  No Firebase calls inside Bloc.
5.  No Repository calls inside UI.
6.  Use constructor dependency injection.
7.  Reuse states where possible.
8.  Keep Bloc focused and small.

------------------------------------------------------------------------

# Naming Convention

Files:

-   authentication_bloc.dart
-   authentication_event.dart
-   authentication_state.dart

Classes:

-   AuthenticationBloc
-   AuthenticationEvent
-   AuthenticationState

------------------------------------------------------------------------

# Future Modules

The same pattern will be used for:

-   Dashboard
-   Marketing
-   Planning
-   Production
-   Inventory
-   Purchase
-   Accounts
-   HR
-   Payroll
-   Reports
-   Settings
-   Notifications

------------------------------------------------------------------------

# Revision History

## v2.0

Initial enterprise BLoC standard approved.
