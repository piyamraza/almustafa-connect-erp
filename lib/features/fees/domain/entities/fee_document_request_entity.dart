import 'package:equatable/equatable.dart';

import 'fee_payment_entity.dart';
import 'monthly_fee_due_entity.dart';

enum FeeDocumentType { challan, receipt }

class FeeChallanDocumentRequest extends Equatable {
  FeeChallanDocumentRequest({
    required List<MonthlyFeeDueEntity> dues,
    required this.copyCount,
  }) : dues = List<MonthlyFeeDueEntity>.unmodifiable(dues);

  final List<MonthlyFeeDueEntity> dues;
  final int copyCount;

  @override
  List<Object> get props => [dues, copyCount];
}

class FeeReceiptDocumentRequest extends Equatable {
  const FeeReceiptDocumentRequest({required this.payment});

  final FeePaymentEntity payment;

  @override
  List<Object> get props => [payment];
}
