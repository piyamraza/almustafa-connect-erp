import '../../domain/entities/student_entity.dart';

class StudentModel extends StudentEntity {
  const StudentModel({
    required super.id,
    required super.admissionNo,
    required super.rollNumber,
    required super.firstName,
    required super.lastName,
    required super.gender,
    required super.dateOfBirth,
    required super.classId,
    required super.sectionId,
    required super.fatherName,
    super.fatherCnic,
    super.fatherPhone,
    super.fatherWhatsapp,
    required super.motherName,
    super.motherCnic,
    super.motherPhone,
    super.motherWhatsapp,
    super.guardianName,
    super.guardianCnic,
    required super.guardianPhone,
    super.guardianWhatsapp,
    super.preferredWhatsAppContact,
    required super.guardianEmail,
    super.bloodGroup,
    super.medicalAllergies,
    required super.address,
    required super.profileImageUrl,
    required super.isActive,
    super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] ?? '',
      admissionNo: map['admissionNo'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      gender: map['gender'] ?? '',
      dateOfBirth: DateTime.parse(map['dateOfBirth']),
      classId: map['classId'] ?? '',
      sectionId: map['sectionId'] ?? '',
      fatherName: map['fatherName'] ?? '',
      fatherCnic: map['fatherCnic'] ?? '',
      fatherPhone: map['fatherPhone'] ?? '',
      fatherWhatsapp: map['fatherWhatsapp'] ?? map['fatherPhone'] ?? '',
      motherName: map['motherName'] ?? '',
      motherCnic: map['motherCnic'] ?? '',
      motherPhone: map['motherPhone'] ?? '',
      motherWhatsapp: map['motherWhatsapp'] ?? map['motherPhone'] ?? '',
      guardianName: map['guardianName'] ?? '',
      guardianCnic: map['guardianCnic'] ?? '',
      guardianPhone: map['guardianPhone'] ?? '',
      guardianWhatsapp: map['guardianWhatsapp'] ?? map['guardianPhone'] ?? '',
      preferredWhatsAppContact: StudentWhatsAppContact.values.firstWhere(
        (item) => item.name == map['preferredWhatsAppContact'],
        orElse: () => StudentWhatsAppContact.guardian,
      ),
      guardianEmail: map['guardianEmail'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      medicalAllergies: map['medicalAllergies'] ?? '',
      address: map['address'] ?? '',
      profileImageUrl:
          map['profileImageUrl'] ??
          map['photoUrl'] ??
          map['imageUrl'] ??
          map['studentPhotoUrl'] ??
          '',
      isActive: map['isActive'] ?? true,
      status: _status(map),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'admissionNo': admissionNo,
      'rollNumber': rollNumber,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'classId': classId,
      'sectionId': sectionId,
      'fatherName': fatherName,
      'fatherCnic': fatherCnic,
      'fatherPhone': fatherPhone,
      'fatherWhatsapp': fatherWhatsapp,
      'motherName': motherName,
      'motherCnic': motherCnic,
      'motherPhone': motherPhone,
      'motherWhatsapp': motherWhatsapp,
      'guardianName': guardianName,
      'guardianCnic': guardianCnic,
      'guardianPhone': guardianPhone,
      'guardianWhatsapp': guardianWhatsapp,
      'preferredWhatsAppContact': preferredWhatsAppContact.name,
      'guardianEmail': guardianEmail,
      'bloodGroup': bloodGroup,
      'medicalAllergies': medicalAllergies,
      'address': address,
      'profileImageUrl': profileImageUrl,
      'isActive': isActive,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory StudentModel.fromEntity(StudentEntity entity) {
    return StudentModel(
      id: entity.id,
      admissionNo: entity.admissionNo,
      rollNumber: entity.rollNumber,
      firstName: entity.firstName,
      lastName: entity.lastName,
      gender: entity.gender,
      dateOfBirth: entity.dateOfBirth,
      classId: entity.classId,
      sectionId: entity.sectionId,
      fatherName: entity.fatherName,
      fatherCnic: entity.fatherCnic,
      fatherPhone: entity.fatherPhone,
      fatherWhatsapp: entity.fatherWhatsapp,
      motherName: entity.motherName,
      motherCnic: entity.motherCnic,
      motherPhone: entity.motherPhone,
      motherWhatsapp: entity.motherWhatsapp,
      guardianName: entity.guardianName,
      guardianCnic: entity.guardianCnic,
      guardianPhone: entity.guardianPhone,
      guardianWhatsapp: entity.guardianWhatsapp,
      preferredWhatsAppContact: entity.preferredWhatsAppContact,
      guardianEmail: entity.guardianEmail,
      bloodGroup: entity.bloodGroup,
      medicalAllergies: entity.medicalAllergies,
      address: entity.address,
      profileImageUrl: entity.profileImageUrl,
      isActive: entity.isActive,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  static StudentStatus _status(Map<String, dynamic> map) {
    final value = map['status']?.toString();
    return StudentStatus.values.firstWhere(
      (item) => item.name == value,
      orElse: () => (map['isActive'] ?? true)
          ? StudentStatus.active
          : StudentStatus.inactive,
    );
  }
}
