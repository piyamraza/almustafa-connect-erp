$ErrorActionPreference = "Stop"

$root = "D:\Projects\almustafa-connect-erp"
$manualPath = Join-Path $root "lib\features\exams\presentation\pages\manual_exam_date_sheet_builder_page.dart"
$autoPath = Join-Path $root "lib\features\exams\domain\usecases\generate_exam_date_sheet_options.dart"

function Replace-Exact {
    param(
        [string]$Text,
        [string]$Old,
        [string]$New,
        [string]$Label
    )

    if (-not $Text.Contains($Old)) {
        throw "Patch failed: pattern not found for $Label"
    }

    return $Text.Replace($Old, $New)
}

Write-Host "Patching Manual Date Sheet Builder..." -ForegroundColor Cyan
$manual = Get-Content $manualPath -Raw

# 1) Add dart:convert.
$manual = Replace-Exact $manual `
"import 'package:flutter/material.dart';" `
"import 'dart:convert';

import 'package:flutter/material.dart';" `
"manual dart:convert import"

# 2) Add Subject Component imports.
$manual = Replace-Exact $manual `
"import '../../../academic_structure/domain/entities/academic_subject_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';" `
"import '../../../academic_structure/domain/entities/academic_subject_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/entities/subject_component_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../academic_structure/domain/repositories/subject_component_repository.dart';" `
"manual subject component imports"

# 3) Add component state list.
$manual = Replace-Exact $manual `
"  List<AcademicSubjectEntity> _subjects = const [];
  List<TeacherAssignmentEntity> _assignments = const [];" `
"  List<AcademicSubjectEntity> _subjects = const [];
  List<SubjectComponentEntity> _components = const [];
  List<TeacherAssignmentEntity> _assignments = const [];" `
"manual component state"

# 4) Load components with the other reference data.
$manual = Replace-Exact $manual `
"        sl<AcademicStructureRepository>().getSubjects(),
        sl<TeacherAssignmentRepository>().getAssignments(),
      ]);" `
"        sl<AcademicStructureRepository>().getSubjects(),
        sl<TeacherAssignmentRepository>().getAssignments(),
        sl<SubjectComponentRepository>().getComponents(),
      ]);" `
"manual component load"

# 5) Store active components.
$manual = Replace-Exact $manual `
"        _subjects = subjects;
        _assignments = values[4] as List<TeacherAssignmentEntity>;
        _calendarHolidays = calendarHolidays;" `
"        _subjects = subjects;
        _assignments = values[4] as List<TeacherAssignmentEntity>;
        _components = (values[5] as List<SubjectComponentEntity>)
            .where((item) => item.isActive)
            .toList();
        _calendarHolidays = calendarHolidays;" `
"manual store components"

# 6) Expand examination-enabled subjects into component papers.
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

$manual = Replace-Exact $manual $oldManualLoop $newManualLoop "manual component expansion"

# 7) Add helper methods before _findAssignment.
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

$manual = Replace-Exact $manual `
"  TeacherAssignmentEntity? _findAssignment({" `
"$manualHelpers  TeacherAssignmentEntity? _findAssignment({" `
"manual helper insertion"

# Existing dropdown filtering already removes a subject after it has been
# selected once in the same Class/Section. Strengthen it so a stale/legacy
# paper value cannot crash the dropdown after component expansion.
$oldCell = @'
    final options = _subjectsForColumn(column)
        .where(
          (row) =>
              row.subject.id == paper?.subjectId ||
              !selectedIds.contains(row.subject.id),
        )
        .toList();
    return SizedBox(
'@

$newCell = @'
    final options = _subjectsForColumn(column)
        .where(
          (row) =>
              row.subject.id == paper?.subjectId ||
              !selectedIds.contains(row.subject.id),
        )
        .toList();

    final currentValue =
        paper != null && options.any((row) => row.subject.id == paper.subjectId)
        ? paper.subjectId
        : '';

    return SizedBox(
'@

$manual = Replace-Exact $manual $oldCell $newCell "manual selected-subject filtering"

$manual = Replace-Exact $manual `
"                value: paper?.subjectId ?? ''," `
"                value: currentValue," `
"manual safe dropdown value"

Set-Content -Path $manualPath -Value $manual -Encoding UTF8
Write-Host "Manual Date Sheet Builder patched." -ForegroundColor Green


Write-Host "Patching Auto Date Sheet Generator..." -ForegroundColor Cyan
$auto = Get-Content $autoPath -Raw

# 1) dart:convert for stable component subject IDs.
$auto = Replace-Exact $auto `
"import '../../../academic_structure/domain/entities/academic_class_entity.dart';" `
"import 'dart:convert';

import '../../../academic_structure/domain/entities/academic_class_entity.dart';" `
"auto dart:convert import"

