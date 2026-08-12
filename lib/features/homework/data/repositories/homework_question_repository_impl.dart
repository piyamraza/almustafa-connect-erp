import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../../notifications/domain/entities/portal_notification_entity.dart';
import '../../../notifications/domain/repositories/portal_notification_repository.dart';
import '../../domain/entities/homework_question_entity.dart';
import '../../domain/repositories/homework_question_repository.dart';

class HomeworkQuestionRepositoryImpl implements HomeworkQuestionRepository {
  const HomeworkQuestionRepositoryImpl(this._service, this._notifications);

  final FirebaseFirestoreService _service;
  final PortalNotificationRepository _notifications;

  @override
  Future<List<HomeworkQuestionEntity>> getForHomework({
    required String homeworkId,
    required String parentId,
    required String studentId,
  }) async {
    final snapshot = await _service
        .collection(FirestorePaths.homeworkQuestions)
        .where('parentId', isEqualTo: parentId)
        .where('studentId', isEqualTo: studentId)
        .get();
    return _map(
      snapshot.docs,
    ).where((item) => item.homeworkId == homeworkId).toList(growable: false);
  }

  @override
  Future<List<HomeworkQuestionEntity>> getForTeacher(String teacherId) async {
    final snapshot = await _service
        .collection(FirestorePaths.homeworkQuestions)
        .where('teacherId', isEqualTo: teacherId)
        .get();
    return _map(snapshot.docs);
  }

  @override
  Future<List<HomeworkQuestionEntity>> getForAdmin() async {
    final snapshot = await _service
        .collection(FirestorePaths.homeworkQuestions)
        .get();
    return _map(snapshot.docs);
  }

  @override
  Future<List<HomeworkQuestionEntity>> getForParent(String parentId) async {
    final snapshot = await _service
        .collection(FirestorePaths.homeworkQuestions)
        .where('parentId', isEqualTo: parentId)
        .get();
    return _map(snapshot.docs);
  }

  static List<HomeworkQuestionEntity> _map(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final values =
        documents.map((doc) => _fromMap({...doc.data(), 'id': doc.id})).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(values);
  }

  @override
  Future<void> askQuestion(HomeworkQuestionEntity question) async {
    if (question.question.trim().isEmpty) {
      throw StateError('Please enter your question.');
    }
    await _service
        .collection(FirestorePaths.homeworkQuestions)
        .doc(question.id)
        .set(_toMap(question));
    // Every parent query is first visible to administration. The assigned
    // teacher receives a copy as well so either role can answer it.
    await _notifications.create(
      recipientType: PortalRecipientType.admin,
      recipientId: 'admin',
      title: question.homeworkId.isEmpty
          ? 'Parent query from ${question.parentName}'
          : 'Homework question from ${question.parentName}',
      message:
          '${question.studentName} • ${question.subjectName}: ${question.question}',
      type: PortalNotificationType.homeworkQuestion,
      referenceId: question.id,
      studentId: question.studentId,
    );
    if (question.teacherId.isNotEmpty) {
      await _notifications.create(
        recipientType: PortalRecipientType.teacher,
        recipientId: question.teacherId,
        title: 'Homework question from ${question.parentName}',
        message:
            '${question.studentName} asked about ${question.subjectName}: ${question.question}',
        type: PortalNotificationType.homeworkQuestion,
        referenceId: question.id,
        studentId: question.studentId,
      );
    }
  }

  @override
  Future<void> addReply({
    required HomeworkQuestionEntity question,
    required HomeworkQuestionReplyEntity reply,
  }) async {
    if (reply.message.trim().isEmpty) return;
    final replies = [...question.replies, reply];
    await _service
        .collection(FirestorePaths.homeworkQuestions)
        .doc(question.id)
        .update({
          'replies': replies.map(_replyToMap).toList(growable: false),
          'status': HomeworkQuestionStatus.replied.name,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
    if (reply.authorType != HomeworkReplyAuthorType.parent) {
      await _notifications.create(
        recipientType: PortalRecipientType.parent,
        recipientId: question.parentId,
        title: '${reply.authorName} replied to your homework question',
        message: reply.message,
        type: PortalNotificationType.homeworkReply,
        referenceId: question.id,
        studentId: question.studentId,
      );
    }
  }

  @override
  Future<void> closeQuestion(HomeworkQuestionEntity question) => _service
      .collection(FirestorePaths.homeworkQuestions)
      .doc(question.id)
      .update({
        'status': HomeworkQuestionStatus.closed.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

  @override
  String generateId() =>
      _service.collection(FirestorePaths.homeworkQuestions).doc().id;

  @override
  String generateReplyId() => generateId();

  static HomeworkQuestionEntity _fromMap(Map<String, dynamic> map) {
    final rawReplies = map['replies'] as List<dynamic>? ?? const [];
    return HomeworkQuestionEntity(
      id: map['id']?.toString() ?? '',
      homeworkId: map['homeworkId']?.toString() ?? '',
      homeworkTitle: map['homeworkTitle']?.toString() ?? '',
      parentId: map['parentId']?.toString() ?? '',
      parentName: map['parentName']?.toString() ?? '',
      studentId: map['studentId']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? '',
      teacherId: map['teacherId']?.toString() ?? '',
      classId: map['classId']?.toString() ?? '',
      sectionId: map['sectionId']?.toString() ?? '',
      subjectId: map['subjectId']?.toString() ?? '',
      subjectName: map['subjectName']?.toString() ?? '',
      question: map['question']?.toString() ?? '',
      status: HomeworkQuestionStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => HomeworkQuestionStatus.newQuestion,
      ),
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
      replies: rawReplies
          .whereType<Map<String, dynamic>>()
          .map(_replyFromMap)
          .toList(growable: false),
    );
  }

  static Map<String, dynamic> _toMap(HomeworkQuestionEntity item) => {
    'homeworkId': item.homeworkId,
    'homeworkTitle': item.homeworkTitle,
    'parentId': item.parentId,
    'parentName': item.parentName,
    'studentId': item.studentId,
    'studentName': item.studentName,
    'teacherId': item.teacherId,
    'classId': item.classId,
    'sectionId': item.sectionId,
    'subjectId': item.subjectId,
    'subjectName': item.subjectName,
    'question': item.question,
    'status': item.status.name,
    'createdAt': Timestamp.fromDate(item.createdAt),
    'updatedAt': Timestamp.fromDate(item.updatedAt),
    'replies': item.replies.map(_replyToMap).toList(growable: false),
  };

  static HomeworkQuestionReplyEntity _replyFromMap(Map<String, dynamic> map) {
    return HomeworkQuestionReplyEntity(
      id: map['id']?.toString() ?? '',
      authorId: map['authorId']?.toString() ?? '',
      authorName: map['authorName']?.toString() ?? '',
      authorType: HomeworkReplyAuthorType.values.firstWhere(
        (value) => value.name == map['authorType'],
        orElse: () => HomeworkReplyAuthorType.admin,
      ),
      message: map['message']?.toString() ?? '',
      createdAt: _date(map['createdAt']),
    );
  }

  static Map<String, dynamic> _replyToMap(HomeworkQuestionReplyEntity item) => {
    'id': item.id,
    'authorId': item.authorId,
    'authorName': item.authorName,
    'authorType': item.authorType.name,
    'message': item.message,
    'createdAt': Timestamp.fromDate(item.createdAt),
  };

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
