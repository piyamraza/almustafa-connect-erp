import 'package:equatable/equatable.dart';

enum HomeworkQuestionStatus { newQuestion, replied, closed }

enum HomeworkReplyAuthorType { parent, teacher, admin }

class HomeworkQuestionReplyEntity extends Equatable {
  const HomeworkQuestionReplyEntity({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorType,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final HomeworkReplyAuthorType authorType;
  final String message;
  final DateTime createdAt;

  @override
  List<Object> get props => [
    id,
    authorId,
    authorName,
    authorType,
    message,
    createdAt,
  ];
}

class HomeworkQuestionEntity extends Equatable {
  HomeworkQuestionEntity({
    required this.id,
    required this.homeworkId,
    required this.homeworkTitle,
    required this.parentId,
    required this.parentName,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
    required this.classId,
    required this.sectionId,
    required this.subjectId,
    required this.subjectName,
    required this.question,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required List<HomeworkQuestionReplyEntity> replies,
  }) : replies = List.unmodifiable(replies);

  final String id;
  final String homeworkId;
  final String homeworkTitle;
  final String parentId;
  final String parentName;
  final String studentId;
  final String studentName;
  final String teacherId;
  final String classId;
  final String sectionId;
  final String subjectId;
  final String subjectName;
  final String question;
  final HomeworkQuestionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<HomeworkQuestionReplyEntity> replies;

  @override
  List<Object> get props => [
    id,
    homeworkId,
    parentId,
    studentId,
    teacherId,
    question,
    status,
    updatedAt,
    replies,
  ];
}
