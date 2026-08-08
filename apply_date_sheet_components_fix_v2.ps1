$ErrorActionPreference = "Stop"

$root = "D:\Projects\almustafa-connect-erp"
$manualPath = Join-Path $root "lib\features\exams\presentation\pages\manual_exam_date_sheet_builder_page.dart"
$autoPath = Join-Path $root "lib\features\exams\domain\usecases\generate_exam_date_sheet_options.dart"
$slPath = Join-Path $root "lib\core\di\service_locator.dart"

function Normalize-LF([string]$text) {
    return $text -replace "`r`n", "`n"
}

function Ensure-Contains {
    param(
        [string]$Text,
        [string]$Old,
        [string]$New,
        [string]$AlreadyMarker,
        [string]$Label
    )

    if ($AlreadyMarker -and $Text.Contains($AlreadyMarker)) {
        Write-Host "SKIP: $Label already applied." -ForegroundColor DarkYellow
        return $Text
    }

    if (-not $Text.Contains($Old)) {
        throw "Patch failed: pattern not found for $Label"
    }

    Write-Host "APPLY: $Label" -ForegroundColor Green
    return $Text.Replace($Old, $New)
}

function Backup-File([string]$Path) {
    $backup = "$Path.before_components_fix.bak"
    if (-not (Test-Path $backup)) {
        Copy-Item $Path $backup
        Write-Host "Backup: $backup" -ForegroundColor DarkGray
    }
}

Backup-File $manualPath
Backup-File $autoPath
Backup-File $slPath

# =========================================================
# MANUAL DATE SHEET
# =========================================================
Write-Host "`nPatching Manual Date Sheet Builder..." -ForegroundColor Cyan
$manual = Normalize-LF (Get-Content $manualPath -Raw)

if (-not $manual.Contains("import 'dart:convert';")) {
    $manual = $manual.Replace(
        "import 'package:flutter/material.dart';",
        "import 'dart:convert';`n`nimport 'package:flutter/material.dart';"
    )
}

if (-not $manual.Contains("subject_component_entity.dart")) {
    $manual = $manual.Replace(
        "import '../../../academic_structure/domain/entities/section_entity.dart';",
        "import '../../../academic_structure/domain/entities/section_entity.dart';`nimport '../../../academic_structure/domain/entities/subject_component_entity.dart';"
    )
}

if (-not $manual.Contains("subject_component_repository.dart")) {
    $manual = $manual.Replace(
        "import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';",
        "import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';`nimport '../../../academic_structure/domain/repositories/subject_component_repository.dart';"
    )
}

$manual = Ensure-Contains $manual `
"  List<AcademicSubjectEntity> _subjects = const [];
  List<TeacherAssignmentEntity> _assignments = const [];" `
"  List<AcademicSubjectEntity> _subjects = const [];
  List<SubjectComponentEntity> _components = const [];
  List<TeacherAssignmentEntity> _assignments = const [];" `
"List<SubjectComponentEntity> _components" `
"manual component state"

$manual = Ensure-Contains $manual `
"        sl<AcademicStructureRepository>().getSubjects(),
        sl<TeacherAssignmentRepository>().getAssignments(),
      ]);" `
"        sl<AcademicStructureRepository>().getSubjects(),
        sl<TeacherAssignmentRepository>().getAssignments(),
        sl<SubjectComponentRepository>().getComponents(),
      ]);" `
"sl<SubjectComponentRepository>().getComponents()" `
"manual load components"

$manual = Ensure-Contains $manual `
"        _subjects = subjects;
        _assignments = values[4] as List<TeacherAssignmentEntity>;
        _calendarHolidays = calendarHolidays;" `
"        _subjects = subjects;
        _assignments = values[4] as List<TeacherAssignmentEntity>;
        _components = (values[5] as List<SubjectComponentEntity>)
            .where((item) => item.isActive)
            .toList();
        _calendarHolidays = calendarHolidays;" `
