import '../entities/subject_component_entity.dart';

abstract class SubjectComponentRepository {
  Future<List<SubjectComponentEntity>> getComponents();
  Future<List<SubjectComponentEntity>> getComponentsForSubject(String parentSubjectId,{bool activeOnly=false});
  Future<void> saveComponent(SubjectComponentEntity component);
  Future<void> deleteComponent(String id);
  Future<void> saveOrder(List<SubjectComponentEntity> components);
  String generateId();
}
