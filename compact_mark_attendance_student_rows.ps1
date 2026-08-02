$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
if (-not (Test-Path (Join-Path $root 'pubspec.yaml'))) {
    throw 'Run this script from the almustafa-connect-erp project root.'
}

$utf8 = New-Object System.Text.UTF8Encoding($false)
$target = 'lib/features/attendance/presentation/pages/mark_attendance_page.dart'
$targetPath = Join-Path $root $target

if (-not (Test-Path $targetPath)) {
    throw "Required file not found: $target"
}

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupRoot = Join-Path `
    (Split-Path $root -Parent) `
    "almustafa-connect-erp_backups/compact_mark_attendance_rows_$stamp"

$backupFile = Join-Path $backupRoot $target
New-Item -ItemType Directory -Path (Split-Path $backupFile -Parent) -Force | Out-Null
Copy-Item $targetPath $backupFile -Force

$content = [IO.File]::ReadAllText($targetPath).Replace("`r`n", "`n")

# Compact page spacing.
$content = $content.Replace(
    '      padding: const EdgeInsets.all(24),',
    '      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),'
)

$content = $content.Replace(
    '          const SizedBox(height: 16),' + "`n" +
    '          Row(',
    '          const SizedBox(height: 10),' + "`n" +
    '          Row('
)

$content = $content.Replace(
    '          const SizedBox(height: 20),' + "`n" +
    '          Expanded(',
    '          const SizedBox(height: 10),' + "`n" +
    '          Expanded('
)

# Compact list gaps and card padding.
$content = $content.Replace(
    '                    separatorBuilder: (_, _) => const SizedBox(height: 10),',
    '                    separatorBuilder: (_, _) => const SizedBox(height: 4),'
)

$content = $content.Replace(
    '                          padding: const EdgeInsets.all(16),',
    '                          padding: const EdgeInsets.symmetric(' + "`n" +
    '                            horizontal: 12,' + "`n" +
    '                            vertical: 8,' + "`n" +
    '                          ),'
)

$content = $content.Replace(
    '                                        const SizedBox(height: 16),',
    '                                        const SizedBox(height: 8),'
)

$content = $content.Replace(
    '                                        const SizedBox(width: 24),',
    '                                        const SizedBox(width: 14),'
)

$content = $content.Replace(
    '                                        SizedBox(width: 400, child: controls),',
    '                                        SizedBox(width: 380, child: controls),'
)

# Replace student details widget with compact inline information.
$detailsPattern = '(?ms)class _StudentDetails extends StatelessWidget \{.*?^\}\n\nclass _AttendanceControls'

$detailsReplacement = @'
class _StudentDetails extends StatelessWidget {
  const _StudentDetails({required this.student});

  final StudentEntity student;

  @override
  Widget build(BuildContext context) {
    final father = student.fatherName.trim().isEmpty
        ? '-'
        : student.fatherName.trim();
    final roll = student.rollNumber.trim().isEmpty
        ? '-'
        : student.rollNumber.trim();

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          child: Text(
            student.fullName.isEmpty
                ? '?'
                : student.fullName[0].toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    student.fullName,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Father: $father',
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 14,
                runSpacing: 2,
                children: [
                  Text(
                    'Roll No: $roll',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  Text(
                    'Admission No: ${student.admissionNo}',
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttendanceControls
'@

if ([regex]::IsMatch($content, $detailsPattern)) {
    $content = [regex]::Replace(
        $content,
        $detailsPattern,
        $detailsReplacement,
        1
    )
} else {
    throw 'Student details widget anchor not found.'
}

# Make controls shorter and denser.
$content = $content.Replace(
    "          decoration: const InputDecoration(`n" +
    "            labelText: 'Status',`n" +
    "            border: OutlineInputBorder(),`n" +
    "          ),",
    "          decoration: const InputDecoration(`n" +
    "            labelText: 'Status',`n" +
    "            isDense: true,`n" +
    "            contentPadding: EdgeInsets.symmetric(`n" +
    "              horizontal: 12,`n" +
    "              vertical: 12,`n" +
    "            ),`n" +
    "            border: OutlineInputBorder(),`n" +
    "          ),"
)

$content = $content.Replace(
    "          decoration: const InputDecoration(`n" +
    "            labelText: 'Remarks',`n" +
    "            border: OutlineInputBorder(),`n" +
    "          ),",
    "          decoration: const InputDecoration(`n" +
    "            labelText: 'Remarks',`n" +
    "            isDense: true,`n" +
    "            contentPadding: EdgeInsets.symmetric(`n" +
    "              horizontal: 12,`n" +
    "              vertical: 12,`n" +
    "            ),`n" +
    "            border: OutlineInputBorder(),`n" +
    "          ),"
)

[IO.File]::WriteAllText($targetPath, $content, $utf8)
Write-Host "Updated: $target" -ForegroundColor Green

Write-Host ''
Write-Host 'Running dart format...' -ForegroundColor Cyan

& dart format $target

if ($LASTEXITCODE -ne 0) {
    throw 'dart format failed.'
}

Write-Host ''
Write-Host 'Running flutter analyze...' -ForegroundColor Cyan

& flutter analyze

if ($LASTEXITCODE -ne 0) {
    throw 'flutter analyze found issues. Copy the complete output into ChatGPT.'
}

Write-Host ''
Write-Host 'Mark Attendance student rows compressed successfully.' -ForegroundColor Green
Write-Host 'Father name is now beside student name, with roll and admission details on one compact line.' -ForegroundColor Cyan
Write-Host "Backup: $backupRoot" -ForegroundColor DarkGray
