[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=(Get-Location).Path
if(-not(Test-Path (Join-Path $root 'pubspec.yaml'))){
  throw 'Run this script from the project root.'
}

$files=@(
  'lib\features\exams\domain\entities\exam_subject_setup_entity.dart',
  'lib\features\exams\data\models\exam_subject_setup_model.dart',
  'lib\features\academic_structure\domain\services\subject_component_exam_service.dart',
  'lib\features\exams\presentation\pages\exam_form_page.dart',
  'lib\features\exams\domain\usecases\generate_exam_results.dart'
)

$missing=@($files | Where-Object { -not(Test-Path (Join-Path $root $_)) })
if($missing.Count -gt 0){
  throw ('Missing files: ' + ($missing -join ', '))
}

$pack=Join-Path $root 'exam_component_passing_local_files'
$zip=Join-Path $root 'exam_component_passing_local_files.zip'

if(Test-Path $pack){Remove-Item $pack -Recurse -Force}
if(Test-Path $zip){Remove-Item $zip -Force}

New-Item -ItemType Directory -Force -Path $pack | Out-Null

foreach($file in $files){
  $source=Join-Path $root $file
  $target=Join-Path $pack $file
  New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent) | Out-Null

  $bytes=[System.IO.File]::ReadAllBytes($source)
  [System.IO.File]::WriteAllBytes($target,$bytes)
}

Start-Sleep -Milliseconds 500

$tar=Get-Command tar.exe -ErrorAction SilentlyContinue
if($null -eq $tar){
  throw 'Windows tar.exe was not found.'
}

Push-Location $pack
try{
  & tar.exe -a -c -f $zip *
  if($LASTEXITCODE -ne 0){
    throw 'tar.exe could not create the ZIP file.'
  }
}
finally{
  Pop-Location
}

Write-Host ''
Write-Host 'Local files package created successfully.' -ForegroundColor Green
Write-Host "Upload this file: $zip" -ForegroundColor Cyan