"_components = (values[5]" `
"manual save components"

$oldManualLoop = @'
        for (final subject in byName.values) {
          final assignment = _findAssignment(
            exam: exam,
            academicClass: academicClass,
            section: section,
            subject: subject,
          );
          if (assignment != null) {
            rows.add(
              _ManualPaperRow(
                academicClass: academicClass,
                section: section,
                subject: subject,
                assignment: assignment,
              ),
            );
          }
        }
'@

$newManualLoop = @'
        for (final subject in byName.values) {
          final assignment = _findAssignment(
            exam: exam,
            academicClass: academicClass,
            section: section,
            subject: subject,
          );

          if (assignment == null) {
            continue;
          }

          final components = _activeComponentsFor(subject);

          if (subject.useComponentsInExamination && components.isNotEmpty) {
            for (final component in components) {
              rows.add(
                _ManualPaperRow(
                  academicClass: academicClass,
                  section: section,
                  subject: subject.copyWith(
                    id: _componentSubjectId(subject, component),
                    name: _componentDisplayName(
                      subject.name,
                      component.componentName,
                    ),
                  ),
                  assignment: assignment,
                ),
              );
            }
          } else {
            rows.add(
              _ManualPaperRow(
                academicClass: academicClass,
                section: section,
                subject: subject,
                assignment: assignment,
              ),
            );
          }
        }
'@

$manual = Ensure-Contains $manual `
$oldManualLoop `
$newManualLoop `
"final components = _activeComponentsFor(subject);" `
"manual expand subjects into components"

$manualHelpers = @'
  List<SubjectComponentEntity> _activeComponentsFor(
    AcademicSubjectEntity subject,
  ) {
    final values = _components
        .where(
          (component) =>
              component.isActive &&
              component.parentSubjectId == subject.id,
        )
        .toList()
      ..sort(
        (first, second) =>
            first.displayOrder.compareTo(second.displayOrder),
      );

    return values;
  }

  String _componentSubjectId(
    AcademicSubjectEntity parent,
    SubjectComponentEntity component,
  ) {
    final encodedParent = base64Url
        .encode(utf8.encode(parent.name))
        .replaceAll('=', '');
    final reportFlag = parent.useComponentsInReportCard ? '1' : '0';

    return 'cmp::${parent.id}::$encodedParent::$reportFlag::${component.id}';
  }

  String _componentDisplayName(
    String parentName,
    String componentName,
  ) {
    final parent = parentName.trim();
    final component = componentName.trim();

    if (parent.isEmpty) return component;
    if (component.isEmpty) return parent;

    final normalizedParent = _normalise(parent);
    final normalizedComponent = _normalise(component);

    if (normalizedComponent == normalizedParent ||
        normalizedComponent.startsWith('$normalizedParent ')) {
      return component;
    }

    return '$parent $component';
  }

'@

if (-not $manual.Contains("List<SubjectComponentEntity> _activeComponentsFor(")) {
    $anchor = "  TeacherAssignmentEntity? _findAssignment({"
    if (-not $manual.Contains($anchor)) {
        throw "Patch failed: helper insertion point not found in manual builder"
    }
    $manual = $manual.Replace($anchor, "$manualHelpers$anchor")
    Write-Host "APPLY: manual helper methods" -ForegroundColor Green
}

# Current manual builder already filters selected IDs from later dropdowns.
# Add a defensive check so duplicate selection is also blocked in the handler.
if (-not $manual.Contains("if (selectedIds.contains(subjectId)")) {
    $old = @'
    final row = _subjectsForColumn(
      column,
    ).where((item) => item.subject.id == subjectId).firstOrNull;
'@
    $new = @'
    final selectedIds = _selectedSubjectIds(column);
    if (selectedIds.contains(subjectId) &&
        existing?.subjectId != subjectId) {
      _show('This subject is already selected for this class/section.');
      return;
    }

    final row = _subjectsForColumn(
      column,
    ).where((item) => item.subject.id == subjectId).firstOrNull;
'@
    if (-not $manual.Contains($old)) {
        throw "Patch failed: duplicate-subject guard insertion point not found"
    }
    $manual = $manual.Replace($old, $new)
    Write-Host "APPLY: manual duplicate-subject guard" -ForegroundColor Green
}

[System.IO.File]::WriteAllText($manualPath, ($manual -replace "`n","`r`n"), [System.Text.UTF8Encoding]::new($false))
Write-Host "Manual builder patched." -ForegroundColor Green

