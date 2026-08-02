import 'package:equatable/equatable.dart';

class AcademicSubjectEntity extends Equatable {
  const AcademicSubjectEntity({
    required this.id,
    required this.classId,
    this.sectionId,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String classId;
  /// Null means this is the default subject for every section of the class.
  final String? sectionId;
  final String name;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get classSubjectKey =>
      '${classId}_${sectionId ?? 'class'}_${name.trim().toLowerCase()}';

  AcademicSubjectEntity copyWith({
    String? id,
    String? classId,
    String? sectionId,
    String? name,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AcademicSubjectEntity(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        classId,
        sectionId,
        name,
        isActive,
        createdAt,
        updatedAt,
      ];
}
