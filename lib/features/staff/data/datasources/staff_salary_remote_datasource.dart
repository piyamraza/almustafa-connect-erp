import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/staff_salary_entity.dart';
import '../models/staff_salary_model.dart';

abstract class StaffSalaryRemoteDataSource {
  Future<List<StaffSalaryModel>> getSalariesByMonth(
    DateTime month,
  );

  Future<List<StaffSalaryModel>> getSalariesByStaff({
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<void> saveSalary(
    StaffSalaryModel salary,
  );

  Future<void> saveSalaries(
    List<StaffSalaryModel> salaries,
  );

  Future<void> updatePaymentStatus({
    required String salaryId,
    required StaffSalaryPaymentStatus paymentStatus,
    required DateTime? paymentDate,
    required StaffSalaryPaymentMethod? paymentMethod,
    required String paymentReference,
    required DateTime updatedAt,
  });
}

class StaffSalaryRemoteDataSourceImpl
    implements StaffSalaryRemoteDataSource {
  StaffSalaryRemoteDataSourceImpl({
    required this._firestoreService,
  });

  final FirebaseFirestoreService _firestoreService;

  @override
  Future<List<StaffSalaryModel>> getSalariesByMonth(
    DateTime month,
  ) async {
    final monthStart = DateTime(
      month.year,
      month.month,
      1,
    );

    final nextMonth = DateTime(
      month.year,
      month.month + 1,
      1,
    );

    final snapshot = await _firestoreService
        .collection(FirestorePaths.staffSalaries)
        .where(
          'salaryMonth',
          isGreaterThanOrEqualTo: monthStart.toIso8601String(),
        )
        .where(
          'salaryMonth',
          isLessThan: nextMonth.toIso8601String(),
        )
        .get();

    final salaries = snapshot.docs.map(
      (document) {
        return StaffSalaryModel.fromMap({
          ...document.data(),
          'id': document.id,
        });
      },
    ).toList();

    salaries.sort(
      (first, second) => first.staffName.toLowerCase().compareTo(
            second.staffName.toLowerCase(),
          ),
    );

    return salaries;
  }

  @override
  Future<List<StaffSalaryModel>> getSalariesByStaff({
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final normalizedStartDate = DateTime(
      startDate.year,
      startDate.month,
      1,
    );

    final normalizedEndDate = DateTime(
      endDate.year,
      endDate.month + 1,
      1,
    );

    final snapshot = await _firestoreService
        .collection(FirestorePaths.staffSalaries)
        .where(
          'staffId',
          isEqualTo: staffId,
        )
        .where(
          'salaryMonth',
          isGreaterThanOrEqualTo:
              normalizedStartDate.toIso8601String(),
        )
        .where(
          'salaryMonth',
          isLessThan: normalizedEndDate.toIso8601String(),
        )
        .get();

    final salaries = snapshot.docs.map(
      (document) {
        return StaffSalaryModel.fromMap({
          ...document.data(),
          'id': document.id,
        });
      },
    ).toList();

    salaries.sort(
      (first, second) => second.salaryMonth.compareTo(
        first.salaryMonth,
      ),
    );

    return salaries;
  }

  @override
  Future<void> saveSalary(
    StaffSalaryModel salary,
  ) {
    return _firestoreService
        .collection(FirestorePaths.staffSalaries)
        .doc(salary.id)
        .set(salary.toMap());
  }

  @override
  Future<void> saveSalaries(
    List<StaffSalaryModel> salaries,
  ) async {
    if (salaries.isEmpty) {
      return;
    }

    final batch = _firestoreService.instance.batch();
    final collection = _firestoreService.collection(
      FirestorePaths.staffSalaries,
    );

    for (final salary in salaries) {
      batch.set(
        collection.doc(salary.id),
        salary.toMap(),
      );
    }

    await batch.commit();
  }

  @override
  Future<void> updatePaymentStatus({
    required String salaryId,
    required StaffSalaryPaymentStatus paymentStatus,
    required DateTime? paymentDate,
    required StaffSalaryPaymentMethod? paymentMethod,
    required String paymentReference,
    required DateTime updatedAt,
  }) {
    return _firestoreService
        .collection(FirestorePaths.staffSalaries)
        .doc(salaryId)
        .update({
      'paymentStatus': paymentStatus.name,
      'paymentDate': paymentDate?.toIso8601String(),
      'paymentMethod': paymentMethod?.name,
      'paymentReference': paymentReference,
      'updatedAt': updatedAt.toIso8601String(),
    });
  }
}