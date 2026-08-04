import '../../domain/entities/staff_entity.dart';

class StaffModel extends StaffEntity {
  const StaffModel({
    required super.id,
    required super.staffId,
    required super.firstName,
    required super.lastName,
    required super.fatherName,
    required super.cnic,
    required super.phone,
    super.whatsappNumber,
    required super.address,
    required super.designation,
    required super.joiningDate,
    required super.monthlySalary,
    required super.profileImageUrl,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory StaffModel.fromMap(Map<String, dynamic> map) {
    return StaffModel(
      id: map['id'] as String? ?? '',
      staffId: map['staffId'] as String? ?? '',
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      fatherName: map['fatherName'] as String? ?? '',
      cnic: map['cnic'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      whatsappNumber:
          map['whatsappNumber'] as String? ?? map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      designation: map['designation'] as String? ?? '',
      joiningDate:
          DateTime.tryParse(map['joiningDate'] as String? ?? '') ??
          DateTime.now(),
      monthlySalary: (map['monthlySalary'] as num?)?.toDouble() ?? 0,
      profileImageUrl: map['profileImageUrl'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory StaffModel.fromEntity(StaffEntity entity) {
    return StaffModel(
      id: entity.id,
      staffId: entity.staffId,
      firstName: entity.firstName,
      lastName: entity.lastName,
      fatherName: entity.fatherName,
      cnic: entity.cnic,
      phone: entity.phone,
      whatsappNumber: entity.whatsappNumber,
      address: entity.address,
      designation: entity.designation,
      joiningDate: entity.joiningDate,
      monthlySalary: entity.monthlySalary,
      profileImageUrl: entity.profileImageUrl,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'staffId': staffId,
      'firstName': firstName,
      'lastName': lastName,
      'fatherName': fatherName,
      'cnic': cnic,
      'phone': phone,
      'whatsappNumber': whatsappNumber,
      'address': address,
      'designation': designation,
      'joiningDate': joiningDate.toIso8601String(),
      'monthlySalary': monthlySalary,
      'profileImageUrl': profileImageUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
