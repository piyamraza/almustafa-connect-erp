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