# =========================================================
# AUTO DATE SHEET GENERATOR
# =========================================================
Write-Host "`nPatching Auto Date Sheet Generator..." -ForegroundColor Cyan
$auto = Normalize-LF (Get-Content $autoPath -Raw)

if (-not $auto.Contains("import 'dart:convert';")) {
    $auto = "import 'dart:convert';`n`n" + $auto
}

if (-not $auto.Contains("subject_component_entity.dart")) {
    $auto = $auto.Replace(
        "import '../../../academic_structure/domain/entities/section_entity.dart';",
        "import '../../../academic_structure/domain/entities/section_entity.dart';`nimport '../../../academic_structure/domain/entities/subject_component_entity.dart';"
    )
}

if (-not $auto.Contains("subject_component_repository.dart")) {
    $auto = $auto.Replace(
        "import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';",
        "import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';`nimport '../../../academic_structure/domain/repositories/subject_component_repository.dart';"
    )
}

$auto = Ensure-Contains $auto `
"    this._dateSheetRepository,
    this._validator,
  );

  final AcademicStructureRepository _academicRepository;
  final TeacherAssignmentRepository _assignmentRepository;
  final ExamDateSheetRepository _dateSheetRepository;
  final ValidateExamDateSheet _validator;" `
"    this._dateSheetRepository,
    this._validator,
    this._componentRepository,
  );

  final AcademicStructureRepository _academicRepository;
  final TeacherAssignmentRepository _assignmentRepository;
  final ExamDateSheetRepository _dateSheetRepository;
  final ValidateExamDateSheet _validator;
  final SubjectComponentRepository _componentRepository;" `
"final SubjectComponentRepository _componentRepository;" `
"auto component repository dependency"

$auto = Ensure-Contains $auto `
"      _academicRepository.getSubjects(),
      _assignmentRepository.getAssignments(),
    ]);" `
"      _academicRepository.getSubjects(),
      _assignmentRepository.getAssignments(),
      _componentRepository.getComponents(),
    ]);" `
"_componentRepository.getComponents()" `
"auto load components"

$auto = Ensure-Contains $auto `
"    final assignments = (values[3] as List<TeacherAssignmentEntity>)
        .where(
          (item) =>
              _normalise(item.academicSession) ==
              _normalise(exam.academicSession),
        )
        .toList(growable: false);

    final tasks = <_PaperTask>[];" `
"    final assignments = (values[3] as List<TeacherAssignmentEntity>)
        .where(
          (item) =>
              _normalise(item.academicSession) ==
              _normalise(exam.academicSession),
        )
        .toList(growable: false);

    final components = (values[4] as List<SubjectComponentEntity>)
        .where((item) => item.isActive)
        .toList(growable: false);

    final tasks = <_PaperTask>[];" `
