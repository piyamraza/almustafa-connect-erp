import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/exam_result_entity.dart';
import '../models/exam_result_model.dart';

abstract class ExamResultRemoteDataSource {
  Future<List<ExamResultModel>> getResultsForExam(String examId);

  Future<List<ExamResultModel>> getPublishedResults({
    String? examId,
    String? classId,
    String? sectionId,
    String? studentId,
  });

  Future<void> saveResults(List<ExamResultModel> results);

  Future<void> updateStatus({
    required List<String> resultIds,
    required ResultStatus status,
    bool setPublishedAt = true,
  });
}

class ExamResultRemoteDataSourceImpl implements ExamResultRemoteDataSource {
  ExamResultRemoteDataSourceImpl({
    required FirebaseFirestoreService firestoreService,
  }) : _service = firestoreService;

  final FirebaseFirestoreService _service;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _service.collection(FirestorePaths.examResults);

  @override
  Future<List<ExamResultModel>> getResultsForExam(String examId) async {
    if (examId.trim().isEmpty) {
      throw ArgumentError.value(examId, 'examId', 'Exam ID cannot be empty.');
    }
    final snapshot = await _collection.where('examId', isEqualTo: examId).get();
    final results = snapshot.docs
        .map(
          (document) => ExamResultModel.fromMap({
            ...document.data(),
            'id': document.id,
          }),
        )
        .toList(growable: false);
    results.sort((first, second) {
      final classOrder = first.className.compareTo(second.className);
      if (classOrder != 0) return classOrder;
      final sectionOrder = first.sectionName.compareTo(second.sectionName);
      if (sectionOrder != 0) return sectionOrder;
      final firstRoll = int.tryParse(first.rollNumber.trim());
      final secondRoll = int.tryParse(second.rollNumber.trim());
      if (firstRoll != null && secondRoll != null) {
        return firstRoll.compareTo(secondRoll);
      }
      return first.studentName.compareTo(second.studentName);
    });
    return results;
  }

  @override
  Future<List<ExamResultModel>> getPublishedResults({
    String? examId,
    String? classId,
    String? sectionId,
    String? studentId,
  }) async {
    final snapshot = await _collection
        .where('status', whereIn: [
          ResultStatus.published.name,
          ResultStatus.locked.name,
        ])
        .get();
    final results = snapshot.docs
        .map(
          (document) => ExamResultModel.fromMap({
            ...document.data(),
            'id': document.id,
          }),
        )
        .where(
          (result) =>
              (examId == null || result.examId == examId) &&
              (classId == null || result.classId == classId) &&
              (sectionId == null || result.sectionId == sectionId) &&
              (studentId == null || result.studentId == studentId),
        )
        .toList(growable: false);
    results.sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
    return results;
  }

  @override
  Future<void> saveResults(List<ExamResultModel> results) async {
    if (results.isEmpty) return;
    final ids = <String>{};
    for (final result in results) {
      if (result.id.trim().isEmpty) {
        throw ArgumentError.value(result.id, 'result.id', 'Result ID cannot be empty.');
      }
      if (!ids.add(result.id)) {
        throw StateError('Duplicate results were generated for a student.');
      }
    }
    for (var start = 0; start < results.length; start += 500) {
      final end = start + 500 > results.length ? results.length : start + 500;
      final batch = _service.instance.batch();
      for (final result in results.sublist(start, end)) {
        batch.set(_collection.doc(result.id), result.toMap());
      }
      await batch.commit();
    }
  }

  @override
  Future<void> updateStatus({
    required List<String> resultIds,
    required ResultStatus status,
    bool setPublishedAt = true,
  }) async {
    if (resultIds.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    final updates = <String, dynamic>{
      'status': status.name,
      'updatedAt': now,
      if (status == ResultStatus.published && setPublishedAt) 'publishedAt': now,
    };
    for (var start = 0; start < resultIds.length; start += 500) {
      final end = start + 500 > resultIds.length ? resultIds.length : start + 500;
      final batch = _service.instance.batch();
      for (final id in resultIds.sublist(start, end)) {
        batch.update(_collection.doc(id), updates);
      }
      await batch.commit();
    }
  }
}
