import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../models/exam_subject_setup_model.dart';

abstract class ExamSubjectSetupRemoteDataSource {
  Future<List<ExamSubjectSetupModel>> getSetups();
  Future<List<ExamSubjectSetupModel>> getSetupsForExam(String examId);
  Future<void> createSetups(List<ExamSubjectSetupModel> setups);
  Future<void> updateSetup(ExamSubjectSetupModel setup);
  Future<void> deleteSetup(String id);
  Future<void> synchronizeExamSetups({
    required String examId,
    required List<ExamSubjectSetupModel> selectedSetups,
  });
  String generateId();
}

class ExamSubjectSetupRemoteDataSourceImpl
    implements ExamSubjectSetupRemoteDataSource {
  ExamSubjectSetupRemoteDataSourceImpl({
    required FirebaseFirestoreService firestoreService,
  }) : _service = firestoreService;
  final FirebaseFirestoreService _service;
  CollectionReference<Map<String, dynamic>> get _collection =>
      _service.collection(FirestorePaths.examSubjectSetups);
  @override
  Future<List<ExamSubjectSetupModel>> getSetups() async {
    final result = await _collection
        .orderBy('createdAt', descending: true)
        .get();
    return result.docs
        .map(
          (doc) => ExamSubjectSetupModel.fromMap({...doc.data(), 'id': doc.id}),
        )
        .toList(growable: false);
  }

  @override
  Future<List<ExamSubjectSetupModel>> getSetupsForExam(String examId) async {
    final result = await _collection.where('examId', isEqualTo: examId).get();
    final setups = result.docs
        .map(
          (doc) => ExamSubjectSetupModel.fromMap({...doc.data(), 'id': doc.id}),
        )
        .toList(growable: false);
    setups.sort(
      (first, second) => first.subjectName.compareTo(second.subjectName),
    );
    return setups;
  }

  @override
  Future<void> createSetups(List<ExamSubjectSetupModel> setups) async {
    if (setups.isEmpty) return;
    final keys = <String>{};
    for (final setup in setups) {
      if (!keys.add(setup.uniqueKey)) {
        throw StateError('Duplicate subject setup selected.');
      }
      final existing = await _collection
          .where('uniqueKey', isEqualTo: setup.uniqueKey)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw StateError('A setup already exists for ${setup.subjectName}.');
      }
    }
    final batch = _service.instance.batch();
    for (final setup in setups) {
      batch.set(_collection.doc(_id(setup.id)), setup.toMap());
    }
    await batch.commit();
  }

  @override
  Future<void> updateSetup(ExamSubjectSetupModel setup) async {
    final existing = await _collection
        .where('uniqueKey', isEqualTo: setup.uniqueKey)
        .limit(1)
        .get();
    if (existing.docs.any((doc) => doc.id != setup.id)) {
      throw StateError('A setup already exists for ${setup.subjectName}.');
    }
    await _collection.doc(_id(setup.id)).update(setup.toMap());
  }

  @override
  Future<void> deleteSetup(String id) => _collection.doc(_id(id)).delete();
  @override
  Future<void> synchronizeExamSetups({
    required String examId,
    required List<ExamSubjectSetupModel> selectedSetups,
  }) async {
    final normalizedExamId = examId.trim();
    if (normalizedExamId.isEmpty) {
      throw ArgumentError.value(examId, 'examId', 'Exam ID cannot be empty.');
    }
    final selectedByKey = <String, ExamSubjectSetupModel>{};
    for (final setup in selectedSetups) {
      if (setup.examId != normalizedExamId) {
        throw StateError(
          'Every subject setup must belong to the selected exam.',
        );
      }
      if (selectedByKey.containsKey(setup.uniqueKey)) {
        throw StateError('Duplicate subject setup selected.');
      }
      selectedByKey[setup.uniqueKey] = setup;
    }
    final snapshot = await _collection
        .where('examId', isEqualTo: normalizedExamId)
        .get();
    final existingByKey =
        <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final document in snapshot.docs) {
      final existing = ExamSubjectSetupModel.fromMap({
        ...document.data(),
        'id': document.id,
      });
      existingByKey[existing.uniqueKey] = document;
    }
    final batch = _service.instance.batch();
    final retainedDocumentIds = <String>{};
    for (final entry in selectedByKey.entries) {
      final setup = entry.value;
      final existing =
          existingByKey[entry.key] ??
          snapshot.docs
              .where((document) => document.id == setup.id)
              .firstOrNull;
      final model = existing == null
          ? setup
          : ExamSubjectSetupModel.fromEntity(
              setup.copyWith(
                id: existing.id,
                createdAt: ExamSubjectSetupModel.fromMap({
                  ...existing.data(),
                  'id': existing.id,
                }).createdAt,
              ),
            );
      if (existing != null) retainedDocumentIds.add(existing.id);
      batch.set(_collection.doc(_id(model.id)), model.toMap());
    }
    for (final entry in existingByKey.entries) {
      if (selectedByKey.containsKey(entry.key) ||
          retainedDocumentIds.contains(entry.value.id)) {
        continue;
      }
      batch.update(entry.value.reference, {
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
    await batch.commit();
  }

  @override
  String generateId() => _collection.doc().id;
  String _id(String value) {
    final id = value.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(value, 'id', 'Setup ID cannot be empty.');
    }
    return id;
  }
}
