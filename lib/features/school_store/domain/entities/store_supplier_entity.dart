import 'package:equatable/equatable.dart';

class StoreSupplierEntity extends Equatable {
  const StoreSupplierEntity({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.contactPerson = '',
    this.mobileNumber = '',
    this.whatsappNumber = '',
    this.address = '',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String contactPerson;
  final String mobileNumber;
  final String whatsappNumber;
  final String address;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    name,
    contactPerson,
    mobileNumber,
    whatsappNumber,
    address,
    isActive,
    createdAt,
    updatedAt,
  ];
}
