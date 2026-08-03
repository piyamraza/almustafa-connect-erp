import 'package:equatable/equatable.dart';
import '../../domain/entities/store_item_entity.dart';

sealed class SchoolStoreEvent extends Equatable {
  const SchoolStoreEvent();
  @override
  List<Object?> get props => const [];
}

class LoadSchoolStore extends SchoolStoreEvent {
  const LoadSchoolStore();
}

class SaveStoreItemRequested extends SchoolStoreEvent {
  const SaveStoreItemRequested(this.item);
  final StoreItemEntity item;
  @override
  List<Object?> get props => [item];
}

class DeleteStoreItemRequested extends SchoolStoreEvent {
  const DeleteStoreItemRequested(this.itemId);
  final String itemId;
  @override
  List<Object?> get props => [itemId];
}
