import '../entities/homework_question_entity.dart';

abstract class HomeworkQuestionRepository {
  Future<List<HomeworkQuestionEntity>> getForHomework({
    required String homeworkId,
    required String parentId,
    required String studentId,
  });

  Future<List<HomeworkQuestionEntity>> getForTeacher(String teacherId);
  Future<List<HomeworkQuestionEntity>> getForAdmin();
  Future<List<HomeworkQuestionEntity>> getForParent(String parentId);

  Future<void> askQuestion(HomeworkQuestionEntity question);

  Future<void> addReply({
    required HomeworkQuestionEntity question,
    required HomeworkQuestionReplyEntity reply,
  });

  Future<void> closeQuestion(HomeworkQuestionEntity question);
  String generateId();
  String generateReplyId();
}
