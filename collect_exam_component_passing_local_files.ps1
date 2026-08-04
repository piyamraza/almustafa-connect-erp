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

$out=Join-Path $root 'exam_component_passing_local_files.zip'
if(Test-Path $out){Remove-Item $out -Force}

$temp=Join-Path $env:TEMP ('exam_component_passing_' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $temp | Out-Null

foreach($file in $files){
  $source=Join-Path $root $file
  $target=Join-Path $temp $file
  New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent) | Out-Null
  Copy-Item $source $target -Force
}

Compress-Archive -Path (Join-Path $temp '*') -DestinationPath $out -Force
Remove-Item $temp -Recurse -Force

Write-Host ''
Write-Host 'Local files package created successfully.' -ForegroundColor Green
Write-Host "Upload this file: $out" -ForegroundColor Cyan
