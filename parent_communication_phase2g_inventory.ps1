[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=(Get-Location).Path
if(-not(Test-Path (Join-Path $root 'pubspec.yaml'))){
  throw 'Run from project root.'
}

$out=Join-Path $root 'parent_communication_phase2g_inventory.txt'
$lines=New-Object System.Collections.Generic.List[string]

$lines.Add('PARENT COMMUNICATION PHASE 2G INVENTORY')
$lines.Add('Generated: ' + (Get-Date))
$lines.Add('')

$targets=@(
  'lib\features\communication',
  'lib\features\parent_portal',
  'lib\features\teacher_portal',
  'lib\core\di\service_locator.dart',
  'lib\core\constants\firestore_paths.dart'
)

$patterns=@(
  'class Chat',
  'abstract class Chat',
  'ChatRepository',
  'ChatThread',
  'ChatMessage',
  'SendChat',
  'LoadChat',
  'WatchChat',
  'markThreadRead',
  'unread',
  'participant',
  'attachment',
  'messageType',
  'conversation'
)

foreach($target in $targets){
  $full=Join-Path $root $target
  if(-not(Test-Path $full)){continue}

  $files=if((Get-Item $full).PSIsContainer){
    Get-ChildItem $full -Recurse -Filter *.dart
  }else{
    Get-Item $full
  }

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
}

$lines | Set-Content $out -Encoding utf8
Write-Host ''
Write-Host 'Phase 2G inventory completed.' -ForegroundColor Green
Write-Host "Report: $out" -ForegroundColor Cyan
