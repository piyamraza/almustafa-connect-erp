[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path

if (-not (Test-Path (Join-Path $root 'pubspec.yaml'))) {
  throw 'PROJECT ROOT ERROR: Run this script from the Flutter project root.'
}

$patterns = @(
  'phone',
  'mobile',
  'contactNumber',
  'contactNo',
  'whatsapp',
  'WhatsApp'
)

$results = Get-ChildItem .\lib -Recurse -Filter '*.dart' |
  Select-String -Pattern $patterns |
  Select-Object Path, LineNumber, Line

$reportPath = Join-Path $root 'whatsapp_integration_inventory.txt'

$header = @"
ALMUSTAFA CONNECT ERP
WhatsApp Integration Inventory
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

This report lists Dart files containing phone/mobile/contact/WhatsApp fields.
It is used to safely integrate Same-as-Mobile + separate WhatsApp number support.

"@

$body = $results |
  Sort-Object Path, LineNumber |
  ForEach-Object {
    "$($_.Path):$($_.LineNumber)`r`n$($_.Line.Trim())`r`n"
  }

[IO.File]::WriteAllText(
  $reportPath,
  $header + ($body -join "`r`n"),
  (New-Object System.Text.UTF8Encoding($false))
)

Write-Host ''
Write-Host 'WhatsApp integration inventory completed.' -ForegroundColor Green
Write-Host "Report: $reportPath" -ForegroundColor Cyan
Write-Host ''
Write-Host "Matched lines: $($results.Count)" -ForegroundColor Yellow
Write-Host ''
Write-Host 'Likely modules:' -ForegroundColor Cyan

$results |
  ForEach-Object {
    $relative = $_.Path.Substring($root.Length).TrimStart('\')
    $parts = $relative -split '\\'
    if ($parts.Length -ge 3 -and $parts[0] -eq 'lib' -and $parts[1] -eq 'features') {
      $parts[2]
    } elseif ($parts.Length -ge 2) {
      $parts[1]
    }
  } |
  Where-Object { $_ } |
  Sort-Object -Unique |
  ForEach-Object { Write-Host "  - $_" }
