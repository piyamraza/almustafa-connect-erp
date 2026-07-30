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
  final String motherName;
  final String guardianPhone;
  final String guardianEmail;

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
    required this.motherName,
    required this.guardianPhone,
    required this.guardianEmail,
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
    String? motherName,
    String? guardianPhone,
    String? guardianEmail,
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
      motherName: motherName ?? this.motherName,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      guardianEmail: guardianEmail ?? this.guardianEmail,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
