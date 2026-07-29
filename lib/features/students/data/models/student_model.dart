import '../../domain/entities/student_entity.dart';

class StudentModel extends StudentEntity {
  const StudentModel({
    required super.id,
    required super.admissionNo,
    required super.firstName,
    required super.lastName,
    required super.gender,
    required super.dateOfBirth,
    required super.classId,
    required super.sectionId,
    required super.fatherName,
    required super.motherName,
    required super.guardianPhone,
    required super.guardianEmail,
    required super.address,
    required super.profileImageUrl,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] ?? '',
      admissionNo: map['admissionNo'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      gender: map['gender'] ?? '',
      dateOfBirth: DateTime.parse(map['dateOfBirth']),
      classId: map['classId'] ?? '',
      sectionId: map['sectionId'] ?? '',
      fatherName: map['fatherName'] ?? '',
      motherName: map['motherName'] ?? '',
      guardianPhone: map['guardianPhone'] ?? '',
      guardianEmail: map['guardianEmail'] ?? '',
      address: map['address'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'admissionNo': admissionNo,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'classId': classId,
      'sectionId': sectionId,
      'fatherName': fatherName,
      'motherName': motherName,
      'guardianPhone': guardianPhone,
      'guardianEmail': guardianEmail,
      'address': address,
      'profileImageUrl': profileImageUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory StudentModel.fromEntity(StudentEntity entity) {
    return StudentModel(
      id: entity.id,
      admissionNo: entity.admissionNo,
      firstName: entity.firstName,
      lastName: entity.lastName,
      gender: entity.gender,
      dateOfBirth: entity.dateOfBirth,
      classId: entity.classId,
      sectionId: entity.sectionId,
      fatherName: entity.fatherName,
      motherName: entity.motherName,
      guardianPhone: entity.guardianPhone,
      guardianEmail: entity.guardianEmail,
      address: entity.address,
      profileImageUrl: entity.profileImageUrl,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}