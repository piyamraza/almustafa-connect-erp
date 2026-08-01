$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
if (-not (Test-Path (Join-Path $root 'pubspec.yaml'))) {
    throw 'Run this script from the almustafa-connect-erp project root.'
}

$utf8 = New-Object System.Text.UTF8Encoding($false)

$formFile = 'lib/features/homework/presentation/pages/homework_form_page.dart'
$dashboardFile = 'lib/features/homework/presentation/pages/homework_dashboard_page.dart'

function Read-ProjectFile {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $path = Join-Path $root $RelativePath
    if (-not (Test-Path $path)) {
        throw "Required file not found: $RelativePath"
    }

    return [IO.File]::ReadAllText($path).Replace("`r`n", "`n")
}

function Write-ProjectFile {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $path = Join-Path $root $RelativePath
    [IO.File]::WriteAllText($path, $Content, $utf8)
    Write-Host "Updated: $RelativePath" -ForegroundColor Green
}

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupRoot = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups/homework_save_fix_$stamp"

foreach ($relativePath in @($formFile, $dashboardFile)) {
    $source = Join-Path $root $relativePath
    $destination = Join-Path $backupRoot $relativePath

    New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
    Copy-Item $source $destination -Force
}

# =========================================================
# Fix homework form
# =========================================================

$content = Read-ProjectFile -RelativePath $formFile

if (-not $content.Contains('bool _saving = false;')) {
    $content = $content.Replace(
        '  bool _uploading = false;',
        "  bool _uploading = false;`n  bool _saving = false;"
    )
}

$saveStart = $content.IndexOf('  Future<void> _save() async {')
$snackStart = $content.IndexOf('  void _snack(String message) {')

if ($saveStart -lt 0 -or $snackStart -lt 0 -or $snackStart -le $saveStart) {
    throw 'Homework _save method anchors not found.'
}

$newSaveMethod = @'
  Future<void> _save() async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) {
      _snack('Please complete all required fields.');
      return;
    }

    if ([_classId, _sectionId, _subjectId, _teacherId].contains(null)) {
      _snack('Class, section, subject and teacher are required.');
      return;
    }

    setState(() => _saving = true);

    try {
      final calendar =
          await sl<AcademicCalendarPolicyService>()
              .validateHomeworkDueDate(
        academicSession: widget.academicSession,
        date: _due,
      );

      if (!mounted) return;

      if (!calendar.allowed) {
        if (calendar.suggestedDate == null) {
          _snack(calendar.message);
          return;
        }

        final useSuggested = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Invalid Due Date'),
                content: Text(
                  '${calendar.message}\n\n'
                  'Suggested: ${_date(calendar.suggestedDate!)}',
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext, true),
                    child: const Text('Use Suggested'),
                  ),
                ],
              ),
            ) ??
            false;

        if (!useSuggested) return;
        _due = calendar.suggestedDate!;
      }

      final now = DateTime.now();
      final old = widget.existing;

      final homework = HomeworkEntity(
        id: _homeworkId,
        academicSession: widget.academicSession,
        classId: _classId!,
        className: _name(_classes, _classId),
        sectionId: _sectionId!,
        sectionName: _name(_sections, _sectionId),
        subjectId: _subjectId!,
        subjectName: _name(_subjects, _subjectId),
        teacherId: _teacherId!,
        teacherName: _teacherName(),
        title: _title.text.trim(),
        description: _description.text.trim(),
        instructions: _instructions.text.trim(),
        assignedDate: _assigned,
        dueDate: _due,
        status: _status,
        attachments: _attachments,
        createdBy: old?.createdBy ?? 'Admin',
        updatedBy: 'Admin',
        publishedBy: _status == HomeworkStatus.published
            ? 'Admin'
            : old?.publishedBy,
        createdAt: old?.createdAt ?? now,
        updatedAt: now,
        publishedAt: _status == HomeworkStatus.published
            ? old?.publishedAt ?? now
            : old?.publishedAt,
        sourceHomeworkId:
            widget.copyFrom?.id ?? old?.sourceHomeworkId,
      );

      final repository = sl<HomeworkRepository>();
      final duplicate = await repository.duplicateExists(homework);

      if (!mounted) return;

      if (duplicate) {
        final proceed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Possible Duplicate'),
                content: const Text(
                  'Same title, class, section and subject already '
                  'exist for this assigned date. Save anyway?',
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext, true),
                    child: const Text('Save Anyway'),
                  ),
                ],
              ),
            ) ??
            false;

        if (!proceed) return;
      }

      await repository.saveHomework(homework);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error, stackTrace) {
      debugPrint('Homework save failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      _snack(
        'Homework could not be saved: '
        '${error.toString().replaceFirst('StateError: ', '')}',
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

'@

$content = $content.Remove($saveStart, $snackStart - $saveStart)
$content = $content.Insert($saveStart, $newSaveMethod)

$oldButton = @'
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Homework'),
              ),
'@

$newButton = @'
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _saving ? 'Saving...' : 'Save Homework',
                ),
              ),
'@

if ($content.Contains($oldButton)) {
    $content = $content.Replace($oldButton, $newButton)
} elseif (-not $content.Contains("'Saving...'")) {
    throw 'Save Homework button anchor not found.'
}

Write-ProjectFile -RelativePath $formFile -Content $content

# =========================================================
# Fix dashboard return/reload flow
# =========================================================

$content = Read-ProjectFile -RelativePath $dashboardFile

$oldOpenMethod = @'
    final value = await Navigator.of(context).push<HomeworkEntity>(
      MaterialPageRoute(
        builder: (_) => HomeworkFormPage(
          existing: existing,
          copyFrom: copyFrom,
          academicSession: _session.text.trim(),
        ),
      ),
    );
    if (value != null && mounted) {
      context.read<HomeworkBloc>().add(SaveHomework(value));
    }
'@

$newOpenMethod = @'
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => HomeworkFormPage(
          existing: existing,
          copyFrom: copyFrom,
          academicSession: _session.text.trim(),
        ),
      ),
    );

    if (saved == true && mounted) {
      _load();

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Homework saved successfully.'),
          ),
        );
    }
'@

if ($content.Contains($oldOpenMethod)) {
    $content = $content.Replace($oldOpenMethod, $newOpenMethod)
} elseif (-not $content.Contains('push<bool>')) {
    $pattern = '(?ms)\s*final value = await Navigator\.of\(context\)\.push<HomeworkEntity>\(.*?context\.read<HomeworkBloc>\(\)\.add\(SaveHomework\(value\)\);\s*\}'

    if ([regex]::IsMatch($content, $pattern)) {
        $content = [regex]::Replace(
            $content,
            $pattern,
            "`n$newOpenMethod",
            1
        )
    } else {
        throw 'Homework dashboard _open method anchor not found.'
    }
}

Write-ProjectFile -RelativePath $dashboardFile -Content $content

# =========================================================
# Format and analyze
# =========================================================

Write-Host ''
Write-Host 'Running dart format...' -ForegroundColor Cyan

& dart format $formFile $dashboardFile

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
Write-Host 'Homework save flow fixed successfully.' -ForegroundColor Green
Write-Host 'Homework is now saved directly before leaving the form.' -ForegroundColor Cyan
Write-Host "Backup: $backupRoot" -ForegroundColor DarkGray
