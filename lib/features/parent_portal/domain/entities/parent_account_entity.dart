import 'package:equatable/equatable.dart';

class ParentAccountEntity extends Equatable {
  ParentAccountEntity({
    required this.id,
    required this.fullName,
    required this.mobileNumber,
    this.whatsappNumber = '',
    required this.email,
    required this.relationship,
    required List<String> studentIds,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  }) : studentIds = List<String>.unmodifiable(studentIds);

  final String id;
  final String fullName;
  final String mobileNumber;
  final String whatsappNumber;
  final String email;
  final String relationship;
  final List<String> studentIds;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ParentAccountEntity copyWith({
    String? fullName,
    String? mobileNumber,
    String? whatsappNumber,
    String? email,
    String? relationship,
    List<String>? studentIds,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return ParentAccountEntity(
      id: id,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
      studentIds: studentIds ?? this.studentIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object> get props => [
    id,
    fullName,
    mobileNumber,
    whatsappNumber,
    email,
    relationship,
    studentIds,
    isActive,
    updatedAt,
  ];
}
