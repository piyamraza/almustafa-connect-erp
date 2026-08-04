import 'package:equatable/equatable.dart';

class StaffEntity extends Equatable {
  const StaffEntity({
    required this.id,
    required this.staffId,
    required this.firstName,
    required this.lastName,
    required this.fatherName,
    required this.cnic,
    required this.phone,
    this.whatsappNumber = '',
    required this.address,
    required this.designation,
    required this.joiningDate,
    required this.monthlySalary,
    required this.profileImageUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String staffId;
  final String firstName;
  final String lastName;
  final String fatherName;
  final String cnic;
  final String phone;
  final String whatsappNumber;
  final String address;
  final String designation;
  final DateTime joiningDate;
  final double monthlySalary;
  final String profileImageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get fullName => '$firstName $lastName'.trim();

  StaffEntity copyWith({
    String? id,
    String? staffId,
    String? firstName,
    String? lastName,
    String? fatherName,
    String? cnic,
    String? phone,
    String? whatsappNumber,
    String? address,
    String? designation,
    DateTime? joiningDate,
    double? monthlySalary,
    String? profileImageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StaffEntity(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fatherName: fatherName ?? this.fatherName,
      cnic: cnic ?? this.cnic,
      phone: phone ?? this.phone,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      address: address ?? this.address,
      designation: designation ?? this.designation,
      joiningDate: joiningDate ?? this.joiningDate,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object> get props => [
    id,
    staffId,
    firstName,
    lastName,
    fatherName,
    cnic,
    phone,
    whatsappNumber,
    address,
    designation,
    joiningDate,
    monthlySalary,
    profileImageUrl,
    isActive,
    createdAt,
    updatedAt,
  ];
}
