import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/subject_component_entity.dart';

class SubjectComponentModel extends SubjectComponentEntity {
  const SubjectComponentModel({required super.id,required super.parentSubjectId,required super.parentSubjectName,required super.componentName,required super.displayOrder,required super.isActive,required super.createdAt,required super.updatedAt});
  factory SubjectComponentModel.fromEntity(SubjectComponentEntity value)=>SubjectComponentModel(id:value.id,parentSubjectId:value.parentSubjectId,parentSubjectName:value.parentSubjectName,componentName:value.componentName,displayOrder:value.displayOrder,isActive:value.isActive,createdAt:value.createdAt,updatedAt:value.updatedAt);
  factory SubjectComponentModel.fromFirestore(DocumentSnapshot<Map<String,dynamic>> document){final map=document.data()??const <String,dynamic>{};return SubjectComponentModel(id:document.id,parentSubjectId:map['parentSubjectId'] as String? ?? '',parentSubjectName:map['parentSubjectName'] as String? ?? '',componentName:map['componentName'] as String? ?? '',displayOrder:(map['displayOrder'] as num?)?.toInt()??0,isActive:map['isActive'] as bool? ?? true,createdAt:_date(map['createdAt']),updatedAt:_date(map['updatedAt']));}
  Map<String,dynamic> toFirestore()=>{'parentSubjectId':parentSubjectId,'parentSubjectName':parentSubjectName,'componentName':componentName,'displayOrder':displayOrder,'isActive':isActive,'createdAt':Timestamp.fromDate(createdAt),'updatedAt':Timestamp.fromDate(updatedAt)};
  @override
  SubjectComponentModel copyWith({String? id,String? parentSubjectId,String? parentSubjectName,String? componentName,int? displayOrder,bool? isActive,DateTime? createdAt,DateTime? updatedAt})=>SubjectComponentModel(id:id??this.id,parentSubjectId:parentSubjectId??this.parentSubjectId,parentSubjectName:parentSubjectName??this.parentSubjectName,componentName:componentName??this.componentName,displayOrder:displayOrder??this.displayOrder,isActive:isActive??this.isActive,createdAt:createdAt??this.createdAt,updatedAt:updatedAt??this.updatedAt);
  static DateTime _date(dynamic value){if(value is Timestamp)return value.toDate();if(value is DateTime)return value;if(value is String)return DateTime.tryParse(value)??DateTime.fromMillisecondsSinceEpoch(0);return DateTime.fromMillisecondsSinceEpoch(0);}
}
