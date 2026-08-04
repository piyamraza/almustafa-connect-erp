import 'package:equatable/equatable.dart';

class TeacherEntity extends Equatable {
  const TeacherEntity({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.cnic,
    required this.dateOfBirth,
    required this.phone,
    this.whatsappNumber = '',
    required this.email,
    required this.address,
    required this.designation,
    required this.qualification,
    required this.specialization,
    required this.experienceYears,
    required this.joiningDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String gender;
  final String cnic;
  final DateTime dateOfBirth;
  final String phone;
  final String whatsappNumber;
  final String email;
  final String address;
  final String designation;
  final String qualification;
  final String specialization;
  final int experienceYears;
  final DateTime joiningDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get fullName => '$firstName $lastName'.trim();

  @override
  List<Object> get props => [
    id,
    employeeId,
    firstName,
    lastName,
    gender,
    cnic,
    dateOfBirth,
    phone,
    whatsappNumber,
    email,
    address,
    designation,
    qualification,
    specialization,
    experienceYears,
    joiningDate,
    isActive,
    createdAt,
    updatedAt,
  ];
}
