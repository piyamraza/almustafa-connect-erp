import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../models/staff_model.dart';

abstract class StaffRemoteDataSource {
  Future<List<StaffModel>> getStaff();

  Future<void> saveStaff(StaffModel staff);

  Future<void> deleteStaff(String id);

  String generateStaffId();
}

class StaffRemoteDataSourceImpl implements StaffRemoteDataSource {
  StaffRemoteDataSourceImpl({
    required FirebaseFirestoreService firestoreService,
  }) : _firestoreService = firestoreService;

  final FirebaseFirestoreService _firestoreService;

  @override
  Future<List<StaffModel>> getStaff() async {
    final snapshot = await _firestoreService
        .collection(FirestorePaths.employees)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => StaffModel.fromMap({
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .toList();
  }

  @override
  Future<void> saveStaff(StaffModel staff) {
    return _firestoreService
        .collection(FirestorePaths.employees)
        .doc(staff.id)
        .set(staff.toMap());
  }

  @override
  Future<void> deleteStaff(String id) {
    return _firestoreService
        .collection(FirestorePaths.employees)
        .doc(id)
        .delete();
  }

  @override
  String generateStaffId() {
    return _firestoreService
        .collection(FirestorePaths.employees)
        .doc()
        .id;
  }
}