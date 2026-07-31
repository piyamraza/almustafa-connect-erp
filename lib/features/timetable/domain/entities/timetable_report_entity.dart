import 'package:equatable/equatable.dart';

import 'class_timetable_entry_entity.dart';
import 'teacher_workload_entity.dart';
import 'timetable_configuration_entity.dart';

enum TimetableReportType { classTimetable, teacherTimetable, teacherWorkload }

enum TimetableReportExportAction { printPdf, sharePdf, exportExcel }

class TimetableReportRequestEntity extends Equatable {
  const TimetableReportRequestEntity({
    required this.branchId,
    required this.academicSession,
    required this.type,
    this.classId,
    this.className,
    this.sectionId,
    this.sectionName,
    this.teacherId,
    this.teacherName,
  });

  final String branchId;
  final String academicSession;
  final TimetableReportType type;
  final String? classId;
  final String? className;
  final String? sectionId;
  final String? sectionName;
  final String? teacherId;
  final String? teacherName;

  String get reportTitle => switch (type) {
    TimetableReportType.classTimetable => 'Class Timetable',
    TimetableReportType.teacherTimetable => 'Teacher Timetable',
    TimetableReportType.teacherWorkload => 'Teacher Workload Report',
  };

  String get reportSubject => switch (type) {
    TimetableReportType.classTimetable =>
      '${className?.trim() ?? ''} - ${sectionName?.trim() ?? ''}'.trim(),
    TimetableReportType.teacherTimetable => teacherName?.trim() ?? '',
    TimetableReportType.teacherWorkload => 'All Active Teachers',
  };

  Map<String, String> get filters {
    final values = <String, String>{
      'Branch': branchId.trim(),
      'Academic Session': academicSession.trim(),
      'Report': reportTitle,
    };

    if (type == TimetableReportType.classTimetable) {
      values['Class'] = className?.trim() ?? '';
      values['Section'] = sectionName?.trim() ?? '';
    } else if (type == TimetableReportType.teacherTimetable) {
      values['Teacher'] = teacherName?.trim() ?? '';
    }

    return Map<String, String>.unmodifiable(values);
  }

  List<String> get validationErrors {
    final errors = <String>[];

    if (branchId.trim().isEmpty) {
      errors.add('Branch is required.');
    }
    if (academicSession.trim().isEmpty) {
      errors.add('Academic session is required.');
    }

    if (type == TimetableReportType.classTimetable) {
      if ((classId ?? '').trim().isEmpty || (className ?? '').trim().isEmpty) {
        errors.add('Class is required.');
      }
      if ((sectionId ?? '').trim().isEmpty ||
          (sectionName ?? '').trim().isEmpty) {
        errors.add('Section is required.');
      }
    }

    if (type == TimetableReportType.teacherTimetable) {
      if ((teacherId ?? '').trim().isEmpty ||
          (teacherName ?? '').trim().isEmpty) {
        errors.add('Teacher is required.');
      }
    }

    return errors;
  }

  @override
  List<Object?> get props => [
    branchId,
    academicSession,
    type,
    classId,
    className,
    sectionId,
    sectionName,
    teacherId,
    teacherName,
  ];
}

class TimetableReportEntity extends Equatable {
  TimetableReportEntity({
    required this.request,
    required this.configuration,
    required List<ClassTimetableEntryEntity> entries,
    required List<TeacherWorkloadEntity> workloads,
    required this.generatedAt,
  }) : entries = List<ClassTimetableEntryEntity>.unmodifiable(entries),
       workloads = List<TeacherWorkloadEntity>.unmodifiable(workloads);

  final TimetableReportRequestEntity request;
  final TimetableConfigurationEntity configuration;
  final List<ClassTimetableEntryEntity> entries;
  final List<TeacherWorkloadEntity> workloads;
  final DateTime generatedAt;

  int get assignedPeriods => entries.length;

  int get activeTeacherCount => workloads.length;

  int get totalWorkloadPeriods => workloads.fold<int>(
    0,
    (total, workload) => total + workload.assignedPeriods,
  );

  @override
  List<Object> get props => [
    request,
    configuration,
    entries,
    workloads,
    generatedAt,
  ];
}
