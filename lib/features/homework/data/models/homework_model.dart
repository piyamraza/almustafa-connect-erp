import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/homework_entity.dart';

class HomeworkModel extends HomeworkEntity {
  HomeworkModel({
    required super.id,
    required super.academicSession,
    required super.classId,
    required super.className,
    required super.sectionId,
    required super.sectionName,
    required super.subjectId,
    required super.subjectName,
    required super.teacherId,
    required super.teacherName,
    required super.title,
    required super.description,
    required super.instructions,
    required super.assignedDate,
    required super.dueDate,
    required super.status,
    required super.attachments,
    required super.createdBy,
    required super.updatedBy,
    required super.createdAt,
    required super.updatedAt,
    super.publishedBy,
    super.publishedAt,
    super.sourceHomeworkId,
  });

  factory HomeworkModel.fromEntity(HomeworkEntity value) => HomeworkModel(
    id: value.id,
    academicSession: value.academicSession,
    classId: value.classId,
    className: value.className,
    sectionId: value.sectionId,
    sectionName: value.sectionName,
    subjectId: value.subjectId,
    subjectName: value.subjectName,
    teacherId: value.teacherId,
    teacherName: value.teacherName,
    title: value.title,
    description: value.description,
    instructions: value.instructions,
    assignedDate: value.assignedDate,
    dueDate: value.dueDate,
    status: value.status,
    attachments: value.attachments,
    createdBy: value.createdBy,
    updatedBy: value.updatedBy,
    createdAt: value.createdAt,
    updatedAt: value.updatedAt,
    publishedBy: value.publishedBy,
    publishedAt: value.publishedAt,
    sourceHomeworkId: value.sourceHomeworkId,
  );

  factory HomeworkModel.fromMap(Map<String, dynamic> map) {
    final raw = map['attachments'] as List<dynamic>? ?? const [];
    final legacyNames = (map['attachmentNames'] as List<dynamic>? ?? const [])
        .whereType<String>();

    return HomeworkModel(
      id: map['id'] as String? ?? '',
      academicSession: map['academicSession'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      className: map['className'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      sectionName: map['sectionName'] as String? ?? '',
      subjectId: map['subjectId'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      teacherId: map['teacherId'] as String? ?? '',
      teacherName: map['teacherName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      instructions: map['instructions'] as String? ?? '',
      assignedDate: _date(map['assignedDate']),
      dueDate: _date(map['dueDate']),
      status: HomeworkStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => HomeworkStatus.draft,
      ),
      attachments: [
        ...raw.whereType<Map<String, dynamic>>().map(
          (item) => HomeworkAttachmentEntity(
            id: item['id'] as String? ?? '',
            fileName: item['fileName'] as String? ?? '',
            fileUrl: item['fileUrl'] as String? ?? '',
            fileType: item['fileType'] as String? ?? '',
            fileSize: (item['fileSize'] as num?)?.toInt() ?? 0,
            storagePath: item['storagePath'] as String? ?? '',
          ),
        ),
        ...legacyNames.map(
          (name) => HomeworkAttachmentEntity(
            id: name,
            fileName: name,
            fileUrl: '',
            fileType: name.contains('.') ? name.split('.').last : 'file',
            fileSize: 0,
            storagePath: '',
          ),
        ),
      ],
      createdBy: map['createdBy'] as String? ?? 'Admin',
      updatedBy: map['updatedBy'] as String? ?? 'Admin',
      publishedBy: map['publishedBy'] as String?,
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
      publishedAt: map['publishedAt'] == null
          ? null
          : _date(map['publishedAt']),
      sourceHomeworkId: map['sourceHomeworkId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'academicSession': academicSession,
    'classId': classId,
    'className': className,
    'sectionId': sectionId,
    'sectionName': sectionName,
    'subjectId': subjectId,
    'subjectName': subjectName,
    'teacherId': teacherId,
    'teacherName': teacherName,
    'title': title,
    'description': description,
    'instructions': instructions,
    'assignedDate': Timestamp.fromDate(assignedDate),
    'dueDate': Timestamp.fromDate(dueDate),
    'status': status.name,
    'attachments': attachments
        .map(
          (item) => {
            'id': item.id,
            'fileName': item.fileName,
            'fileUrl': item.fileUrl,
            'fileType': item.fileType,
            'fileSize': item.fileSize,
            'storagePath': item.storagePath,
          },
        )
        .toList(growable: false),
    'createdBy': createdBy,
    'updatedBy': updatedBy,
    'publishedBy': publishedBy,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'publishedAt': publishedAt == null
        ? null
        : Timestamp.fromDate(publishedAt!),
    'sourceHomeworkId': sourceHomeworkId,
  };

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
