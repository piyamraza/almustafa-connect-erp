import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/exam_date_sheet_entity.dart';

class ExamDateSheetModel extends ExamDateSheetEntity {
  ExamDateSheetModel({
    required super.id,
    required super.examId,
    required super.examName,
    required super.academicSession,
    required super.title,
    required super.creationMode,
    required super.status,
    required super.papers,
    required super.createdAt,
    required super.updatedAt,
    super.publishedAt,
    super.generatorOptionLabel,
  });

  factory ExamDateSheetModel.fromEntity(ExamDateSheetEntity entity) {
    return ExamDateSheetModel(
      id: entity.id,
      examId: entity.examId,
      examName: entity.examName,
      academicSession: entity.academicSession,
      title: entity.title,
      creationMode: entity.creationMode,
      status: entity.status,
      papers: entity.papers,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      publishedAt: entity.publishedAt,
      generatorOptionLabel: entity.generatorOptionLabel,
    );
  }

  factory ExamDateSheetModel.fromMap(Map<String, dynamic> map) {
    final rawPapers = map['papers'] as List<dynamic>? ?? const [];

    return ExamDateSheetModel(
      id: map['id'] as String? ?? '',
      examId: map['examId'] as String? ?? '',
      examName: map['examName'] as String? ?? '',
      academicSession: map['academicSession'] as String? ?? '',
      title: map['title'] as String? ?? '',
      creationMode: _creationMode(map['creationMode'] as String?),
      status: _status(map['status'] as String?),
      papers: rawPapers
          .whereType<Map<String, dynamic>>()
          .map(_paperFromMap)
          .toList(growable: false),
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
      publishedAt: _nullableDate(map['publishedAt']),
      generatorOptionLabel: map['generatorOptionLabel'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'examId': examId,
    'examName': examName,
    'academicSession': academicSession,
    'title': title,
    'creationMode': creationMode.name,
    'status': status.name,
    'papers': papers.map(_paperToMap).toList(growable: false),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'publishedAt': publishedAt == null
        ? null
        : Timestamp.fromDate(publishedAt!),
    'generatorOptionLabel': generatorOptionLabel,
  };

  static ExamDateSheetPaperEntity _paperFromMap(Map<String, dynamic> map) {
    return ExamDateSheetPaperEntity(
      id: map['id'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      className: map['className'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      sectionName: map['sectionName'] as String? ?? '',
      subjectId: map['subjectId'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      teacherId: map['teacherId'] as String? ?? '',
      teacherName: map['teacherName'] as String? ?? '',
      examDate: _date(map['examDate']),
      startMinutes: (map['startMinutes'] as num?)?.toInt() ?? 0,
      endMinutes: (map['endMinutes'] as num?)?.toInt() ?? 0,
      totalMarks: (map['totalMarks'] as num?)?.toDouble() ?? 0,
      passingMarks: (map['passingMarks'] as num?)?.toDouble() ?? 0,
      instructions: map['instructions'] as String? ?? '',
    );
  }

  static Map<String, dynamic> _paperToMap(ExamDateSheetPaperEntity paper) => {
    'id': paper.id,
    'classId': paper.classId,
    'className': paper.className,
    'sectionId': paper.sectionId,
    'sectionName': paper.sectionName,
    'subjectId': paper.subjectId,
    'subjectName': paper.subjectName,
    'teacherId': paper.teacherId,
    'teacherName': paper.teacherName,
    'examDate': Timestamp.fromDate(paper.examDate),
    'startMinutes': paper.startMinutes,
    'endMinutes': paper.endMinutes,
    'totalMarks': paper.totalMarks,
    'passingMarks': paper.passingMarks,
    'instructions': paper.instructions,
  };

  static ExamDateSheetCreationMode _creationMode(String? value) {
    return ExamDateSheetCreationMode.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ExamDateSheetCreationMode.manual,
    );
  }

  static ExamDateSheetStatus _status(String? value) {
    return ExamDateSheetStatus.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ExamDateSheetStatus.draft,
    );
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _nullableDate(dynamic value) =>
      value == null ? null : _date(value);
}
