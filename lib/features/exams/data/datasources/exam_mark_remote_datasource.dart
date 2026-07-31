import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../models/exam_mark_model.dart';

abstract class ExamMarkRemoteDataSource {
  Future<List<ExamMarkModel>> getMarksForEntry(String entryKey);
  Future<List<ExamMarkModel>> getMarksForExam(String examId);
  Future<void> saveMarks(List<ExamMarkModel> marks);
  Future<void> deleteMark(String id);
}

class ExamMarkRemoteDataSourceImpl implements ExamMarkRemoteDataSource {
  ExamMarkRemoteDataSourceImpl({
    required FirebaseFirestoreService firestoreService,
  }) : _service = firestoreService;

  final FirebaseFirestoreService _service;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _service.collection(FirestorePaths.examMarks);

  @override
  Future<List<ExamMarkModel>> getMarksForEntry(String entryKey) async {
    final snapshot = await _collection
        .where('entryKey', isEqualTo: entryKey)
        .get();

    final marks = snapshot.docs
        .map((document) => ExamMarkModel.fromMap({
              ...document.data(),
              'id': document.id,
            }))
        .toList(growable: false);
    marks.sort((first, second) => first.updatedAt.compareTo(second.updatedAt));
    return marks;
  }

  @override
  Future<List<ExamMarkModel>> getMarksForExam(String examId) async {
    if (examId.trim().isEmpty) {
      throw ArgumentError.value(examId, 'examId', 'Exam ID cannot be empty.');
    }

    final snapshot = await _collection.where('examId', isEqualTo: examId).get();
    final marks = snapshot.docs
        .map(
          (document) => ExamMarkModel.fromMap({
            ...document.data(),
            'id': document.id,
          }),
        )
        .toList(growable: false);
    marks.sort((first, second) => first.updatedAt.compareTo(second.updatedAt));
    return marks;
  }

  @override
  Future<void> saveMarks(List<ExamMarkModel> marks) async {
    if (marks.isEmpty) return;

    final ids = <String>{};
    for (final mark in marks) {
      if (mark.id.trim().isEmpty) {
        throw ArgumentError.value(mark.id, 'mark.id', 'Mark ID cannot be empty.');
      }
      if (!ids.add(mark.id)) {
        throw StateError('Duplicate marks were submitted for the same student.');
      }
    }

    for (var start = 0; start < marks.length; start += 500) {
      final end = start + 500 > marks.length ? marks.length : start + 500;
      final batch = _service.instance.batch();
      for (final mark in marks.sublist(start, end)) {
        batch.set(_collection.doc(mark.id), mark.toMap());
      }
      await batch.commit();
    }
  }

  @override
  Future<void> deleteMark(String id) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Mark ID cannot be empty.');
    }
    return _collection.doc(id).delete();
  }
}
