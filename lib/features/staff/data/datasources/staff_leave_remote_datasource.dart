import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/staff_leave_entity.dart';
import '../models/staff_leave_model.dart';

abstract class StaffLeaveRemoteDataSource {
  Future<List<StaffLeaveModel>> getLeavesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<StaffLeaveModel>> getLeavesByStaff({
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<StaffLeaveModel>> getPendingLeaves();

  Future<void> saveLeave(
    StaffLeaveModel leave,
  );

  Future<void> deleteLeave(
    String leaveId,
  );

  Future<void> updateLeaveStatus({
    required String leaveId,
    required StaffLeaveStatus status,
    required String approvalRemarks,
    required String approvedBy,
    required DateTime? approvedAt,
    required DateTime updatedAt,
  });
}

class StaffLeaveRemoteDataSourceImpl
    implements StaffLeaveRemoteDataSource {
  StaffLeaveRemoteDataSourceImpl(
    this._firestoreService,
  );

  final FirebaseFirestoreService _firestoreService;

  @override
  Future<List<StaffLeaveModel>> getLeavesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final normalizedStartDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final normalizedEndDate = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
      999,
    );

    final snapshot = await _firestoreService
        .collection(FirestorePaths.staffLeaves)
        .where(
          'startDate',
          isLessThanOrEqualTo:
              normalizedEndDate.toIso8601String(),
        )
        .get();

    final leaves = snapshot.docs
        .map(
          (document) {
            return StaffLeaveModel.fromMap({
              ...document.data(),
              'id': document.id,
            });
          },
        )
        .where(
          (leave) =>
              !leave.endDate.isBefore(normalizedStartDate),
        )
        .toList();

    _sortLeaves(leaves);

    return leaves;
  }

  @override
  Future<List<StaffLeaveModel>> getLeavesByStaff({
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final normalizedStartDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final normalizedEndDate = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
      999,
    );

    final snapshot = await _firestoreService
        .collection(FirestorePaths.staffLeaves)
        .where(
          'staffId',
          isEqualTo: staffId,
        )
        .where(
          'startDate',
          isLessThanOrEqualTo:
              normalizedEndDate.toIso8601String(),
        )
        .get();

    final leaves = snapshot.docs
        .map(
          (document) {
            return StaffLeaveModel.fromMap({
              ...document.data(),
              'id': document.id,
            });
          },
        )
        .where(
          (leave) =>
              !leave.endDate.isBefore(normalizedStartDate),
        )
        .toList();

    _sortLeaves(leaves);

    return leaves;
  }

  @override
  Future<List<StaffLeaveModel>> getPendingLeaves() async {
    List<StaffLeaveModel> leaves;

    try {
      final snapshot = await _firestoreService
          .collection(FirestorePaths.staffLeaves)
          .where(
            'status',
            isEqualTo: StaffLeaveStatus.pending.name,
          )
          .get();

      leaves = _toLeaveModels(snapshot);
    } on FirebaseException catch (error) {
      if (error.code != 'failed-precondition') {
        rethrow;
      }

      // Some existing Firebase projects have a field-index exemption for
      // `status`. The approval screen must still remain usable until indexes
      // are managed centrally, so only this exceptional path filters locally.
      final snapshot = await _firestoreService
          .collection(FirestorePaths.staffLeaves)
          .get();
      leaves = _toLeaveModels(snapshot).where(
        (leave) => leave.status == StaffLeaveStatus.pending,
      ).toList();
    }

    _sortLeaves(leaves);

    return leaves;
  }

  @override
  Future<void> saveLeave(
    StaffLeaveModel leave,
  ) {
    return _firestoreService
        .collection(FirestorePaths.staffLeaves)
        .doc(leave.id)
        .set(leave.toMap());
  }

  @override
  Future<void> deleteLeave(
    String leaveId,
  ) {
    return _firestoreService
        .collection(FirestorePaths.staffLeaves)
        .doc(leaveId)
        .delete();
  }

  @override
  Future<void> updateLeaveStatus({
    required String leaveId,
    required StaffLeaveStatus status,
    required String approvalRemarks,
    required String approvedBy,
    required DateTime? approvedAt,
    required DateTime updatedAt,
  }) {
    return _firestoreService
        .collection(FirestorePaths.staffLeaves)
        .doc(leaveId)
        .update({
      'status': status.name,
      'approvalRemarks': approvalRemarks,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    });
  }

  void _sortLeaves(
    List<StaffLeaveModel> leaves,
  ) {
    leaves.sort((first, second) {
      final dateComparison =
          second.startDate.compareTo(first.startDate);

      if (dateComparison != 0) {
        return dateComparison;
      }

      return first.staffName.toLowerCase().compareTo(
            second.staffName.toLowerCase(),
          );
    });
  }

  List<StaffLeaveModel> _toLeaveModels(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map((document) {
      return StaffLeaveModel.fromMap({
        ...document.data(),
        'id': document.id,
      });
    }).toList();
  }
}
