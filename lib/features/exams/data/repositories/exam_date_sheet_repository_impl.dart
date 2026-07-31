import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/exam_date_sheet_entity.dart';
import '../../domain/repositories/exam_date_sheet_repository.dart';
import '../models/exam_date_sheet_model.dart';

class ExamDateSheetRepositoryImpl implements ExamDateSheetRepository {
  const ExamDateSheetRepositoryImpl(this._firestoreService);

  final FirebaseFirestoreService _firestoreService;

  @override
  Future<List<ExamDateSheetEntity>> getDateSheets({
    String? examId,
    String? academicSession,
  }) async {
    final snapshot = await _firestoreService
        .collection(FirestorePaths.examDateSheets)
        .get();

    final values =
        snapshot.docs
            .map(
              (document) => ExamDateSheetModel.fromMap({
                ...document.data(),
                'id': document.id,
              }),
            )
            .where(
              (item) =>
                  (examId == null || item.examId == examId) &&
                  (academicSession == null ||
                      item.academicSession == academicSession),
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return List<ExamDateSheetEntity>.unmodifiable(values);
  }

  @override
  Future<ExamDateSheetEntity?> getDateSheetById(String id) async {
    final document = await _firestoreService
        .collection(FirestorePaths.examDateSheets)
        .doc(id)
        .get();

    if (!document.exists || document.data() == null) return null;

    return ExamDateSheetModel.fromMap({...document.data()!, 'id': document.id});
  }

  @override
  Future<void> saveDateSheet(ExamDateSheetEntity dateSheet) {
    return _firestoreService
        .collection(FirestorePaths.examDateSheets)
        .doc(dateSheet.id)
        .set(ExamDateSheetModel.fromEntity(dateSheet).toMap());
  }

  @override
  Future<void> deleteDateSheet(String id) {
    return _firestoreService
        .collection(FirestorePaths.examDateSheets)
        .doc(id)
        .delete();
  }

  @override
  Future<void> publishDateSheet(String id) async {
    final target = await getDateSheetById(id);
    if (target == null) {
      throw StateError('Date sheet was not found.');
    }

    final all = await getDateSheets(examId: target.examId);
    final batch = _firestoreService.instance.batch();
    final collection = _firestoreService.collection(
      FirestorePaths.examDateSheets,
    );
    final now = DateTime.now();

    for (final item in all) {
      if (item.id == id) {
        batch.update(collection.doc(item.id), {
          'status': ExamDateSheetStatus.published.name,
          'publishedAt': now,
          'updatedAt': now,
        });
      } else if (item.status == ExamDateSheetStatus.published) {
        batch.update(collection.doc(item.id), {
          'status': ExamDateSheetStatus.archived.name,
          'updatedAt': now,
        });
      }
    }

    await batch.commit();
  }

  @override
  Future<void> archiveDateSheet(String id) {
    return _firestoreService
        .collection(FirestorePaths.examDateSheets)
        .doc(id)
        .update({
          'status': ExamDateSheetStatus.archived.name,
          'updatedAt': DateTime.now(),
        });
  }

  @override
  String generateDateSheetId() {
    return _firestoreService.collection(FirestorePaths.examDateSheets).doc().id;
  }

  @override
  String generatePaperId() {
    return _firestoreService.collection(FirestorePaths.examDateSheets).doc().id;
  }
}
