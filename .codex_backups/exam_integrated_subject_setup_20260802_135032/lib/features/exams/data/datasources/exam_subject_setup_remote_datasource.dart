import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../models/exam_subject_setup_model.dart';

abstract class ExamSubjectSetupRemoteDataSource { Future<List<ExamSubjectSetupModel>> getSetups(); Future<List<ExamSubjectSetupModel>> getSetupsForExam(String examId); Future<void> createSetups(List<ExamSubjectSetupModel> setups); Future<void> updateSetup(ExamSubjectSetupModel setup); Future<void> deleteSetup(String id); String generateId(); }
class ExamSubjectSetupRemoteDataSourceImpl implements ExamSubjectSetupRemoteDataSource {
  ExamSubjectSetupRemoteDataSourceImpl({required FirebaseFirestoreService firestoreService}):_service=firestoreService;
  final FirebaseFirestoreService _service;
  CollectionReference<Map<String,dynamic>> get _collection => _service.collection(FirestorePaths.examSubjectSetups);
  @override Future<List<ExamSubjectSetupModel>> getSetups() async { final result=await _collection.orderBy('createdAt',descending:true).get(); return result.docs.map((doc)=>ExamSubjectSetupModel.fromMap({...doc.data(),'id':doc.id})).toList(growable:false); }
  @override Future<List<ExamSubjectSetupModel>> getSetupsForExam(String examId) async { final result=await _collection.where('examId',isEqualTo:examId).get(); final setups=result.docs.map((doc)=>ExamSubjectSetupModel.fromMap({...doc.data(),'id':doc.id})).toList(growable:false); setups.sort((first,second)=>first.subjectName.compareTo(second.subjectName)); return setups; }
  @override Future<void> createSetups(List<ExamSubjectSetupModel> setups) async { if(setups.isEmpty)return; final keys=<String>{}; for(final setup in setups){ if(!keys.add(setup.uniqueKey)) throw StateError('Duplicate subject setup selected.'); final existing=await _collection.where('uniqueKey',isEqualTo:setup.uniqueKey).limit(1).get(); if(existing.docs.isNotEmpty) throw StateError('A setup already exists for ${setup.subjectName}.'); } final batch=_service.instance.batch(); for(final setup in setups){batch.set(_collection.doc(_id(setup.id)),setup.toMap());} await batch.commit(); }
  @override Future<void> updateSetup(ExamSubjectSetupModel setup) async { final existing=await _collection.where('uniqueKey',isEqualTo:setup.uniqueKey).limit(1).get(); if(existing.docs.any((doc)=>doc.id!=setup.id)) throw StateError('A setup already exists for ${setup.subjectName}.'); await _collection.doc(_id(setup.id)).update(setup.toMap()); }
  @override Future<void> deleteSetup(String id)=>_collection.doc(_id(id)).delete();
  @override String generateId()=>_collection.doc().id;
  String _id(String value){final id=value.trim();if(id.isEmpty)throw ArgumentError.value(value,'id','Setup ID cannot be empty.');return id;}
}
