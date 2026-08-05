[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
if (-not (Test-Path (Join-Path $root 'pubspec.yaml'))) {
  throw 'Run this script from the project root.'
}

$out = Join-Path $root 'parent_audit_integration_inventory.txt'
$lines = New-Object System.Collections.Generic.List[string]

$lines.Add('PARENT PORTAL + AUDIT INTEGRATION INVENTORY')
$lines.Add('Generated: ' + (Get-Date))
$lines.Add('')

$targets = @(
  'lib\main.dart',
  'lib\core',
  'lib\features\authentication',
  'lib\features\access_control',
  'lib\features\dashboard',
  'lib\features\parent_portal',
  'lib\features\audit',
  'lib\features\audit_log',
  'lib\features\settings'
)

$patterns = @(
  'ParentPortalDashboardPage',
  'parent_portal',
  'hasRole\(''parent''\)',
  'hasRole\("parent"\)',
  'parentsView',
  'parentUserId',
  'ParentAccount',
  'Audit',
  'audit',
  'ActivityLog',
  'AuditLog',
  'logAction',
  'recordAction',
  'createdBy',
  'updatedBy',
  'deletedBy',
  'LoginPage',
  'DashboardPage',
  'TeacherPortalDashboardPage',
  'Sidebar',
  'AppPermission'
)

foreach ($target in $targets) {
  $full = Join-Path $root $target
  if (-not (Test-Path $full)) {
    continue
  }

  $files = if ((Get-Item $full).PSIsContainer) {
    Get-ChildItem $full -Recurse -Filter *.dart
  } else {
    Get-Item $full
  }

  foreach ($file in $files) {
    $matches = Select-String `
      -Path $file.FullName `
      -Pattern $patterns `
      -CaseSensitive:$false

    if ($matches) {
      $relative = $file.FullName.Substring($root.Length + 1)
      $lines.Add("FILE: $relative")
      foreach ($match in $matches) {
        $lines.Add("  Line $($match.LineNumber): $($match.Line.Trim())")
      }
      $lines.Add('')
    }
  }
}

$lines | Set-Content $out -Encoding utf8

Write-Host ''
Write-Host 'Integration inventory completed.' -ForegroundColor Green
Write-Host "Upload this report: $out" -ForegroundColor Cyan
