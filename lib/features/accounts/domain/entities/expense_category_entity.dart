import 'package:equatable/equatable.dart';

class ExpenseCategoryEntity extends Equatable {
  const ExpenseCategoryEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    isActive,
    displayOrder,
    createdAt,
    updatedAt,
  ];
}
