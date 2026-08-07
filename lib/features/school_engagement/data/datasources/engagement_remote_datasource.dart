import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../models/engagement_history_model.dart';
import '../models/engagement_template_model.dart';

abstract class EngagementRemoteDataSource {
  Future<List<EngagementTemplateModel>> getTemplates();

  Future<void> saveTemplate(EngagementTemplateModel template);

  Future<List<EngagementHistoryModel>> getHistory();

  Future<void> saveHistory(EngagementHistoryModel history);

  String generateTemplateId();

  String generateHistoryId();
}

class EngagementRemoteDataSourceImpl implements EngagementRemoteDataSource {
  const EngagementRemoteDataSourceImpl(this._firestoreService);

  final FirebaseFirestoreService _firestoreService;

  CollectionReference<Map<String, dynamic>> get _templateCollection =>
      _firestoreService.collection(FirestorePaths.engagementTemplates);

  CollectionReference<Map<String, dynamic>> get _historyCollection =>
      _firestoreService.collection(FirestorePaths.engagementHistory);

  @override
  Future<List<EngagementTemplateModel>> getTemplates() async {
    final snapshot = await _templateCollection.get();

    return snapshot.docs
        .map(
          (doc) =>
              EngagementTemplateModel.fromMap({...doc.data(), 'id': doc.id}),
        )
        .toList();
  }

  @override
  Future<void> saveTemplate(EngagementTemplateModel template) async {
    await _templateCollection.doc(template.id).set(template.toMap());
  }

  @override
  Future<List<EngagementHistoryModel>> getHistory() async {
    final snapshot = await _historyCollection
        .orderBy('generatedAt', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) =>
              EngagementHistoryModel.fromMap({...doc.data(), 'id': doc.id}),
        )
        .toList();
  }

  @override
  Future<void> saveHistory(EngagementHistoryModel history) async {
    await _historyCollection.doc(history.id).set(history.toMap());
  }

  @override
  String generateTemplateId() {
    return _templateCollection.doc().id;
  }

  @override
  String generateHistoryId() {
    return _historyCollection.doc().id;
  }
}
