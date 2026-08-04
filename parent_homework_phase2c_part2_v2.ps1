[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=(Get-Location).Path
$utf8=New-Object System.Text.UTF8Encoding($false)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$backup=Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\parent_homework_phase2c_part2_v2_$stamp"

function Full([string]$p){Join-Path $root $p}
function BackupFile([string]$p){
  $s=Full $p
  if(Test-Path $s){
    $d=Join-Path $backup $p
    New-Item -ItemType Directory -Force -Path (Split-Path $d -Parent)|Out-Null
    Copy-Item $s $d -Force
  }
}
function WriteText([string]$p,[string]$t){
  $f=Full $p
  New-Item -ItemType Directory -Force -Path (Split-Path $f -Parent)|Out-Null
  [IO.File]::WriteAllText($f,$t.Replace("`r`n","`n"),$utf8)
}

if(-not(Test-Path (Full 'pubspec.yaml'))){throw 'Run from project root.'}

$page='lib/features/parent_portal/presentation/pages/parent_homework_page.dart'
$dashboard='lib/features/parent_portal/presentation/pages/parent_portal_dashboard_page.dart'

foreach($f in @($page,$dashboard)){BackupFile $f}

if(-not(Test-Path (Full $page))){
  throw "Required file not found: $page"
}

$text=[IO.File]::ReadAllText((Full $dashboard)).Replace("`r`n","`n")

$import="import 'parent_homework_page.dart';"
if(-not $text.Contains($import)){
  $anchor="import 'parent_attendance_page.dart';"
  if(-not $text.Contains($anchor)){
    throw 'Dashboard import anchor not found.'
  }
  $text=$text.Replace($anchor,"$anchor`n$import")
}

$attendanceBlock=@'
                  if (module.$1 == 'Attendance') {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => ParentAttendancePage(student: student),
                      ),
                    );
                    return;
                  }
'@

$homeworkBlock=@'
                  if (module.$1 == 'Attendance') {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => ParentAttendancePage(student: student),
                      ),
                    );
                    return;
                  }

                  if (module.$1 == 'Homework') {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => ParentHomeworkPage(
                          student: student,
                        ),
                      ),
                    );
                    return;
                  }
'@

if(-not $text.Contains("if (module.`$1 == 'Homework')")){
  if(-not $text.Contains($attendanceBlock)){
    throw 'Attendance navigation block not found.'
  }
  $text=$text.Replace($attendanceBlock,$homeworkBlock)
}

$academicOld=@'
                    'Attendance',
                    'Timetable',
                    'Homework',
                    'Date Sheet',
                    'Results',
'@

$academicNew=@'
                    'Timetable',
                    'Date Sheet',
                    'Results',
'@

if($text.Contains($academicOld)){
  $text=$text.Replace($academicOld,$academicNew)
}

WriteText $dashboard $text

dart format $page $dashboard
if($LASTEXITCODE -ne 0){throw "FORMAT ERROR. Backup: $backup"}

flutter analyze lib/features/parent_portal lib/features/homework --no-fatal-infos --no-fatal-warnings
if($LASTEXITCODE -ne 0){throw "ANALYZE ERROR. Backup: $backup"}

Write-Host ''
Write-Host 'Parent Homework Phase 2C completed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
