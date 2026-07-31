import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../models/exam_model.dart';

abstract class ExamRemoteDataSource {
  Future<List<ExamModel>> getExams({
    String? academicSession,
    bool? isActive,
  });

  Future<ExamModel?> getExamById(String id);

  Future<void> createExam(ExamModel exam);

  Future<void> updateExam(ExamModel exam);

  Future<void> deleteExam(String id);

  Future<void> setExamActiveStatus({
    required String id,
    required bool isActive,
  });

  String generateId();
}

class ExamRemoteDataSourceImpl implements ExamRemoteDataSource {
  ExamRemoteDataSourceImpl({
    required this._firestoreService,
  });

  final FirebaseFirestoreService _firestoreService;

  CollectionReference<Map<String, dynamic>> get _examsCollection {
    return _firestoreService.collection(FirestorePaths.examConfigurations);
  }

  @override
  Future<List<ExamModel>> getExams({
    String? academicSession,
    bool? isActive,
  }) async {
    Query<Map<String, dynamic>> query = _examsCollection;

    if (academicSession != null && academicSession.trim().isNotEmpty) {
      query = query.where(
        'academicSession',
        isEqualTo: academicSession.trim(),
      );
    }
    if (isActive != null) {
      query = query.where('isActive', isEqualTo: isActive);
    }

    final snapshot = await query.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((document) => ExamModel.fromMap({
              ...document.data(),
              'id': document.id,
            }))
        .toList(growable: false);
  }

  @override
  Future<ExamModel?> getExamById(String id) async {
    final normalizedId = _requireId(id);
    final snapshot = await _examsCollection.doc(normalizedId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return ExamModel.fromMap({...snapshot.data()!, 'id': snapshot.id});
  }

  @override
  Future<void> createExam(ExamModel exam) async {
    final reference = _examsCollection.doc(_requireId(exam.id));
    if (await _hasDuplicateExam(exam)) {
      throw StateError(
        'An exam with the same name already exists for this academic session.',
      );
    }
    await _firestoreService.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (snapshot.exists) {
        throw StateError('An examination with this ID already exists.');
      }
      transaction.set(reference, exam.toMap());
    });
  }

  @override
  Future<void> updateExam(ExamModel exam) async {
    if (await _hasDuplicateExam(exam)) {
      throw StateError(
        'An exam with the same name already exists for this academic session.',
      );
    }
    await _examsCollection.doc(_requireId(exam.id)).update(exam.toMap());
  }

  @override
  Future<void> deleteExam(String id) async {
    await _examsCollection.doc(_requireId(id)).delete();
  }

  @override
  Future<void> setExamActiveStatus({
    required String id,
    required bool isActive,
  }) async {
    await _examsCollection.doc(_requireId(id)).update({'isActive': isActive});
  }

  @override
  String generateId() => _examsCollection.doc().id;

  String _requireId(String id) {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Exam ID cannot be empty.');
    }
    return normalizedId;
  }

  Future<bool> _hasDuplicateExam(ExamModel exam) async {
    final snapshot = await _examsCollection
        .where('academicSession', isEqualTo: exam.academicSession.trim())
        .get();
    final normalizedName = _normalize(exam.name);
    return snapshot.docs.any((document) {
      if (document.id == exam.id) {
        return false;
      }
      return _normalize(document.data()['name'] as String? ?? '') ==
          normalizedName;
    });
  }

  String _normalize(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }
}
