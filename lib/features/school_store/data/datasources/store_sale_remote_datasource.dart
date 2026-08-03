import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/store_item_entity.dart';
import '../../domain/entities/store_sale_entity.dart';
import '../../domain/entities/store_student_option_entity.dart';
import '../models/store_item_model.dart';
import '../models/store_sale_model.dart';

abstract class StoreSaleRemoteDataSource {
  Future<List<StoreStudentOptionEntity>> getStudents();
  Future<List<StoreSaleEntity>> getSales();
  Future<void> saveSale(StoreSaleEntity sale);
}

class StoreSaleRemoteDataSourceImpl implements StoreSaleRemoteDataSource {
  const StoreSaleRemoteDataSourceImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<List<StoreStudentOptionEntity>> getStudents() async {
    final snapshot = await _service.collection(FirestorePaths.students).get();

    final students = snapshot.docs.map((doc) {
      final map = doc.data();
      final firstName = map['firstName'] as String? ?? '';
      final lastName = map['lastName'] as String? ?? '';
      final name = '$firstName $lastName'.trim();

      return StoreStudentOptionEntity(
        id: doc.id,
        admissionNo: map['admissionNo'] as String? ?? '',
        name: name.isEmpty ? 'Unnamed Student' : name,
        classId: map['classId'] as String? ?? '',
        sectionId: map['sectionId'] as String? ?? '',
      );
    }).toList();

    students.sort((a, b) => a.name.compareTo(b.name));
    return students;
  }

  @override
  Future<List<StoreSaleEntity>> getSales() async {
    final snapshot = await _service.collection(FirestorePaths.storeSales).get();

    final values = snapshot.docs
        .map((doc) => StoreSaleModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();

    values.sort((a, b) => b.saleDate.compareTo(a.saleDate));
    return values;
  }

  @override
  Future<void> saveSale(StoreSaleEntity sale) async {
    final itemRef = _service
        .collection(FirestorePaths.storeItems)
        .doc(sale.itemId);

    final itemDoc = await itemRef.get();

    if (!itemDoc.exists) {
      throw StateError('Selected store item was not found.');
    }

    final item = StoreItemModel.fromMap({...itemDoc.data()!, 'id': itemDoc.id});

    if (sale.quantity > item.currentStock) {
      throw StateError('Only ${item.currentStock} units are available.');
    }

    final updatedItem = StoreItemEntity(
      id: item.id,
      name: item.name,
      category: item.category,
      purchasePrice: item.purchasePrice,
      salePrice: item.salePrice,
      openingStock: item.openingStock,
      purchasedQuantity: item.purchasedQuantity,
      soldQuantity: item.soldQuantity + sale.quantity,
      lowStockLevel: item.lowStockLevel,
      isActive: item.isActive,
      createdAt: item.createdAt,
      updatedAt: DateTime.now(),
      itemCode: item.itemCode,
    );

    await _service
        .collection(FirestorePaths.storeSales)
        .doc(sale.id)
        .set(StoreSaleModel.fromEntity(sale).toMap());

    await itemRef.set(StoreItemModel.fromEntity(updatedItem).toMap());
  }
}
