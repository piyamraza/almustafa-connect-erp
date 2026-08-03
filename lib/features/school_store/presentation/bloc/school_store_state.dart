import 'package:equatable/equatable.dart';
import '../../domain/entities/store_item_entity.dart';

sealed class SchoolStoreState extends Equatable {
  const SchoolStoreState();
  @override
  List<Object?> get props => const [];
}

class SchoolStoreInitial extends SchoolStoreState {
  const SchoolStoreInitial();
}

class SchoolStoreLoading extends SchoolStoreState {
  const SchoolStoreLoading();
}

class SchoolStoreLoaded extends SchoolStoreState {
  const SchoolStoreLoaded({required this.items, this.message});
  final List<StoreItemEntity> items;
  final String? message;
  int get totalStock => items.fold(0, (s, e) => s + e.currentStock);
  int get lowStockItems => items.where((e) => e.isLowStock).length;
  double get stockValue => items.fold(0, (s, e) => s + e.stockValue);
  @override
  List<Object?> get props => [items, message];
}

class SchoolStoreFailure extends SchoolStoreState {
  const SchoolStoreFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
