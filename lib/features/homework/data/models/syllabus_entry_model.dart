import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/syllabus_entry_entity.dart';

class SyllabusEntryModel extends SyllabusEntryEntity {
  const SyllabusEntryModel({
    required super.id,
    required super.planId,
    required super.academicSession,
    required super.syllabusTitle,
    required super.classId,
    required super.className,
    required super.sectionId,
    required super.sectionName,
    required super.subjectId,
    required super.subjectName,
    required super.content,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SyllabusEntryModel.fromEntity(SyllabusEntryEntity value) =>
      SyllabusEntryModel(
        id: value.id,
        planId: value.planId,
        academicSession: value.academicSession,
        syllabusTitle: value.syllabusTitle,
        classId: value.classId,
        className: value.className,
        sectionId: value.sectionId,
        sectionName: value.sectionName,
        subjectId: value.subjectId,
        subjectName: value.subjectName,
        content: value.content,
        createdAt: value.createdAt,
        updatedAt: value.updatedAt,
      );

  factory SyllabusEntryModel.fromMap(Map<String, dynamic> map) =>
      SyllabusEntryModel(
        id: map['id'] as String? ?? '',
        planId: map['planId'] as String? ?? '',
        academicSession: map['academicSession'] as String? ?? '',
        syllabusTitle: map['syllabusTitle'] as String? ?? '',
        classId: map['classId'] as String? ?? '',
        className: map['className'] as String? ?? '',
        sectionId: map['sectionId'] as String? ?? '',
        sectionName: map['sectionName'] as String? ?? '',
        subjectId: map['subjectId'] as String? ?? '',
        subjectName: map['subjectName'] as String? ?? '',
        content: map['content'] as String? ?? '',
        createdAt: _date(map['createdAt']),
        updatedAt: _date(map['updatedAt']),
      );

  Map<String, dynamic> toMap() => {
    'academicSession': academicSession,
    'planId': planId,
    'syllabusTitle': syllabusTitle,
    'classId': classId,
    'className': className,
    'sectionId': sectionId,
    'sectionName': sectionName,
    'subjectId': subjectId,
    'subjectName': subjectName,
    'content': content,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
