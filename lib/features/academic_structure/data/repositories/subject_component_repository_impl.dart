import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/subject_component_entity.dart';
import '../../domain/repositories/subject_component_repository.dart';
import '../models/subject_component_model.dart';

class SubjectComponentRepositoryImpl implements SubjectComponentRepository {
  const SubjectComponentRepositoryImpl(this._service);
  final FirebaseFirestoreService _service;
  @override Future<List<SubjectComponentEntity>> getComponents()async{final snapshot=await _service.collection(FirestorePaths.subjectComponents).get();final values=snapshot.docs.map(SubjectComponentModel.fromFirestore).toList()..sort(_compare);return List.unmodifiable(values);}
  @override Future<List<SubjectComponentEntity>> getComponentsForSubject(String parentSubjectId,{bool activeOnly=false})async{final values=(await getComponents()).where((item)=>item.parentSubjectId==parentSubjectId&&(!activeOnly||item.isActive)).toList()..sort(_compare);return List.unmodifiable(values);}
  @override Future<void> saveComponent(SubjectComponentEntity component)=>_service.collection(FirestorePaths.subjectComponents).doc(component.id).set(SubjectComponentModel.fromEntity(component).toFirestore());
  @override Future<void> deleteComponent(String id)=>_service.collection(FirestorePaths.subjectComponents).doc(id).delete();
  @override Future<void> saveOrder(List<SubjectComponentEntity> components)async{if(components.isEmpty)return;final batch=_service.instance.batch();final collection=_service.collection(FirestorePaths.subjectComponents);for(final item in components){batch.set(collection.doc(item.id),SubjectComponentModel.fromEntity(item).toFirestore());}await batch.commit();}
  @override String generateId()=>_service.collection(FirestorePaths.subjectComponents).doc().id;
  static int _compare(SubjectComponentEntity first,SubjectComponentEntity second){final order=first.displayOrder.compareTo(second.displayOrder);return order!=0?order:first.componentName.compareTo(second.componentName);}
}
