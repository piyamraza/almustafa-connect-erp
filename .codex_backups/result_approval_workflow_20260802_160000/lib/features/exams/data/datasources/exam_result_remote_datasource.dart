import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/exam_result_entity.dart';
import '../models/exam_result_model.dart';

abstract class ExamResultRemoteDataSource {
  Future<List<ExamResultModel>> getResultsForExam(
    String examId,
  );

  Future<List<ExamResultModel>> getPublishedResults({
    String? examId,
    String? classId,
    String? sectionId,
    String? studentId,
  });

  Future<void> saveResults(
    List<ExamResultModel> results,
  );

  Future<void> updateStatus({
    required List<String> resultIds,
    required ResultStatus status,
    String actorId = '',
    String reason = '',
    bool setPublishedAt = true,
  });
}

class ExamResultRemoteDataSourceImpl
    implements ExamResultRemoteDataSource {
  ExamResultRemoteDataSourceImpl({
    required FirebaseFirestoreService firestoreService,
  }) : _service = firestoreService;

  final FirebaseFirestoreService _service;

  CollectionReference<Map<String, dynamic>>
      get _collection {
    return _service.collection(
      FirestorePaths.examResults,
    );
  }

  @override
  Future<List<ExamResultModel>> getResultsForExam(
    String examId,
  ) async {
    final normalizedExamId = examId.trim();

    if (normalizedExamId.isEmpty) {
      throw ArgumentError.value(
        examId,
        'examId',
        'Exam ID cannot be empty.',
      );
    }

    final snapshot = await _collection
        .where(
          'examId',
          isEqualTo: normalizedExamId,
        )
        .get();

    final results = snapshot.docs
        .map(
          (document) => ExamResultModel.fromMap({
            ...document.data(),
            'id': document.id,
          }),
        )
        .toList(growable: false);

    results.sort((first, second) {
      final classOrder = first.className.compareTo(
        second.className,
      );

      if (classOrder != 0) {
        return classOrder;
      }

      final sectionOrder =
          first.sectionName.compareTo(
        second.sectionName,
      );

      if (sectionOrder != 0) {
        return sectionOrder;
      }

      final firstRoll =
          int.tryParse(first.rollNumber.trim());
      final secondRoll =
          int.tryParse(second.rollNumber.trim());

      if (firstRoll != null && secondRoll != null) {
        return firstRoll.compareTo(secondRoll);
      }

      return first.studentName.compareTo(
        second.studentName,
      );
    });

    return results;
  }

  @override
  Future<List<ExamResultModel>> getPublishedResults({
    String? examId,
    String? classId,
    String? sectionId,
    String? studentId,
  }) async {
    final snapshot = await _collection
        .where(
          'status',
          whereIn: [
            ResultStatus.published.name,
            ResultStatus.locked.name,
          ],
        )
        .get();

    final results = snapshot.docs
        .map(
          (document) => ExamResultModel.fromMap({
            ...document.data(),
            'id': document.id,
          }),
        )
        .where(
          (result) =>
              (examId == null ||
                  result.examId == examId) &&
              (classId == null ||
                  result.classId == classId) &&
              (sectionId == null ||
                  result.sectionId == sectionId) &&
              (studentId == null ||
                  result.studentId == studentId),
        )
        .toList(growable: false);

    results.sort(
      (first, second) =>
          second.updatedAt.compareTo(
        first.updatedAt,
      ),
    );

    return results;
  }

  @override
  Future<void> saveResults(
    List<ExamResultModel> results,
  ) async {
    if (results.isEmpty) {
      return;
    }

    final ids = <String>{};

    for (final result in results) {
      final normalizedId = result.id.trim();

      if (normalizedId.isEmpty) {
        throw ArgumentError.value(
          result.id,
          'result.id',
          'Result ID cannot be empty.',
        );
      }

      if (!ids.add(normalizedId)) {
        throw StateError(
          'Duplicate results were generated for a student.',
        );
      }
    }

    for (
      var start = 0;
      start < results.length;
      start += 500
    ) {
      final end = start + 500 > results.length
          ? results.length
          : start + 500;

      final batch = _service.instance.batch();

      for (final result
          in results.sublist(start, end)) {
        batch.set(
          _collection.doc(result.id),
          result.toMap(),
        );
      }

      await batch.commit();
    }
  }

  @override
  Future<void> updateStatus({
    required List<String> resultIds,
    required ResultStatus status,
    String actorId = '',
    String reason = '',
    bool setPublishedAt = true,
  }) async {
    final normalizedIds = resultIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (normalizedIds.isEmpty) {
      return;
    }

    final normalizedActorId = actorId.trim();
    final normalizedReason = reason.trim();
    final snapshots =
        <DocumentSnapshot<Map<String, dynamic>>>[];

    for (var start = 0;
        start < normalizedIds.length;
        start += 10) {
      final end = start + 10 > normalizedIds.length
          ? normalizedIds.length
          : start + 10;

      final snapshot = await _collection
          .where(
            FieldPath.documentId,
            whereIn: normalizedIds.sublist(
              start,
              end,
            ),
          )
          .get();

      snapshots.addAll(snapshot.docs);
    }

    if (snapshots.length != normalizedIds.length) {
      throw StateError(
        'One or more selected results no longer exist.',
      );
    }

    final models = snapshots
        .map(
          (document) => ExamResultModel.fromMap({
            ...document.data()!,
            'id': document.id,
          }),
        )
        .toList(growable: false);

    for (final result in models) {
      if (!ExamResultEntity.canTransition(
        current: result.status,
        next: status,
      )) {
        throw StateError(
          'Invalid result transition: '
          '${result.status.name} to ${status.name}.',
        );
      }
    }

    if (_requiresActor(status) &&
        normalizedActorId.isEmpty) {
      throw StateError(
        '${_statusLabel(status)} user ID is required.',
      );
    }

    final unlocking = models.any(
      (result) =>
          result.status == ResultStatus.locked &&
          status == ResultStatus.published,
    );

    if (unlocking && normalizedReason.isEmpty) {
      throw StateError(
        'Unlock reason is required.',
      );
    }

    final now = DateTime.now();
    final nowText = now.toIso8601String();

    for (
      var start = 0;
      start < snapshots.length;
      start += 500
    ) {
      final end = start + 500 > snapshots.length
          ? snapshots.length
          : start + 500;

      final batch = _service.instance.batch();

      for (final snapshot
          in snapshots.sublist(start, end)) {
        final current =
            ExamResultModel.fromMap({
          ...snapshot.data()!,
          'id': snapshot.id,
        });

        batch.update(
          snapshot.reference,
          _statusUpdates(
            current: current,
            next: status,
            actorId: normalizedActorId,
            reason: normalizedReason,
            now: now,
            nowText: nowText,
            setPublishedAt: setPublishedAt,
          ),
        );
      }

      await batch.commit();
    }
  }

  Map<String, dynamic> _statusUpdates({
    required ExamResultModel current,
    required ResultStatus next,
    required String actorId,
    required String reason,
    required DateTime now,
    required String nowText,
    required bool setPublishedAt,
  }) {
    final updates = <String, dynamic>{
      'status': next.name,
      'updatedAt': nowText,
      'schemaVersion': 2,
    };

    switch (next) {
      case ResultStatus.draft:
        break;

      case ResultStatus.generated:
        updates.addAll({
          'generatedAt':
              current.generatedAt?.toIso8601String() ??
                  nowText,
          if (actorId.isNotEmpty)
            'generatedBy': actorId,
        });

      case ResultStatus.verified:
        updates.addAll({
          'verifiedAt': nowText,
          'verifiedBy': actorId,
        });

      case ResultStatus.approved:
        updates.addAll({
          'approvedAt': nowText,
          'approvedBy': actorId,
        });

      case ResultStatus.published:
        final isUnlocking =
            current.status == ResultStatus.locked;

        if (isUnlocking) {
          updates.addAll({
            'unlockedAt': nowText,
            'unlockedBy': actorId,
            'unlockReason': reason,
          });
        } else if (setPublishedAt) {
          updates.addAll({
            'publishedAt': nowText,
            'publishedBy': actorId,
          });
        }

      case ResultStatus.locked:
        updates.addAll({
          'lockedAt': nowText,
          'lockedBy': actorId,
        });

      case ResultStatus.unpublished:
        updates.addAll({
          'unlockedAt': nowText,
          'unlockedBy': actorId,
          'unlockReason': reason,
        });
    }

    return updates;
  }

  bool _requiresActor(ResultStatus status) {
    return status == ResultStatus.verified ||
        status == ResultStatus.approved ||
        status == ResultStatus.published ||
        status == ResultStatus.locked;
  }

  String _statusLabel(ResultStatus status) {
    return switch (status) {
      ResultStatus.draft => 'Draft',
      ResultStatus.generated => 'Generated-by',
      ResultStatus.verified => 'Verified-by',
      ResultStatus.approved => 'Approved-by',
      ResultStatus.published => 'Published-by',
      ResultStatus.locked => 'Locked-by',
      ResultStatus.unpublished => 'Unpublished-by',
    };
  }
}