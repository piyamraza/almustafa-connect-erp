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
  final String motherName;
  final String motherCnic;
  final String motherPhone;
  final String guardianName;
  final String guardianCnic;
  final String guardianPhone;
  final String guardianEmail;
  final String bloodGroup;
  final String medicalAllergies;

  final String address;

  final String profileImageUrl;

  final bool isActive;

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
    required this.motherName,
    this.motherCnic = '',
    this.motherPhone = '',
    this.guardianName = '',
    this.guardianCnic = '',
    required this.guardianPhone,
    required this.guardianEmail,
    this.bloodGroup = '',
    this.medicalAllergies = '',
    required this.address,
    required this.profileImageUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

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
    String? motherName,
    String? motherCnic,
    String? motherPhone,
    String? guardianName,
    String? guardianCnic,
    String? guardianPhone,
    String? guardianEmail,
    String? bloodGroup,
    String? medicalAllergies,
    String? address,
    String? profileImageUrl,
    bool? isActive,
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
      motherName: motherName ?? this.motherName,
      motherCnic: motherCnic ?? this.motherCnic,
      motherPhone: motherPhone ?? this.motherPhone,
      guardianName: guardianName ?? this.guardianName,
      guardianCnic: guardianCnic ?? this.guardianCnic,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      guardianEmail: guardianEmail ?? this.guardianEmail,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      medicalAllergies: medicalAllergies ?? this.medicalAllergies,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
