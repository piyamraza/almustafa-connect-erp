import 'package:equatable/equatable.dart';

class AcademicSubjectEntity extends Equatable {
  const AcademicSubjectEntity({
    required this.id,
    required this.classId,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String classId;
  final String name;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get classSubjectKey => '${classId}_${name.trim().toLowerCase()}';

  AcademicSubjectEntity copyWith({
    String? id,
    String? classId,
    String? name,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AcademicSubjectEntity(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, classId, name, isActive, createdAt, updatedAt];
}
