import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/monthly_profit_loss_entity.dart';
import '../models/monthly_profit_loss_model.dart';

class ProfitLossRemoteDataSource {
  const ProfitLossRemoteDataSource(this._service);

  final FirebaseFirestoreService _service;

  Future<List<MonthlyProfitLossEntity>> getSnapshots() async {
    final snapshot = await _service
        .collection(FirestorePaths.monthlyProfitLoss)
        .get();

    final values = snapshot.docs
        .map(
          (doc) =>
              MonthlyProfitLossModel.fromMap({...doc.data(), 'id': doc.id}),
        )
        .toList();

    values.sort((a, b) => b.month.compareTo(a.month));
    return values;
  }

  Future<void> saveSnapshot(MonthlyProfitLossEntity snapshot) {
    return _service
        .collection(FirestorePaths.monthlyProfitLoss)
        .doc(snapshot.id)
        .set(MonthlyProfitLossModel.fromEntity(snapshot).toMap());
  }
}
