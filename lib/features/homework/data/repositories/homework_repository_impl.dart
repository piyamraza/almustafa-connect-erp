import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/homework_entity.dart';
import '../../domain/repositories/homework_repository.dart';
import '../models/homework_model.dart';

class HomeworkRepositoryImpl implements HomeworkRepository {
  const HomeworkRepositoryImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<List<HomeworkEntity>> getHomework({
    required String academicSession,
    HomeworkStatus? status,
    String? classId,
    String? sectionId,
    String? subjectId,
    String? teacherId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final snapshot = await _service.collection(FirestorePaths.homework).get();

    final values =
        snapshot.docs
            .map((doc) => HomeworkModel.fromMap({...doc.data(), 'id': doc.id}))
            .where(
              (item) =>
                  item.academicSession == academicSession &&
                  (status == null || item.status == status) &&
                  (classId == null || item.classId == classId) &&
                  (sectionId == null || item.sectionId == sectionId) &&
                  (subjectId == null || item.subjectId == subjectId) &&
                  (teacherId == null || item.teacherId == teacherId) &&
                  (fromDate == null || !item.assignedDate.isBefore(fromDate)) &&
                  (toDate == null || !item.assignedDate.isAfter(toDate)),
            )
            .toList()
          ..sort((a, b) => b.assignedDate.compareTo(a.assignedDate));

    return List.unmodifiable(values);
  }

  @override
  Future<void> saveHomework(HomeworkEntity homework) async {
    if (homework.title.trim().isEmpty) {
      throw StateError('Homework title is required.');
    }
    if (homework.dueDate.isBefore(homework.assignedDate)) {
      throw StateError('Due date cannot be before assigned date.');
    }

    await _service
        .collection(FirestorePaths.homework)
        .doc(homework.id)
        .set(HomeworkModel.fromEntity(homework).toMap());
  }

  @override
  Future<void> deleteHomework(String id) =>
      _service.collection(FirestorePaths.homework).doc(id).delete();

  @override
  Future<bool> duplicateExists(HomeworkEntity homework) async {
    final values = await getHomework(
      academicSession: homework.academicSession,
      classId: homework.classId,
      sectionId: homework.sectionId,
      subjectId: homework.subjectId,
    );

    return values.any(
      (item) =>
          item.id != homework.id &&
          item.title.trim().toLowerCase() ==
              homework.title.trim().toLowerCase() &&
          _sameDay(item.assignedDate, homework.assignedDate),
    );
  }

  @override
  String generateId() => _service.collection(FirestorePaths.homework).doc().id;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