"final components = (values[4]" `
"auto parse components"

$oldAutoTask = @'
          tasks.add(
            _PaperTask(
              academicClass: academicClass,
              section: section,
              subject: subject,
              assignment: assignment,
            ),
          );
'@

$newAutoTask = @'
          final examSubjects = _expandForExamination(
            subject,
            components,
          );

          for (final examSubject in examSubjects) {
            tasks.add(
              _PaperTask(
                academicClass: academicClass,
                section: section,
                subject: examSubject,
                assignment: assignment,
              ),
            );
          }
'@

$auto = Ensure-Contains $auto `
$oldAutoTask `
$newAutoTask `
"final examSubjects = _expandForExamination(" `
"auto expand components"

$autoHelpers = @'
  List<AcademicSubjectEntity> _expandForExamination(
    AcademicSubjectEntity subject,
    List<SubjectComponentEntity> components,
  ) {
    if (!subject.useComponentsInExamination) {
      return [subject];
    }

    final active = components
        .where(
          (component) =>
              component.isActive &&
              component.parentSubjectId == subject.id,
        )
        .toList()
      ..sort(
        (first, second) =>
            first.displayOrder.compareTo(second.displayOrder),
      );

    if (active.isEmpty) {
      return [subject];
    }

    return active
        .map(
          (component) => subject.copyWith(
            id: _componentSubjectId(subject, component),
            name: _componentDisplayName(
              subject.name,
              component.componentName,
            ),
          ),
        )
        .toList(growable: false);
  }

  String _componentSubjectId(
    AcademicSubjectEntity parent,
    SubjectComponentEntity component,
  ) {
    final encodedParent = base64Url
        .encode(utf8.encode(parent.name))
        .replaceAll('=', '');
    final reportFlag = parent.useComponentsInReportCard ? '1' : '0';

    return 'cmp::${parent.id}::$encodedParent::$reportFlag::${component.id}';
  }

  String _componentDisplayName(
    String parentName,
    String componentName,
  ) {
    final parent = parentName.trim();
    final component = componentName.trim();

    if (parent.isEmpty) return component;
    if (component.isEmpty) return parent;

    final normalizedParent = _normalise(parent);
    final normalizedComponent = _normalise(component);

    if (normalizedComponent == normalizedParent ||
        normalizedComponent.startsWith('$normalizedParent ')) {
      return component;
    }

    return '$parent $component';
  }

'@

if (-not $auto.Contains("List<AcademicSubjectEntity> _expandForExamination(")) {
    $anchor = "  List<AcademicSubjectEntity> _subjectsFor("
    if (-not $auto.Contains($anchor)) {
        throw "Patch failed: helper insertion point not found in auto generator"
    }
    $auto = $auto.Replace($anchor, "$autoHelpers$anchor")
    Write-Host "APPLY: auto helper methods" -ForegroundColor Green
}

[System.IO.File]::WriteAllText($autoPath, ($auto -replace "`n","`r`n"), [System.Text.UTF8Encoding]::new($false))
Write-Host "Auto generator patched." -ForegroundColor Green

# =========================================================
# SERVICE LOCATOR
# =========================================================
Write-Host "`nPatching service_locator.dart..." -ForegroundColor Cyan
$sl = Normalize-LF (Get-Content $slPath -Raw)

if ($sl.Contains("GenerateExamDateSheetOptions(") -and
    -not ($sl -match "GenerateExamDateSheetOptions\([\s\S]{0,500}sl<SubjectComponentRepository>\(\)")) {

    $pattern = "(GenerateExamDateSheetOptions\(\s*sl<AcademicStructureRepository>\(\),\s*sl<TeacherAssignmentRepository>\(\),\s*sl<ExamDateSheetRepository>\(\),\s*sl<ValidateExamDateSheet>\(\),)(\s*\))"

    if (-not [regex]::IsMatch($sl, $pattern)) {
        throw "Patch failed: GenerateExamDateSheetOptions registration shape not found in service_locator.dart"
    }

    $sl = [regex]::Replace(
        $sl,
        $pattern,
        '$1' + "`n      sl<SubjectComponentRepository>()," + '$2',
        1
    )

    Write-Host "APPLY: service locator component repository dependency" -ForegroundColor Green
} else {
    Write-Host "SKIP: service locator already patched." -ForegroundColor DarkYellow
}

[System.IO.File]::WriteAllText($slPath, ($sl -replace "`n","`r`n"), [System.Text.UTF8Encoding]::new($false))
Write-Host "service_locator.dart patched." -ForegroundColor Green

Write-Host "`nDONE." -ForegroundColor Green
Write-Host "Run this analyzer command:" -ForegroundColor White
Write-Host "flutter analyze lib/features/exams/presentation/pages/manual_exam_date_sheet_builder_page.dart lib/features/exams/domain/usecases/generate_exam_date_sheet_options.dart lib/core/di/service_locator.dart" -ForegroundColor White
