import 'package:equatable/equatable.dart';

import '../../domain/entities/store_sale_entity.dart';

sealed class StoreSaleEvent extends Equatable {
  const StoreSaleEvent();

  @override
  List<Object?> get props => const [];
}

class LoadStoreSales extends StoreSaleEvent {
  const LoadStoreSales();
}

class SaveStoreSaleRequested extends StoreSaleEvent {
  const SaveStoreSaleRequested(this.sale);

  final StoreSaleEntity sale;

  @override
  List<Object?> get props => [sale];
}
