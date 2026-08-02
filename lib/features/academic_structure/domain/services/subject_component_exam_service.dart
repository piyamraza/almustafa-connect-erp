import 'dart:convert';
import '../../../exams/domain/entities/exam_subject_setup_entity.dart';
import '../repositories/academic_structure_repository.dart';
import '../repositories/subject_component_repository.dart';

class SubjectComponentExamService {
  const SubjectComponentExamService(this._academicRepository,this._componentRepository);
  final AcademicStructureRepository _academicRepository;
  final SubjectComponentRepository _componentRepository;
  Future<List<ExamSubjectSetupEntity>> expandSetups(List<ExamSubjectSetupEntity> setups)async{final subjects=await _academicRepository.getSubjects();final components=await _componentRepository.getComponents();final subjectsById={for(final item in subjects)item.id:item};final output=<ExamSubjectSetupEntity>[];for(final setup in setups){final parent=subjectsById[setup.subjectId];final active=components.where((item)=>item.parentSubjectId==setup.subjectId&&item.isActive).toList()..sort((a,b)=>a.displayOrder.compareTo(b.displayOrder));if(parent==null||!parent.useComponentsInExamination||active.isEmpty){output.add(setup);continue;}final total=setup.totalMarks/active.length;final passing=setup.passingMarks/active.length;for(final component in active){final encodedParent=base64Url.encode(utf8.encode(parent.name)).replaceAll('=','');final reportFlag=parent.useComponentsInReportCard?'1':'0';output.add(setup.copyWith(id:'${setup.id}::${component.id}',subjectId:'cmp::${parent.id}::$encodedParent::$reportFlag::${component.id}',subjectName:component.componentName,totalMarks:total,passingMarks:passing));}}return List.unmodifiable(output);}
  static bool isComponentId(String value)=>value.startsWith('cmp::')&&value.split('::').length==5;
  static String? parentId(String value)=>isComponentId(value)?value.split('::')[1]:null;
  static String? parentName(String value){if(!isComponentId(value))return null;try{final raw=value.split('::')[2];return utf8.decode(base64Url.decode(base64Url.normalize(raw)));}catch(_){return null;}}
  static bool useInReportCard(String value)=>isComponentId(value)&&value.split('::')[3]=='1';
}
