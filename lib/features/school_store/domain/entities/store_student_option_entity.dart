import 'package:equatable/equatable.dart';

class StoreStudentOptionEntity extends Equatable {
  const StoreStudentOptionEntity({
    required this.id,
    required this.admissionNo,
    required this.name,
    required this.classId,
    required this.sectionId,
  });

  final String id;
  final String admissionNo;
  final String name;
  final String classId;
  final String sectionId;

  String get displayName {
    final admission = admissionNo.trim();
    return admission.isEmpty ? name : '$name ($admission)';
  }

  @override
  List<Object?> get props => [id, admissionNo, name, classId, sectionId];
}
