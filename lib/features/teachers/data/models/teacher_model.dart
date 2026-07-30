import '../../domain/entities/teacher_entity.dart';

class TeacherModel extends TeacherEntity {
  const TeacherModel({
    required super.id,
    required super.employeeId,
    required super.firstName,
    required super.lastName,
    required super.gender,
    required super.cnic,
    required super.dateOfBirth,
    required super.phone,
    required super.email,
    required super.address,
    required super.designation,
    required super.qualification,
    required super.specialization,
    required super.experienceYears,
    required super.joiningDate,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TeacherModel.fromMap(Map<String, dynamic> map) => TeacherModel(
        id: map['id'] ?? '', employeeId: map['employeeId'] ?? '',
        firstName: map['firstName'] ?? '', lastName: map['lastName'] ?? '',
        gender: map['gender'] ?? '', cnic: map['cnic'] ?? '', dateOfBirth: DateTime.tryParse(map['dateOfBirth'] ?? '') ?? DateTime.now(), phone: map['phone'] ?? '', email: map['email'] ?? '',
        address: map['address'] ?? '', designation: map['designation'] ?? '',
        qualification: map['qualification'] ?? '', specialization: map['specialization'] ?? '', experienceYears: (map['experienceYears'] as num?)?.toInt() ?? 0,
        joiningDate: DateTime.tryParse(map['joiningDate'] ?? '') ?? DateTime.now(),
        isActive: map['isActive'] ?? true,
        createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      );

  factory TeacherModel.fromEntity(TeacherEntity entity) => TeacherModel(
        id: entity.id, employeeId: entity.employeeId, firstName: entity.firstName,
        lastName: entity.lastName, gender: entity.gender, cnic: entity.cnic, dateOfBirth: entity.dateOfBirth, phone: entity.phone,
        email: entity.email, address: entity.address, designation: entity.designation,
        qualification: entity.qualification, specialization: entity.specialization, experienceYears: entity.experienceYears,
        joiningDate: entity.joiningDate, isActive: entity.isActive,
        createdAt: entity.createdAt, updatedAt: entity.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id, 'employeeId': employeeId, 'firstName': firstName,
        'lastName': lastName, 'gender': gender, 'cnic': cnic, 'dateOfBirth': dateOfBirth.toIso8601String(), 'phone': phone, 'email': email,
        'address': address, 'designation': designation,
        'qualification': qualification, 'specialization': specialization, 'experienceYears': experienceYears,
        'joiningDate': joiningDate.toIso8601String(), 'isActive': isActive,
        'createdAt': createdAt.toIso8601String(), 'updatedAt': updatedAt.toIso8601String(),
      };
}
