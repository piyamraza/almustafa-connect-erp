[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=(Get-Location).Path
if(-not(Test-Path (Join-Path $root 'pubspec.yaml'))){
  throw 'Run from project root.'
}

$out=Join-Path $root 'exam_component_distribution_inventory.txt'
$lines=New-Object System.Collections.Generic.List[string]

$lines.Add('EXAM COMPONENT DISTRIBUTION INVENTORY')
$lines.Add('Generated: ' + (Get-Date))
$lines.Add('')

$patterns=@(
  'Apply to All Selected Subjects',
  'Classes, Sections and Subjects',
  'SaveExam',
  'UpdateExam',
  'ExamSubjectSetupEntity',
  'SubjectComponentExamService',
  'useComponentsInExamination',
  'componentName',
  'passingMarks',
  'totalMarks',
  'subjectSetups'
)

$files=Get-ChildItem (Join-Path $root 'lib\features') -Recurse -Filter *.dart

foreach($file in $files){
  $matches=Select-String -Path $file.FullName -Pattern $patterns -CaseSensitive:$false
  if($matches){
    $relative=$file.FullName.Substring($root.Length+1)
    $lines.Add("FILE: $relative")
    foreach($match in $matches){
      $lines.Add("  Line $($match.LineNumber): $($match.Line.Trim())")
    }
    $lines.Add('')
  }
}

$lines | Set-Content $out -Encoding utf8
Write-Host ''
Write-Host 'Inventory completed.' -ForegroundColor Green
Write-Host "Report: $out" -ForegroundColor Cyan
