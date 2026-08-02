[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = (Get-Location).Path
if (-not (Test-Path -LiteralPath (Join-Path $root 'pubspec.yaml'))) {
  throw 'Run this installer from the Almustafa Connect ERP project root.'
}

$modified = @(
  'lib/core/constants/firestore_paths.dart',
  'lib/core/di/service_locator.dart',
  'lib/features/academic_structure/domain/entities/academic_subject_entity.dart',
  'lib/features/academic_structure/data/models/academic_subject_model.dart',
  'lib/features/academic_structure/presentation/pages/class_subjects_page.dart',
  'lib/features/exams/presentation/bloc/exam_marks_bloc.dart',
  'lib/features/exams/domain/usecases/generate_exam_results.dart',
  'lib/features/results/presentation/pages/individual_report_card_page.dart'
)
foreach ($file in $modified) {
  if (-not (Test-Path -LiteralPath (Join-Path $root $file))) {
    throw "Required file is missing: $file"
  }
}

$newFiles = [ordered]@{
'lib/features/academic_structure/domain/entities/subject_component_entity.dart' = @'
import 'package:equatable/equatable.dart';

class SubjectComponentEntity extends Equatable {
  const SubjectComponentEntity({required this.id,required this.parentSubjectId,required this.parentSubjectName,required this.componentName,required this.displayOrder,required this.isActive,required this.createdAt,required this.updatedAt});
  final String id,parentSubjectId,parentSubjectName,componentName;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt,updatedAt;
  SubjectComponentEntity copyWith({String? id,String? parentSubjectId,String? parentSubjectName,String? componentName,int? displayOrder,bool? isActive,DateTime? createdAt,DateTime? updatedAt})=>SubjectComponentEntity(id:id??this.id,parentSubjectId:parentSubjectId??this.parentSubjectId,parentSubjectName:parentSubjectName??this.parentSubjectName,componentName:componentName??this.componentName,displayOrder:displayOrder??this.displayOrder,isActive:isActive??this.isActive,createdAt:createdAt??this.createdAt,updatedAt:updatedAt??this.updatedAt);
  @override List<Object> get props=>[id,parentSubjectId,parentSubjectName,componentName,displayOrder,isActive,createdAt,updatedAt];
}
'@
'lib/features/academic_structure/domain/repositories/subject_component_repository.dart' = @'
import '../entities/subject_component_entity.dart';

abstract class SubjectComponentRepository {
  Future<List<SubjectComponentEntity>> getComponents();
  Future<List<SubjectComponentEntity>> getComponentsForSubject(String parentSubjectId,{bool activeOnly=false});
  Future<void> saveComponent(SubjectComponentEntity component);
  Future<void> deleteComponent(String id);
  Future<void> saveOrder(List<SubjectComponentEntity> components);
  String generateId();
}
'@
'lib/features/academic_structure/data/models/subject_component_model.dart' = @'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/subject_component_entity.dart';

class SubjectComponentModel extends SubjectComponentEntity {
  const SubjectComponentModel({required super.id,required super.parentSubjectId,required super.parentSubjectName,required super.componentName,required super.displayOrder,required super.isActive,required super.createdAt,required super.updatedAt});
  factory SubjectComponentModel.fromEntity(SubjectComponentEntity value)=>SubjectComponentModel(id:value.id,parentSubjectId:value.parentSubjectId,parentSubjectName:value.parentSubjectName,componentName:value.componentName,displayOrder:value.displayOrder,isActive:value.isActive,createdAt:value.createdAt,updatedAt:value.updatedAt);
  factory SubjectComponentModel.fromFirestore(DocumentSnapshot<Map<String,dynamic>> document){final map=document.data()??const <String,dynamic>{};return SubjectComponentModel(id:document.id,parentSubjectId:map['parentSubjectId'] as String? ?? '',parentSubjectName:map['parentSubjectName'] as String? ?? '',componentName:map['componentName'] as String? ?? '',displayOrder:(map['displayOrder'] as num?)?.toInt()??0,isActive:map['isActive'] as bool? ?? true,createdAt:_date(map['createdAt']),updatedAt:_date(map['updatedAt']));}
  Map<String,dynamic> toFirestore()=>{'parentSubjectId':parentSubjectId,'parentSubjectName':parentSubjectName,'componentName':componentName,'displayOrder':displayOrder,'isActive':isActive,'createdAt':Timestamp.fromDate(createdAt),'updatedAt':Timestamp.fromDate(updatedAt)};
  SubjectComponentModel copyWith({String? id,String? parentSubjectId,String? parentSubjectName,String? componentName,int? displayOrder,bool? isActive,DateTime? createdAt,DateTime? updatedAt})=>SubjectComponentModel(id:id??this.id,parentSubjectId:parentSubjectId??this.parentSubjectId,parentSubjectName:parentSubjectName??this.parentSubjectName,componentName:componentName??this.componentName,displayOrder:displayOrder??this.displayOrder,isActive:isActive??this.isActive,createdAt:createdAt??this.createdAt,updatedAt:updatedAt??this.updatedAt);
  static DateTime _date(dynamic value){if(value is Timestamp)return value.toDate();if(value is DateTime)return value;if(value is String)return DateTime.tryParse(value)??DateTime.fromMillisecondsSinceEpoch(0);return DateTime.fromMillisecondsSinceEpoch(0);}
}
'@
'lib/features/academic_structure/data/repositories/subject_component_repository_impl.dart' = @'
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
'@
'lib/features/academic_structure/domain/services/subject_component_exam_service.dart' = @'
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
'@
'lib/features/academic_structure/presentation/bloc/subject_component_bloc.dart' = @'
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/academic_subject_entity.dart';
import '../../domain/entities/subject_component_entity.dart';
import '../../domain/repositories/academic_structure_repository.dart';
import '../../domain/repositories/subject_component_repository.dart';

sealed class SubjectComponentEvent extends Equatable{const SubjectComponentEvent();@override List<Object?> get props=>[];}
class LoadSubjectComponents extends SubjectComponentEvent{const LoadSubjectComponents(this.subject);final AcademicSubjectEntity subject;@override List<Object?> get props=>[subject];}
class SaveSubjectComponent extends SubjectComponentEvent{const SaveSubjectComponent({this.existing,required this.name,required this.isActive});final SubjectComponentEntity? existing;final String name;final bool isActive;@override List<Object?> get props=>[existing,name,isActive];}
class DeleteSubjectComponent extends SubjectComponentEvent{const DeleteSubjectComponent(this.component);final SubjectComponentEntity component;@override List<Object?> get props=>[component];}
class ReorderSubjectComponents extends SubjectComponentEvent{const ReorderSubjectComponents(this.oldIndex,this.newIndex);final int oldIndex,newIndex;@override List<Object?> get props=>[oldIndex,newIndex];}
class SaveSubjectComponentSettings extends SubjectComponentEvent{const SaveSubjectComponentSettings(this.subject);final AcademicSubjectEntity subject;@override List<Object?> get props=>[subject];}
sealed class SubjectComponentState extends Equatable{const SubjectComponentState();@override List<Object?> get props=>[];}
class SubjectComponentLoading extends SubjectComponentState{const SubjectComponentLoading();}
class SubjectComponentLoaded extends SubjectComponentState{const SubjectComponentLoaded({required this.subject,required this.components,this.busy=false,this.message});final AcademicSubjectEntity subject;final List<SubjectComponentEntity> components;final bool busy;final String? message;SubjectComponentLoaded copyWith({AcademicSubjectEntity? subject,List<SubjectComponentEntity>? components,bool? busy,String? message})=>SubjectComponentLoaded(subject:subject??this.subject,components:components??this.components,busy:busy??this.busy,message:message);@override List<Object?> get props=>[subject,components,busy,message];}
class SubjectComponentFailure extends SubjectComponentState{const SubjectComponentFailure(this.message);final String message;@override List<Object?> get props=>[message];}
class SubjectComponentBloc extends Bloc<SubjectComponentEvent,SubjectComponentState>{SubjectComponentBloc(this._components,this._academic):super(const SubjectComponentLoading()){on<LoadSubjectComponents>(_load);on<SaveSubjectComponent>(_save);on<DeleteSubjectComponent>(_delete);on<ReorderSubjectComponents>(_reorder);on<SaveSubjectComponentSettings>(_settings);}final SubjectComponentRepository _components;final AcademicStructureRepository _academic;Future<void> _load(LoadSubjectComponents event,Emitter<SubjectComponentState> emit)async{emit(const SubjectComponentLoading());try{emit(SubjectComponentLoaded(subject:event.subject,components:await _components.getComponentsForSubject(event.subject.id)));}catch(error){emit(SubjectComponentFailure(_message(error)));}}Future<void> _save(SaveSubjectComponent event,Emitter<SubjectComponentState> emit)async{final current=state;if(current is! SubjectComponentLoaded)return;final name=event.name.trim();if(name.isEmpty){emit(current.copyWith(message:'Component name is required.'));return;}if(current.components.any((item)=>item.id!=event.existing?.id&&item.componentName.toLowerCase()==name.toLowerCase())){emit(current.copyWith(message:'A component with this name already exists.'));return;}emit(current.copyWith(busy:true));try{final now=DateTime.now();await _components.saveComponent(SubjectComponentEntity(id:event.existing?.id??_components.generateId(),parentSubjectId:current.subject.id,parentSubjectName:current.subject.name,componentName:name,displayOrder:event.existing?.displayOrder??current.components.length,isActive:event.isActive,createdAt:event.existing?.createdAt??now,updatedAt:now));await _reload(current.subject,emit,'Component saved.');}catch(error){emit(current.copyWith(busy:false,message:_message(error)));}}Future<void> _delete(DeleteSubjectComponent event,Emitter<SubjectComponentState> emit)async{final current=state;if(current is! SubjectComponentLoaded)return;emit(current.copyWith(busy:true));try{await _components.deleteComponent(event.component.id);await _reload(current.subject,emit,'Component deleted.');}catch(error){emit(current.copyWith(busy:false,message:_message(error)));}}Future<void> _reorder(ReorderSubjectComponents event,Emitter<SubjectComponentState> emit)async{final current=state;if(current is! SubjectComponentLoaded)return;final items=[...current.components];var target=event.newIndex;if(target>event.oldIndex)target--;final moved=items.removeAt(event.oldIndex);items.insert(target,moved);final now=DateTime.now();final ordered=[for(var i=0;i<items.length;i++)items[i].copyWith(displayOrder:i,updatedAt:now)];emit(current.copyWith(components:ordered,busy:true));try{await _components.saveOrder(ordered);emit(current.copyWith(components:ordered,busy:false,message:'Component order saved.'));}catch(error){emit(current.copyWith(busy:false,message:_message(error)));}}Future<void> _settings(SaveSubjectComponentSettings event,Emitter<SubjectComponentState> emit)async{final current=state;if(current is! SubjectComponentLoaded)return;emit(current.copyWith(busy:true));try{await _academic.saveSubject(event.subject);emit(current.copyWith(subject:event.subject,busy:false,message:'Subject settings saved.'));}catch(error){emit(current.copyWith(busy:false,message:_message(error)));}}Future<void> _reload(AcademicSubjectEntity subject,Emitter<SubjectComponentState> emit,String message)async=>emit(SubjectComponentLoaded(subject:subject,components:await _components.getComponentsForSubject(subject.id),message:message));String _message(Object error)=>error.toString().replaceFirst('StateError: ','');}
'@
'lib/features/academic_structure/presentation/pages/subject_components_page.dart' = @'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../domain/entities/academic_subject_entity.dart';
import '../../domain/entities/subject_component_entity.dart';
import '../bloc/subject_component_bloc.dart';

class SubjectComponentsPage extends StatelessWidget{const SubjectComponentsPage({super.key,required this.subject});final AcademicSubjectEntity subject;@override Widget build(BuildContext context)=>BlocProvider(create:(_)=>sl<SubjectComponentBloc>()..add(LoadSubjectComponents(subject)),child:const _View());}
class _View extends StatelessWidget{const _View();Future<void> _edit(BuildContext context,[SubjectComponentEntity? item])async{final controller=TextEditingController(text:item?.componentName??'');var active=item?.isActive??true;final result=await showDialog<(String,bool)>(context:context,builder:(dialog)=>StatefulBuilder(builder:(context,setState)=>AlertDialog(title:Text(item==null?'Add Component':'Edit Component'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:controller,autofocus:true,decoration:const InputDecoration(labelText:'Component name',border:OutlineInputBorder())),SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Enabled'),value:active,onChanged:(value)=>setState(()=>active=value))]),actions:[TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(dialog,(controller.text,active)),child:const Text('Save'))])));controller.dispose();if(result!=null&&context.mounted)context.read<SubjectComponentBloc>().add(SaveSubjectComponent(existing:item,name:result.$1,isActive:result.$2));}Future<void> _delete(BuildContext context,SubjectComponentEntity item)async{final yes=await showDialog<bool>(context:context,builder:(dialog)=>AlertDialog(title:const Text('Delete Component'),content:Text('Delete ${item.componentName}?'),actions:[TextButton(onPressed:()=>Navigator.pop(dialog,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(dialog,true),child:const Text('Delete'))]))??false;if(yes&&context.mounted)context.read<SubjectComponentBloc>().add(DeleteSubjectComponent(item));}@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Subject Components'),actions:const [DashboardNavigationButton()]),floatingActionButton:FloatingActionButton.extended(onPressed:()=>_edit(context),icon:const Icon(Icons.add),label:const Text('Add Component')),body:BlocConsumer<SubjectComponentBloc,SubjectComponentState>(listener:(context,state){if(state is SubjectComponentLoaded&&state.message!=null)ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content:Text(state.message!)));},builder:(context,state){if(state is SubjectComponentLoading)return const Center(child:CircularProgressIndicator());if(state is SubjectComponentFailure)return Center(child:Text(state.message));final data=state as SubjectComponentLoaded;return ListView(padding:const EdgeInsets.fromLTRB(20,20,20,90),children:[Card(child:ListTile(leading:const Icon(Icons.menu_book_outlined),title:const Text('Parent Subject'),subtitle:Text(data.subject.name,style:Theme.of(context).textTheme.titleLarge))),const SizedBox(height:16),Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Subject Settings',style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:8),_setting(context,data,'Timetable',data.subject.useComponentsInTimetable,(v)=>data.subject.copyWith(useComponentsInTimetable:v)),_setting(context,data,'Attendance',data.subject.useComponentsInAttendance,(v)=>data.subject.copyWith(useComponentsInAttendance:v)),_setting(context,data,'Homework',data.subject.useComponentsInHomework,(v)=>data.subject.copyWith(useComponentsInHomework:v)),_setting(context,data,'Examination',data.subject.useComponentsInExamination,(v)=>data.subject.copyWith(useComponentsInExamination:v)),_setting(context,data,'Report Card',data.subject.useComponentsInReportCard,(v)=>data.subject.copyWith(useComponentsInReportCard:v))]))),const SizedBox(height:16),Text('Components',style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:8),if(data.components.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(24),child:Center(child:Text('No components. This subject behaves exactly as before.'))))else ReorderableListView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:data.components.length,onReorder:data.busy?(_,_){}:(oldIndex,newIndex)=>context.read<SubjectComponentBloc>().add(ReorderSubjectComponents(oldIndex,newIndex)),itemBuilder:(context,index){final item=data.components[index];return Card(key:ValueKey(item.id),child:ListTile(leading:const Icon(Icons.drag_handle),title:Text(item.componentName),subtitle:Text(item.isActive?'Enabled':'Disabled'),trailing:Wrap(children:[IconButton(tooltip:item.isActive?'Disable':'Enable',onPressed:data.busy?null:()=>context.read<SubjectComponentBloc>().add(SaveSubjectComponent(existing:item,name:item.componentName,isActive:!item.isActive)),icon:Icon(item.isActive?Icons.toggle_on:Icons.toggle_off)),IconButton(tooltip:'Edit',onPressed:data.busy?null:()=>_edit(context,item),icon:const Icon(Icons.edit_outlined)),IconButton(tooltip:'Delete',onPressed:data.busy?null:()=>_delete(context,item),icon:const Icon(Icons.delete_outline))])));})]);}}));Widget _setting(BuildContext context,SubjectComponentLoaded data,String title,bool value,AcademicSubjectEntity Function(bool) change)=>SwitchListTile(title:Text(title),value:value,onChanged:data.busy?null:(enabled)=>context.read<SubjectComponentBloc>().add(SaveSubjectComponentSettings(change(enabled).copyWith(updatedAt:DateTime.now()))));}
'@
}

function Replace-Once([string]$content,[string]$anchor,[string]$replacement,[string]$file){$count=([regex]::Matches($content,[regex]::Escape($anchor))).Count;if($count -ne 1){throw "Anchor error in ${file}: expected 1 occurrence, found $count.`n$anchor"};return $content.Replace($anchor,$replacement)}
function Insert-After([string]$content,[string]$anchor,[string]$addition,[string]$file){return Replace-Once $content $anchor "$anchor`r`n$addition" $file}
function Insert-Before([string]$content,[string]$anchor,[string]$addition,[string]$file){return Replace-Once $content $anchor "$addition`r`n$anchor" $file}

$updates=[ordered]@{}
foreach($file in $modified){$updates[$file]=Get-Content -LiteralPath (Join-Path $root $file) -Raw}

$f='lib/core/constants/firestore_paths.dart';if(-not $updates[$f].Contains('subjectComponents')){$updates[$f]=Insert-After $updates[$f] "  static const String academicSubjects = 'academic_subjects';" "  static const String subjectComponents = 'subject_components';" $f}

$f='lib/features/academic_structure/domain/entities/academic_subject_entity.dart'
if(-not $updates[$f].Contains('useComponentsInExamination')){
$updates[$f]=Insert-After $updates[$f] '    required this.updatedAt,' "    this.useComponentsInTimetable = false,`r`n    this.useComponentsInAttendance = false,`r`n    this.useComponentsInHomework = false,`r`n    this.useComponentsInExamination = true,`r`n    this.useComponentsInReportCard = true," $f
$updates[$f]=Insert-After $updates[$f] '  final DateTime updatedAt;' "  final bool useComponentsInTimetable;`r`n  final bool useComponentsInAttendance;`r`n  final bool useComponentsInHomework;`r`n  final bool useComponentsInExamination;`r`n  final bool useComponentsInReportCard;" $f
$updates[$f]=Insert-After $updates[$f] '    DateTime? updatedAt,' "    bool? useComponentsInTimetable,`r`n    bool? useComponentsInAttendance,`r`n    bool? useComponentsInHomework,`r`n    bool? useComponentsInExamination,`r`n    bool? useComponentsInReportCard," $f
$updates[$f]=Insert-After $updates[$f] '      updatedAt: updatedAt ?? this.updatedAt,' "      useComponentsInTimetable: useComponentsInTimetable ?? this.useComponentsInTimetable,`r`n      useComponentsInAttendance: useComponentsInAttendance ?? this.useComponentsInAttendance,`r`n      useComponentsInHomework: useComponentsInHomework ?? this.useComponentsInHomework,`r`n      useComponentsInExamination: useComponentsInExamination ?? this.useComponentsInExamination,`r`n      useComponentsInReportCard: useComponentsInReportCard ?? this.useComponentsInReportCard," $f
$updates[$f]=Insert-After $updates[$f] '        updatedAt,' "        useComponentsInTimetable,`r`n        useComponentsInAttendance,`r`n        useComponentsInHomework,`r`n        useComponentsInExamination,`r`n        useComponentsInReportCard," $f}

$f='lib/features/academic_structure/data/models/academic_subject_model.dart'
if(-not $updates[$f].Contains('useComponentsInExamination')){
$updates[$f]=Insert-After $updates[$f] '    required super.updatedAt,' "    super.useComponentsInTimetable = false,`r`n    super.useComponentsInAttendance = false,`r`n    super.useComponentsInHomework = false,`r`n    super.useComponentsInExamination = true,`r`n    super.useComponentsInReportCard = true," $f
$updates[$f]=Insert-After $updates[$f] '      updatedAt: value.updatedAt,' "      useComponentsInTimetable: value.useComponentsInTimetable,`r`n      useComponentsInAttendance: value.useComponentsInAttendance,`r`n      useComponentsInHomework: value.useComponentsInHomework,`r`n      useComponentsInExamination: value.useComponentsInExamination,`r`n      useComponentsInReportCard: value.useComponentsInReportCard," $f
$updates[$f]=Insert-After $updates[$f] "      updatedAt: _date(map['updatedAt']) ?? now," "      useComponentsInTimetable: map['useComponentsInTimetable'] as bool? ?? false,`r`n      useComponentsInAttendance: map['useComponentsInAttendance'] as bool? ?? false,`r`n      useComponentsInHomework: map['useComponentsInHomework'] as bool? ?? false,`r`n      useComponentsInExamination: map['useComponentsInExamination'] as bool? ?? true,`r`n      useComponentsInReportCard: map['useComponentsInReportCard'] as bool? ?? true," $f
$updates[$f]=Insert-After $updates[$f] "      'updatedAt': updatedAt.toIso8601String()," "      'useComponentsInTimetable': useComponentsInTimetable,`r`n      'useComponentsInAttendance': useComponentsInAttendance,`r`n      'useComponentsInHomework': useComponentsInHomework,`r`n      'useComponentsInExamination': useComponentsInExamination,`r`n      'useComponentsInReportCard': useComponentsInReportCard," $f}

$f='lib/features/academic_structure/presentation/pages/class_subjects_page.dart'
if(-not $updates[$f].Contains('SubjectComponentsPage')){$updates[$f]=Insert-After $updates[$f] "import '../../domain/repositories/academic_structure_repository.dart';" "import 'subject_components_page.dart';" $f;$anchor="                                    IconButton(`r`n                                      tooltip: 'Edit subject',";if(-not $updates[$f].Contains($anchor)){$anchor="                                    IconButton(`n                                      tooltip: 'Edit subject',"};$addition="                                    IconButton(`r`n                                      tooltip: 'Manage Components',`r`n                                      onPressed: () => Navigator.of(context).push(`r`n                                        MaterialPageRoute<void>(`r`n                                          builder: (_) => SubjectComponentsPage(subject: subject),`r`n                                        ),`r`n                                      ),`r`n                                      icon: const Icon(Icons.account_tree_outlined),`r`n                                    ),";$updates[$f]=Insert-Before $updates[$f] $anchor $addition $f}

$f='lib/features/exams/presentation/bloc/exam_marks_bloc.dart'
if(-not $updates[$f].Contains('componentService')){$updates[$f]=Insert-After $updates[$f] "import '../../../students/domain/usecases/get_students_by_class_and_section.dart';" "import '../../../academic_structure/domain/services/subject_component_exam_service.dart';" $f;$updates[$f]=Insert-After $updates[$f] '    required this._deleteExamMark,' '    required this.componentService,' $f;$updates[$f]=Insert-After $updates[$f] '  final DeleteExamMark _deleteExamMark;' '  final SubjectComponentExamService componentService;' $f;$updates[$f]=$updates[$f].Replace('final setups = await _getSubjectSetupsForExam(current.selectedExamId!);','final setups = await componentService.expandSetups(await _getSubjectSetupsForExam(current.selectedExamId!));').Replace('final setups = await _getSubjectSetupsForExam(event.examId);','final setups = await componentService.expandSetups(await _getSubjectSetupsForExam(event.examId));')}

$f='lib/features/exams/domain/usecases/generate_exam_results.dart'
if(-not $updates[$f].Contains('componentService')){$updates[$f]=Insert-After $updates[$f] "import '../../../students/domain/repositories/student_repository.dart';" "import '../../../academic_structure/domain/services/subject_component_exam_service.dart';" $f;$updates[$f]=Insert-After $updates[$f] '    required this._resultRepository,' '    required this.componentService,' $f;$updates[$f]=Insert-After $updates[$f] '  final ExamResultRepository _resultRepository;' '  final SubjectComponentExamService componentService;' $f;$old="    final setups = (responses[1] as List<ExamSubjectSetupEntity>)`r`n        .where((setup) => setup.isActive)`r`n        .toList(growable: false);";if(-not $updates[$f].Contains($old)){$old=$old.Replace("`r`n","`n")};$new="    final setups = await componentService.expandSetups(`r`n      (responses[1] as List<ExamSubjectSetupEntity>)`r`n          .where((setup) => setup.isActive)`r`n          .toList(growable: false),`r`n    );";$updates[$f]=Replace-Once $updates[$f] $old $new $f}

$f='lib/features/results/presentation/pages/individual_report_card_page.dart'
if(-not $updates[$f].Contains('_componentRows')){$updates[$f]=Insert-After $updates[$f] "import '../../../exams/domain/entities/exam_result_entity.dart';" "import '../../../academic_structure/domain/services/subject_component_exam_service.dart';" $f;$old="            rows: subjects`r`n                .map(";if(-not $updates[$f].Contains($old)){$old=$old.Replace("`r`n","`n")};$updates[$f]=Replace-Once $updates[$f] $old "            rows: _componentRows(subjects).map(" $f;$helper=@'

List<SubjectResultEntity> _componentRows(List<SubjectResultEntity> subjects) {
  final output=<SubjectResultEntity>[];
  final grouped=<String,List<SubjectResultEntity>>{};
  for(final subject in subjects){final parent=SubjectComponentExamService.parentId(subject.subjectId);if(parent==null){output.add(subject);}else{(grouped[parent]??=[]).add(subject);}}
  for(final entry in grouped.entries){final items=entry.value;if(SubjectComponentExamService.useInReportCard(items.first.subjectId))output.addAll(items);final total=items.fold<double>(0,(sum,item)=>sum+item.totalMarks);final obtained=items.fold<double>(0,(sum,item)=>sum+item.obtainedMarks);final parentName=SubjectComponentExamService.parentName(items.first.subjectId)??'Subject';final percentage=total==0?0.0:obtained*100/total;output.add(SubjectResultEntity(subjectId:'${entry.key}::total',subjectName:'$parentName Total (${percentage.toStringAsFixed(1)}% - ${_componentGrade(percentage)})',totalMarks:total,obtainedMarks:obtained,isAbsent:items.every((item)=>item.isAbsent),isPassed:items.every((item)=>item.isPassed),remarks:''));}
  return output;
}
String _componentGrade(double value){if(value>=80)return'A+';if(value>=70)return'A';if(value>=60)return'B';if(value>=50)return'C';if(value>=40)return'D';return'F';}
'@;$updates[$f]=Insert-Before $updates[$f] 'String _value(String? value) =>' $helper.Trim() $f}

$f='lib/core/di/service_locator.dart'
if(-not $updates[$f].Contains('SubjectComponentRepositoryImpl')){$updates[$f]=Insert-After $updates[$f] "import '../../features/academic_structure/data/repositories/academic_structure_repository_impl.dart';" "import '../../features/academic_structure/data/repositories/subject_component_repository_impl.dart';`r`nimport '../../features/academic_structure/domain/repositories/subject_component_repository.dart';`r`nimport '../../features/academic_structure/domain/services/subject_component_exam_service.dart';`r`nimport '../../features/academic_structure/presentation/bloc/subject_component_bloc.dart';" $f;$registration="  sl.registerLazySingleton<SubjectComponentRepository>(`r`n    () => SubjectComponentRepositoryImpl(sl<FirebaseFirestoreService>()),`r`n  );`r`n  sl.registerLazySingleton<SubjectComponentExamService>(`r`n    () => SubjectComponentExamService(`r`n      sl<AcademicStructureRepository>(),`r`n      sl<SubjectComponentRepository>(),`r`n    ),`r`n  );`r`n  sl.registerFactory<SubjectComponentBloc>(`r`n    () => SubjectComponentBloc(`r`n      sl<SubjectComponentRepository>(),`r`n      sl<AcademicStructureRepository>(),`r`n    ),`r`n  );";$updates[$f]=Insert-Before $updates[$f] '  sl.registerLazySingleton<ValidateExamDateSheet>(ValidateExamDateSheet.new);' $registration $f;$updates[$f]=Insert-After $updates[$f] '      resultRepository: sl<ExamResultRepository>(),' '      componentService: sl<SubjectComponentExamService>(),' $f;$updates[$f]=Insert-After $updates[$f] '      deleteExamMark: sl<DeleteExamMark>(),' '      componentService: sl<SubjectComponentExamService>(),' $f}

$dart=Get-Command dart -ErrorAction SilentlyContinue;if($null -eq $dart){throw 'Dart is not available on PATH. No files were changed.'};$flutter=Get-Command flutter -ErrorAction SilentlyContinue;if($null -eq $flutter){throw 'Flutter is not available on PATH. No files were changed.'}
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss';$backup=Join-Path $root ".subject_components_backups\$stamp";New-Item -ItemType Directory -Path $backup -Force|Out-Null
foreach($file in @($modified)+@($newFiles.Keys)){if(Test-Path -LiteralPath (Join-Path $root $file)){ $destination=Join-Path $backup $file;New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force|Out-Null;Copy-Item -LiteralPath (Join-Path $root $file) -Destination $destination -Force}}
$utf8=New-Object System.Text.UTF8Encoding($false);foreach($entry in $updates.GetEnumerator()){[IO.File]::WriteAllText((Join-Path $root $entry.Key),$entry.Value,$utf8)};foreach($entry in $newFiles.GetEnumerator()){$path=Join-Path $root $entry.Key;New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force|Out-Null;[IO.File]::WriteAllText($path,$entry.Value.TrimStart()+"`r`n",$utf8)}
$targets=@($modified)+@($newFiles.Keys);& $dart.Source format $targets;if($LASTEXITCODE -ne 0){throw "dart format failed. Backup: $backup"};& $flutter.Source analyze;if($LASTEXITCODE -ne 0){throw "flutter analyze failed. Backup: $backup"}
Write-Host '';Write-Host 'Subject Components Management installed successfully.' -ForegroundColor Green;Write-Host "Backup: $backup";Write-Host 'Timetable, Attendance, Homework and Teacher Assignment remain parent-subject only.'
