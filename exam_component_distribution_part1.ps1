[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=(Get-Location).Path
$utf8=New-Object System.Text.UTF8Encoding($false)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$backup=Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\exam_component_distribution_part1_$stamp"

function Full([string]$p){Join-Path $root $p}
function BackupFile([string]$p){
  $s=Full $p
  if(-not(Test-Path $s)){throw "Required file not found: $p"}
  $d=Join-Path $backup $p
  New-Item -ItemType Directory -Force -Path (Split-Path $d -Parent)|Out-Null
  Copy-Item $s $d -Force
}
function WriteText([string]$p,[string]$t){
  [IO.File]::WriteAllText((Full $p),$t.Replace("`r`n","`n"),$utf8)
}

if(-not(Test-Path (Full 'pubspec.yaml'))){throw 'Run from project root.'}

$entity='lib/features/exams/domain/entities/exam_subject_setup_entity.dart'
$model='lib/features/exams/data/models/exam_subject_setup_model.dart'
$service='lib/features/academic_structure/domain/services/subject_component_exam_service.dart'
$validation='lib/features/exams/domain/usecases/create_exam_subject_setups.dart'

foreach($f in @($entity,$model,$service,$validation)){BackupFile $f}

WriteText $entity @'
import 'package:equatable/equatable.dart';

/// Subject configuration for one examination, class and section.
class ExamSubjectSetupEntity extends Equatable {
  const ExamSubjectSetupEntity({
    required this.id,
    required this.examId,
    required this.examName,
    required this.academicSession,
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    required this.subjectId,
    required this.subjectName,
    required this.totalMarks,
    required this.passingMarks,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.academicYearId = '',
    this.theoryMarks = 0,
    this.practicalMarks = 0,
    this.internalAssessmentMarks = 0,
    this.displayOrder = 0,
    this.componentTotalMarks = const {},
    this.componentPassingMarks = const {},
  });

  final String id;
  final String examId;
  final String examName;
  final String academicSession;
  final String academicYearId;
  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;
  final String subjectId;
  final String subjectName;
  final double totalMarks;
  final double passingMarks;
  final double theoryMarks;
  final double practicalMarks;
  final double internalAssessmentMarks;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Component ID -> maximum marks.
  ///
  /// Empty maps represent legacy setups and allow equal-distribution fallback.
  final Map<String, double> componentTotalMarks;

  /// Component ID -> passing marks.
  final Map<String, double> componentPassingMarks;

  String get uniqueKey => '${examId}_${classId}_${sectionId}_$subjectId';

  double get configuredBreakdownMarks =>
      theoryMarks + practicalMarks + internalAssessmentMarks;

  bool get hasMarksBreakdown => configuredBreakdownMarks > 0;

  bool get isMarksBreakdownValid =>
      !hasMarksBreakdown || configuredBreakdownMarks == totalMarks;

  bool get isPassingMarksValid =>
      passingMarks >= 0 && passingMarks <= totalMarks;

  bool get hasComponentDistribution => componentTotalMarks.isNotEmpty;

  double get configuredComponentTotal => componentTotalMarks.values.fold(
        0,
        (sum, value) => sum + value,
      );

  double get configuredComponentPassing =>
      componentPassingMarks.values.fold(0, (sum, value) => sum + value);

  bool get isComponentDistributionValid {
    if (!hasComponentDistribution) return true;
    return _same(configuredComponentTotal, totalMarks) &&
        componentTotalMarks.keys.every(
          (id) {
            final total = componentTotalMarks[id] ?? 0;
            final passing = componentPassingMarks[id] ?? 0;
            return total > 0 && passing >= 0 && passing <= total;
          },
        );
  }

  ExamSubjectSetupEntity copyWith({
    String? id,
    String? examId,
    String? examName,
    String? academicSession,
    String? academicYearId,
    String? classId,
    String? className,
    String? sectionId,
    String? sectionName,
    String? subjectId,
    String? subjectName,
    double? totalMarks,
    double? passingMarks,
    double? theoryMarks,
    double? practicalMarks,
    double? internalAssessmentMarks,
    int? displayOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, double>? componentTotalMarks,
    Map<String, double>? componentPassingMarks,
  }) {
    return ExamSubjectSetupEntity(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      examName: examName ?? this.examName,
      academicSession: academicSession ?? this.academicSession,
      academicYearId: academicYearId ?? this.academicYearId,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      totalMarks: totalMarks ?? this.totalMarks,
      passingMarks: passingMarks ?? this.passingMarks,
      theoryMarks: theoryMarks ?? this.theoryMarks,
      practicalMarks: practicalMarks ?? this.practicalMarks,
      internalAssessmentMarks:
          internalAssessmentMarks ?? this.internalAssessmentMarks,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      componentTotalMarks:
          componentTotalMarks ?? this.componentTotalMarks,
      componentPassingMarks:
          componentPassingMarks ?? this.componentPassingMarks,
    );
  }

  static bool _same(double first, double second) =>
      (first - second).abs() < 0.001;

  @override
  List<Object?> get props => [
        id,
        examId,
        examName,
        academicSession,
        academicYearId,
        classId,
        className,
        sectionId,
        sectionName,
        subjectId,
        subjectName,
        totalMarks,
        passingMarks,
        theoryMarks,
        practicalMarks,
        internalAssessmentMarks,
        displayOrder,
        isActive,
        createdAt,
        updatedAt,
        componentTotalMarks,
        componentPassingMarks,
      ];
}
'@

WriteText $model @'
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/exam_subject_setup_entity.dart';

class ExamSubjectSetupModel extends ExamSubjectSetupEntity {
  const ExamSubjectSetupModel({
    required super.id,
    required super.examId,
    required super.examName,
    required super.academicSession,
    required super.classId,
    required super.className,
    required super.sectionId,
    required super.sectionName,
    required super.subjectId,
    required super.subjectName,
    required super.totalMarks,
    required super.passingMarks,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.academicYearId,
    super.theoryMarks,
    super.practicalMarks,
    super.internalAssessmentMarks,
    super.displayOrder,
    super.componentTotalMarks,
    super.componentPassingMarks,
  });

  factory ExamSubjectSetupModel.fromEntity(
    ExamSubjectSetupEntity entity,
  ) {
    return ExamSubjectSetupModel(
      id: entity.id,
      examId: entity.examId,
      examName: entity.examName,
      academicSession: entity.academicSession,
      academicYearId: entity.academicYearId,
      classId: entity.classId,
      className: entity.className,
      sectionId: entity.sectionId,
      sectionName: entity.sectionName,
      subjectId: entity.subjectId,
      subjectName: entity.subjectName,
      totalMarks: entity.totalMarks,
      passingMarks: entity.passingMarks,
      theoryMarks: entity.theoryMarks,
      practicalMarks: entity.practicalMarks,
      internalAssessmentMarks: entity.internalAssessmentMarks,
      displayOrder: entity.displayOrder,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      componentTotalMarks: entity.componentTotalMarks,
      componentPassingMarks: entity.componentPassingMarks,
    );
  }

  factory ExamSubjectSetupModel.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();

    return ExamSubjectSetupModel(
      id: map['id'] as String? ?? '',
      examId: map['examId'] as String? ?? '',
      examName: map['examName'] as String? ?? '',
      academicSession: map['academicSession'] as String? ?? '',
      academicYearId: map['academicYearId'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      className: map['className'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      sectionName: map['sectionName'] as String? ?? '',
      subjectId: map['subjectId'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      totalMarks: _number(map['totalMarks']),
      passingMarks: _number(map['passingMarks']),
      theoryMarks: _number(map['theoryMarks']),
      practicalMarks: _number(map['practicalMarks']),
      internalAssessmentMarks:
          _number(map['internalAssessmentMarks']),
      displayOrder: _integer(map['displayOrder']),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _date(map['createdAt']) ?? now,
      updatedAt: _date(map['updatedAt']) ?? now,
      componentTotalMarks: _numberMap(map['componentTotalMarks']),
      componentPassingMarks:
          _numberMap(map['componentPassingMarks']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'examId': examId,
      'examName': examName,
      'academicSession': academicSession,
      'academicYearId': academicYearId,
      'classId': classId,
      'className': className,
      'sectionId': sectionId,
      'sectionName': sectionName,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'uniqueKey': uniqueKey,
      'totalMarks': totalMarks,
      'passingMarks': passingMarks,
      'theoryMarks': theoryMarks,
      'practicalMarks': practicalMarks,
      'internalAssessmentMarks': internalAssessmentMarks,
      'componentTotalMarks': componentTotalMarks,
      'componentPassingMarks': componentPassingMarks,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'schemaVersion': 3,
    };
  }

  static Map<String, double> _numberMap(dynamic value) {
    if (value is! Map) return const {};
    return Map.unmodifiable({
      for (final entry in value.entries)
        entry.key.toString(): _number(entry.value),
    });
  }

  static double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _integer(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
'@

WriteText $service @'
import 'dart:convert';

import '../../../exams/domain/entities/exam_subject_setup_entity.dart';
import '../entities/academic_subject_entity.dart';
import '../entities/subject_component_entity.dart';
import '../repositories/academic_structure_repository.dart';
import '../repositories/subject_component_repository.dart';

class SubjectComponentExamService {
  const SubjectComponentExamService(
    this._academicRepository,
    this._componentRepository,
  );

  final AcademicStructureRepository _academicRepository;
  final SubjectComponentRepository _componentRepository;

  Future<List<ExamSubjectSetupEntity>> expandSetups(
    List<ExamSubjectSetupEntity> setups,
  ) async {
    final subjects = await _academicRepository.getSubjects();
    final components = await _componentRepository.getComponents();
    final subjectsById = {for (final item in subjects) item.id: item};
    final output = <ExamSubjectSetupEntity>[];

    for (final setup in setups) {
      final parent = _resolveParent(
        setup,
        subjects,
        subjectsById,
        components,
      );

      final active = parent == null
          ? const <SubjectComponentEntity>[]
          : (components
                .where(
                  (item) =>
                      item.parentSubjectId == parent.id && item.isActive,
                )
                .toList()
              ..sort(
                (a, b) => a.displayOrder.compareTo(b.displayOrder),
              ));

      if (parent == null ||
          !parent.useComponentsInExamination ||
          active.isEmpty) {
        output.add(setup);
        continue;
      }

      final useManual = setup.componentTotalMarks.isNotEmpty;

      for (final component in active) {
        final total = useManual
            ? setup.componentTotalMarks[component.id]
            : setup.totalMarks / active.length;
        final passing = useManual
            ? setup.componentPassingMarks[component.id]
            : setup.passingMarks / active.length;

        if (total == null || total <= 0 || passing == null) {
          throw StateError(
            'Component marks are incomplete for '
            '${setup.subjectName} (${setup.className}-${setup.sectionName}).',
          );
        }

        final encodedParent = base64Url
            .encode(utf8.encode(parent.name))
            .replaceAll('=', '');
        final reportFlag = parent.useComponentsInReportCard ? '1' : '0';

        output.add(
          setup.copyWith(
            id: '${setup.id}::${component.id}',
            subjectId:
                'cmp::${parent.id}::$encodedParent::$reportFlag::${component.id}',
            subjectName: _componentDisplayName(
              parent.name,
              component.componentName,
            ),
            totalMarks: total,
            passingMarks: passing,
            componentTotalMarks: const {},
            componentPassingMarks: const {},
          ),
        );
      }
    }

    return List.unmodifiable(output);
  }

  AcademicSubjectEntity? _resolveParent(
    ExamSubjectSetupEntity setup,
    List<AcademicSubjectEntity> subjects,
    Map<String, AcademicSubjectEntity> subjectsById,
    List<SubjectComponentEntity> components,
  ) {
    final exact = subjectsById[setup.subjectId];
    if (exact != null &&
        exact.useComponentsInExamination &&
        components.any(
          (item) => item.parentSubjectId == exact.id && item.isActive,
        )) {
      return exact;
    }

    final name = _normalize(setup.subjectName);
    for (final subject in subjects) {
      if (_normalize(subject.name) == name &&
          subject.useComponentsInExamination &&
          components.any(
            (item) =>
                item.parentSubjectId == subject.id && item.isActive,
          )) {
        return subject;
      }
    }
    return exact;
  }

  static String _componentDisplayName(
    String parentName,
    String componentName,
  ) {
    final parent = parentName.trim();
    final component = componentName.trim();
    if (parent.isEmpty) return component;
    if (component.isEmpty) return parent;

    final normalizedParent = _normalize(parent);
    final normalizedComponent = _normalize(component);
    if (normalizedComponent == normalizedParent ||
        normalizedComponent.startsWith('$normalizedParent ')) {
      return component;
    }
    return '$parent $component';
  }

  static String _normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static bool isComponentId(String value) =>
      value.startsWith('cmp::') && value.split('::').length == 5;

  static String? parentId(String value) =>
      isComponentId(value) ? value.split('::')[1] : null;

  static String? parentName(String value) {
    if (!isComponentId(value)) return null;
    try {
      final raw = value.split('::')[2];
      return utf8.decode(base64Url.decode(base64Url.normalize(raw)));
    } catch (_) {
      return null;
    }
  }

  static bool useInReportCard(String value) =>
      isComponentId(value) && value.split('::')[3] == '1';
}
'@

WriteText $validation @'
import '../entities/exam_subject_setup_entity.dart';
import '../repositories/exam_subject_setup_repository.dart';

class CreateExamSubjectSetups {
  const CreateExamSubjectSetups(this._repository);

  final ExamSubjectSetupRepository _repository;

  Future<void> call(List<ExamSubjectSetupEntity> setups) async {
    if (setups.isEmpty) {
      throw ArgumentError('Add at least one subject setup.');
    }

    final keys = <String>{};
    for (final setup in setups) {
      validateExamSubjectSetup(setup);
      if (!keys.add(setup.uniqueKey)) {
        throw ArgumentError('Duplicate subject setup selected.');
      }
    }

    await _repository.createSetups(setups);
  }
}

void validateExamSubjectSetup(ExamSubjectSetupEntity setup) {
  if (setup.examId.trim().isEmpty) {
    throw ArgumentError('Exam is required.');
  }
  if (setup.classId.trim().isEmpty) {
    throw ArgumentError('Class is required.');
  }
  if (setup.sectionId.trim().isEmpty) {
    throw ArgumentError('Section is required.');
  }
  if (setup.subjectId.trim().isEmpty) {
    throw ArgumentError('Subject is required.');
  }
  if (setup.totalMarks <= 0) {
    throw ArgumentError('Total marks must be greater than zero.');
  }
  if (setup.passingMarks < 0 ||
      setup.passingMarks > setup.totalMarks) {
    throw ArgumentError(
      'Passing marks must be between zero and total marks.',
    );
  }
  if (!setup.isComponentDistributionValid) {
    throw ArgumentError(
      'Component marks for ${setup.subjectName} are invalid or '
      'do not equal the subject total.',
    );
  }
}
'@

dart format $entity $model $service $validation
if($LASTEXITCODE -ne 0){throw "FORMAT ERROR. Backup: $backup"}

flutter analyze lib/features/exams lib/features/academic_structure --no-fatal-infos --no-fatal-warnings
if($LASTEXITCODE -ne 0){throw "ANALYZE ERROR. Backup: $backup"}

Write-Host ''
Write-Host 'Exam Component Distribution Part 1 completed.' -ForegroundColor Green
Write-Host 'Backend storage, validation and runtime expansion are ready.' -ForegroundColor Green
Write-Host 'Legacy exams continue to use equal-distribution fallback.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
