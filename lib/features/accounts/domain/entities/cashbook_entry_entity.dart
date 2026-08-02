import 'package:equatable/equatable.dart';

enum CashbookEntryType { income, expense }

class CashbookEntryEntity extends Equatable {
  const CashbookEntryEntity({
    required this.id,
    required this.entryDate,
    required this.entryType,
    required this.amount,
    required this.description,
    required this.paymentMethod,
    required this.referenceNumber,
    required this.sourceType,
    required this.sourceId,
    required this.createdAt,
    required this.createdBy,
  });

  final String id;
  final DateTime entryDate;
  final CashbookEntryType entryType;
  final int amount;
  final String description;
  final String paymentMethod;
  final String referenceNumber;
  final String sourceType;
  final String sourceId;
  final DateTime createdAt;
  final String createdBy;

  @override
  List<Object?> get props => [
    id,
    entryDate,
    entryType,
    amount,
    description,
    paymentMethod,
    referenceNumber,
    sourceType,
    sourceId,
    createdAt,
    createdBy,
  ];
}
