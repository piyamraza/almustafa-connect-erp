enum StudentStatus { active, inactive, graduated }

class StudentEntity {
  final String id;
  final String admissionNo;
  final String rollNumber;

  final String firstName;
  final String lastName;

  final String gender;
  final DateTime dateOfBirth;

  final String classId;
  final String sectionId;

  final String fatherName;
  final String fatherCnic;
  final String fatherPhone;
  final String fatherWhatsapp;
  final String motherName;
  final String motherCnic;
  final String motherPhone;
  final String motherWhatsapp;
  final String guardianName;
  final String guardianCnic;
  final String guardianPhone;
  final String guardianWhatsapp;
  final String guardianEmail;
  final String bloodGroup;
  final String medicalAllergies;

  final String address;

  final String profileImageUrl;

  final bool isActive;
  final StudentStatus status;

  final DateTime createdAt;
  final DateTime updatedAt;

  const StudentEntity({
    required this.id,
    required this.admissionNo,
    required this.rollNumber,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.dateOfBirth,
    required this.classId,
    required this.sectionId,
    required this.fatherName,
    this.fatherCnic = '',
    this.fatherPhone = '',
    this.fatherWhatsapp = '',
    required this.motherName,
    this.motherCnic = '',
    this.motherPhone = '',
    this.motherWhatsapp = '',
    this.guardianName = '',
    this.guardianCnic = '',
    required this.guardianPhone,
    this.guardianWhatsapp = '',
    required this.guardianEmail,
    this.bloodGroup = '',
    this.medicalAllergies = '',
    required this.address,
    required this.profileImageUrl,
    required this.isActive,
    StudentStatus? status,
    required this.createdAt,
    required this.updatedAt,
  }) : status =
           status ?? (isActive ? StudentStatus.active : StudentStatus.inactive);

  String get fullName => "$firstName $lastName";

  StudentEntity copyWith({
    String? id,
    String? admissionNo,
    String? rollNumber,
    String? firstName,
    String? lastName,
    String? gender,
    DateTime? dateOfBirth,
    String? classId,
    String? sectionId,
    String? fatherName,
    String? fatherCnic,
    String? fatherPhone,
    String? fatherWhatsapp,
    String? motherName,
    String? motherCnic,
    String? motherPhone,
    String? motherWhatsapp,
    String? guardianName,
    String? guardianCnic,
    String? guardianPhone,
    String? guardianWhatsapp,
    String? guardianEmail,
    String? bloodGroup,
    String? medicalAllergies,
    String? address,
    String? profileImageUrl,
    bool? isActive,
    StudentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentEntity(
      id: id ?? this.id,
      admissionNo: admissionNo ?? this.admissionNo,
      rollNumber: rollNumber ?? this.rollNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      fatherName: fatherName ?? this.fatherName,
      fatherCnic: fatherCnic ?? this.fatherCnic,
      fatherPhone: fatherPhone ?? this.fatherPhone,
      fatherWhatsapp: fatherWhatsapp ?? this.fatherWhatsapp,
      motherName: motherName ?? this.motherName,
      motherCnic: motherCnic ?? this.motherCnic,
      motherPhone: motherPhone ?? this.motherPhone,
      motherWhatsapp: motherWhatsapp ?? this.motherWhatsapp,
      guardianName: guardianName ?? this.guardianName,
      guardianCnic: guardianCnic ?? this.guardianCnic,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      guardianWhatsapp: guardianWhatsapp ?? this.guardianWhatsapp,
      guardianEmail: guardianEmail ?? this.guardianEmail,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      medicalAllergies: medicalAllergies ?? this.medicalAllergies,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive:
          isActive ??
          status == StudentStatus.active || (status == null && this.isActive),
      status:
          status ??
          (isActive == null
              ? this.status
              : isActive
              ? StudentStatus.active
              : StudentStatus.inactive),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
