$ErrorActionPreference = "Stop"
$path = "D:\Projects\almustafa-connect-erp\lib\features\parent_portal\presentation\pages\parent_account_form_page.dart"
$backup = "$path.before_separator_fix.bak"
if (-not (Test-Path $backup)) { Copy-Item $path $backup }

$text = Get-Content $path -Raw -Encoding UTF8
$bad = [string]([char]0x00E2) + [char]0x20AC + [char]0x00A2
$count = ([regex]::Matches($text, [regex]::Escape($bad))).Count
if ($count -eq 0) {
    Write-Host "No corrupted separator found. File may already be fixed." -ForegroundColor Yellow
} else {
    $text = $text.Replace($bad, [string][char]0x2022)
    [System.IO.File]::WriteAllText($path, $text, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Fixed $count corrupted separator(s)." -ForegroundColor Green
}
Write-Host "Run:" -ForegroundColor Cyan
Write-Host "dart format lib/features/parent_portal/presentation/pages/parent_account_form_page.dart"
Write-Host "flutter analyze lib/features/parent_portal/presentation/pages/parent_account_form_page.dart"