# 2) Component imports.
$auto = Replace-Exact $auto `
"import '../../../academic_structure/domain/entities/academic_subject_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';" `
"import '../../../academic_structure/domain/entities/academic_subject_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/entities/subject_component_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../academic_structure/domain/repositories/subject_component_repository.dart';" `
"auto component imports"

# 3) Add SubjectComponentRepository to constructor and state.
$auto = Replace-Exact $auto `
"    this._academicRepository,
    this._assignmentRepository,
    this._dateSheetRepository,
    this._validator,
  );

  final AcademicStructureRepository _academicRepository;
  final TeacherAssignmentRepository _assignmentRepository;
  final ExamDateSheetRepository _dateSheetRepository;
  final ValidateExamDateSheet _validator;" `
"    this._academicRepository,
    this._assignmentRepository,
    this._dateSheetRepository,
    this._validator,
    this._componentRepository,
  );

  final AcademicStructureRepository _academicRepository;
  final TeacherAssignmentRepository _assignmentRepository;
  final ExamDateSheetRepository _dateSheetRepository;
  final ValidateExamDateSheet _validator;
  final SubjectComponentRepository _componentRepository;" `
"auto constructor component repository"

# 4) Load components.
$auto = Replace-Exact $auto `
"      _academicRepository.getSubjects(),
      _assignmentRepository.getAssignments(),
    ]);" `
"      _academicRepository.getSubjects(),
      _assignmentRepository.getAssignments(),
      _componentRepository.getComponents(),
    ]);" `
"auto component load"

# 5) Parse active components.
$auto = Replace-Exact $auto `
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
"auto component parsing"

# 6) Expand each parent subject into exam components while retaining the
# parent subject teacher assignment.
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

$auto = Replace-Exact $auto $oldAutoTask $newAutoTask "auto task component expansion"

# 7) Helper methods before _subjectsFor.
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

$auto = Replace-Exact $auto `
"  List<AcademicSubjectEntity> _subjectsFor(" `
"$autoHelpers  List<AcademicSubjectEntity> _subjectsFor(" `
"auto helper insertion"

Set-Content -Path $autoPath -Value $auto -Encoding UTF8
Write-Host "Auto Date Sheet Generator patched." -ForegroundColor Green

Write-Host ""
Write-Host "IMPORTANT: GenerateExamDateSheetOptions constructor now needs SubjectComponentRepository." -ForegroundColor Yellow
Write-Host "Patching service_locator.dart..." -ForegroundColor Cyan

$slPath = Join-Path $root "lib\core\di\service_locator.dart"
$sl = Get-Content $slPath -Raw

$oldRegistration = @'
  sl.registerLazySingleton<GenerateExamDateSheetOptions>(
    () => GenerateExamDateSheetOptions(
      sl<AcademicStructureRepository>(),
      sl<TeacherAssignmentRepository>(),
      sl<ExamDateSheetRepository>(),
      sl<ValidateExamDateSheet>(),
    ),
  );
'@

$newRegistration = @'
  sl.registerLazySingleton<GenerateExamDateSheetOptions>(
    () => GenerateExamDateSheetOptions(
      sl<AcademicStructureRepository>(),
      sl<TeacherAssignmentRepository>(),
      sl<ExamDateSheetRepository>(),
      sl<ValidateExamDateSheet>(),
      sl<SubjectComponentRepository>(),
    ),
  );
'@

if ($sl.Contains($oldRegistration)) {
    $sl = $sl.Replace($oldRegistration, $newRegistration)
    Set-Content -Path $slPath -Value $sl -Encoding UTF8
    Write-Host "service_locator.dart patched." -ForegroundColor Green
} else {
    # Handle compact formatting by locating the constructor call with regex.
    $pattern = '(?s)(sl\.registerLazySingleton<GenerateExamDateSheetOptions>\(\s*\(\)\s*=>\s*GenerateExamDateSheetOptions\(\s*sl<AcademicStructureRepository>\(\),\s*sl<TeacherAssignmentRepository>\(\),\s*sl<ExamDateSheetRepository>\(\),\s*sl<ValidateExamDateSheet>\(\),)(\s*\)\s*,?\s*\);)'
    if ([regex]::IsMatch($sl, $pattern)) {
        $sl = [regex]::Replace(
            $sl,
            $pattern,
            '$1' + "`r`n      sl<SubjectComponentRepository>()," + '$2',
            1
        )
        Set-Content -Path $slPath -Value $sl -Encoding UTF8
        Write-Host "service_locator.dart patched." -ForegroundColor Green
    } else {
        throw "Patch failed: GenerateExamDateSheetOptions registration not found in service_locator.dart"
    }
}

Write-Host ""
Write-Host "DONE." -ForegroundColor Green
Write-Host "Now run:" -ForegroundColor White
Write-Host "flutter analyze lib/features/exams/presentation/pages/manual_exam_date_sheet_builder_page.dart lib/features/exams/domain/usecases/generate_exam_date_sheet_options.dart lib/core/di/service_locator.dart" -ForegroundColor White
