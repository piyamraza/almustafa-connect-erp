import 'package:equatable/equatable.dart';

import '../../domain/entities/store_item_entity.dart';
import '../../domain/entities/store_sale_entity.dart';
import '../../domain/entities/store_student_option_entity.dart';

sealed class StoreSaleState extends Equatable {
  const StoreSaleState();

  @override
  List<Object?> get props => const [];
}

class StoreSaleInitial extends StoreSaleState {
  const StoreSaleInitial();
}

class StoreSaleLoading extends StoreSaleState {
  const StoreSaleLoading();
}

class StoreSaleLoaded extends StoreSaleState {
  const StoreSaleLoaded({
    required this.students,
    required this.items,
    required this.sales,
    this.message,
  });

  final List<StoreStudentOptionEntity> students;
  final List<StoreItemEntity> items;
  final List<StoreSaleEntity> sales;
  final String? message;

  double get totalSales =>
      sales.fold<double>(0, (sum, sale) => sum + sale.netAmount);

  double get totalReceived =>
      sales.fold<double>(0, (sum, sale) => sum + sale.paidAmount);

  double get totalOutstanding =>
      sales.fold<double>(0, (sum, sale) => sum + sale.outstandingAmount);

  double get totalProfit =>
      sales.fold<double>(0, (sum, sale) => sum + sale.profitAmount);

  @override
  List<Object?> get props => [students, items, sales, message];
}

class StoreSaleFailure extends StoreSaleState {
  const StoreSaleFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
