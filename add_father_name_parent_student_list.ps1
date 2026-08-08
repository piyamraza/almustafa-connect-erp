$ErrorActionPreference = "Stop"

$path = "D:\Projects\almustafa-connect-erp\lib\features\parent_portal\presentation\pages\parent_account_form_page.dart"
$backup = "$path.before_father_name_fix.bak"

if (-not (Test-Path $backup)) {
    Copy-Item $path $backup
}

$text = Get-Content $path -Raw -Encoding UTF8

$old = "title: Text(student.fullName),"
$new = @"
title: Text(
                          student.fatherName.trim().isEmpty
                              ? student.fullName
                              : '`${student.fullName}  •  Father: `${student.fatherName}',
                        ),
"@

if (-not $text.Contains($old)) {
    throw "Patch failed: student title pattern not found."
}

$text = $text.Replace($old, $new)
[System.IO.File]::WriteAllText(
    $path,
    $text,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host "Father name added with student name." -ForegroundColor Green
Write-Host ""
Write-Host "Now run:" -ForegroundColor Cyan
Write-Host "dart format lib/features/parent_portal/presentation/pages/parent_account_form_page.dart"
Write-Host "flutter analyze lib/features/parent_portal/presentation/pages/parent_account_form_page.dart"
