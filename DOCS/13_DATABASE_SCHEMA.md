# 13_DATABASE_SCHEMA.md

# Almustafa Connect ERP

## Database Schema (Master Design)

**Version:** 2.0\
**Status:** Draft (To be finalized before ERP modules)

------------------------------------------------------------------------

# Purpose

This document defines the standard Firestore database structure for the
entire ERP. All collections, documents and field names must be
documented here before implementation.

------------------------------------------------------------------------

# Design Principles

-   Keep collections flat where possible.
-   Use document IDs instead of storing duplicate identifiers.
-   Store timestamps using Firestore Timestamp.
-   Never duplicate business-critical data.
-   Use references only where necessary.

------------------------------------------------------------------------

# Proposed Collections

    users
    roles
    permissions
    companies
    branches
    departments
    employees
    customers
    suppliers
    products
    product_categories
    inventory
    warehouses
    purchase_orders
    sales_orders
    production_orders
    reports
    notifications
    settings
    audit_logs

------------------------------------------------------------------------

# users

Document ID

    uid

Fields

  Field          Type        Required
  -------------- ----------- ----------
  uid            String      Yes
  employeeCode   String      Yes
  fullName       String      Yes
  email          String      Yes
  phone          String      No
  roleId         String      Yes
  branchId       String      Yes
  departmentId   String      Yes
  isActive       Boolean     Yes
  createdAt      Timestamp   Yes
  updatedAt      Timestamp   Yes

------------------------------------------------------------------------

# roles

Document ID

    roleId

Fields

-   roleName
-   description
-   createdAt

------------------------------------------------------------------------

# permissions

Document ID

    permissionId

Fields

-   permissionName
-   module
-   description

------------------------------------------------------------------------

# Companies

One company document for each legal entity.

Example fields

-   companyName
-   address
-   phone
-   email
-   logo

------------------------------------------------------------------------

# Branches

Each branch belongs to one company.

------------------------------------------------------------------------

# Departments

Examples

-   Marketing
-   Production
-   Accounts
-   HR
-   Purchase
-   Planning
-   Inventory

------------------------------------------------------------------------

# Audit Logs

Every important ERP action should generate an audit log.

Suggested fields

-   userId
-   action
-   module
-   documentId
-   timestamp
-   device
-   ipAddress (optional)

------------------------------------------------------------------------

# Security Guidelines

-   Authenticate every user.
-   Validate role before sensitive operations.
-   Restrict collections using Firebase Security Rules.
-   Never trust client-side validation.

------------------------------------------------------------------------

# Pending Design

The following modules will be documented before implementation:

-   Marketing
-   Production
-   Inventory
-   Accounts
-   HR
-   Payroll
-   Reports
-   Notifications

------------------------------------------------------------------------

# Revision History

## v2.0

Initial database schema created.
