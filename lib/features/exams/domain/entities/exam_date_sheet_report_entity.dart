import 'package:equatable/equatable.dart';

import 'exam_date_sheet_entity.dart';

enum ExamDateSheetReportType { completeSchool, parentClassCopy, teacherDuty }

enum ExamDateSheetReportAction { printPdf, sharePdf, exportExcel }

class ExamDateSheetReportRequest extends Equatable {
  const ExamDateSheetReportRequest({
    required this.dateSheet,
    required this.type,
    this.classId,
    this.className,
    this.sectionId,
    this.sectionName,
    this.teacherId,
    this.teacherName,
  });

  final ExamDateSheetEntity dateSheet;
  final ExamDateSheetReportType type;
  final String? classId;
  final String? className;
  final String? sectionId;
  final String? sectionName;
  final String? teacherId;
  final String? teacherName;

  String get title => switch (type) {
    ExamDateSheetReportType.completeSchool => 'Complete School Date Sheet',
    ExamDateSheetReportType.parentClassCopy => 'Class Date Sheet',
    ExamDateSheetReportType.teacherDuty => 'Teacher Duty Sheet',
  };

  String get subject => switch (type) {
    ExamDateSheetReportType.completeSchool => dateSheet.title,
    ExamDateSheetReportType.parentClassCopy =>
      '${className ?? ''} - ${sectionName ?? ''}'.trim(),
    ExamDateSheetReportType.teacherDuty => teacherName ?? '',
  };

  List<ExamDateSheetPaperEntity> get papers {
    final values = switch (type) {
      ExamDateSheetReportType.completeSchool => dateSheet.papers,
      ExamDateSheetReportType.parentClassCopy =>
        dateSheet.papers
            .where(
              (paper) =>
                  paper.classId == classId && paper.sectionId == sectionId,
            )
            .toList(growable: false),
      ExamDateSheetReportType.teacherDuty =>
        dateSheet.papers
            .where((paper) => paper.teacherId == teacherId)
            .toList(growable: false),
    };

    return List<ExamDateSheetPaperEntity>.of(values)..sort((first, second) {
      final date = first.examDate.compareTo(second.examDate);
      if (date != 0) return date;
      final time = first.startMinutes.compareTo(second.startMinutes);
      if (time != 0) return time;
      return first.className.compareTo(second.className);
    });
  }

  @override
  List<Object?> get props => [
    dateSheet,
    type,
    classId,
    className,
    sectionId,
    sectionName,
    teacherId,
    teacherName,
  ];
}
