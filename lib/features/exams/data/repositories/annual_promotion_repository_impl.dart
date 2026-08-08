import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/annual_promotion_entity.dart';
import '../../domain/repositories/annual_promotion_repository.dart';

class AnnualPromotionRepositoryImpl implements AnnualPromotionRepository {
  const AnnualPromotionRepositoryImpl({
    required FirebaseFirestoreService firestoreService,
    required FirebaseAuth auth,
  }) : _service = firestoreService,
       _auth = auth;

  final FirebaseFirestoreService _service;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _history =>
      _service.collection(FirestorePaths.annualPromotionHistory);

  CollectionReference<Map<String, dynamic>> get _runs =>
      _service.collection(FirestorePaths.annualPromotionRuns);

  @override
  Future<Set<String>> processedStudentIds({
    required String academicSession,
    required String finalExamId,
  }) async {
    final snapshot = await _history
        .where('fromAcademicSession', isEqualTo: academicSession)
        .where('finalExamId', isEqualTo: finalExamId)
        .get();
    return snapshot.docs
        .map((document) => document.data()['studentId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  @override
  Future<AnnualPromotionExecutionSummary> execute({
    required AnnualPromotionPreview preview,
  }) async {
    _validatePreview(preview);
    final actorId = _auth.currentUser?.uid ?? '';
    if (actorId.isEmpty)
      throw StateError('You must be signed in to promote students.');
    final runId = _runs.doc().id;
    final startedAt = DateTime.now().toUtc().toIso8601String();
    await _runs.doc(runId).set({
      'id': runId,
      'fromAcademicSession': preview.fromSession,
      'toAcademicSession': preview.toSession,
      'finalExamId': preview.examId,
      'finalExamName': preview.examName,
      'status': 'processing',
      'requestedCount': preview.items.where((item) => item.canProcess).length,
      'processedBy': actorId,
      'startedAt': startedAt,
      'createdAt': startedAt,
    });

    var promoted = 0;
    var retained = 0;
    var graduated = 0;
    var alreadyProcessed = 0;
    try {
      for (final item in preview.items.where((item) => item.canProcess)) {
        final applied = await _processStudent(
          preview: preview,
          item: item,
          runId: runId,
          actorId: actorId,
        );
        if (!applied) {
          alreadyProcessed++;
          continue;
        }
        switch (item.action) {
          case AnnualPromotionAction.promote:
            promoted++;
          case AnnualPromotionAction.retain:
            retained++;
          case AnnualPromotionAction.graduate:
            graduated++;
          case AnnualPromotionAction.noAction:
            break;
        }
      }
      final noAction = preview.items
          .where((item) => item.action == AnnualPromotionAction.noAction)
          .length;
      await _runs.doc(runId).update({
        'status': 'completed',
        'promoted': promoted,
        'retained': retained,
        'graduated': graduated,
        'noAction': noAction,
        'alreadyProcessed': alreadyProcessed,
        'completedAt': DateTime.now().toUtc().toIso8601String(),
      });
      return AnnualPromotionExecutionSummary(
        runId: runId,
        promoted: promoted,
        retained: retained,
        graduated: graduated,
        noAction: noAction,
        alreadyProcessed: alreadyProcessed,
      );
    } catch (error) {
      await _runs.doc(runId).update({
        'status': 'failed',
        'error': error.toString(),
        'failedAt': DateTime.now().toUtc().toIso8601String(),
      });
      rethrow;
    }
  }

  Future<bool> _processStudent({
    required AnnualPromotionPreview preview,
    required AnnualPromotionPreviewItem item,
    required String runId,
    required String actorId,
  }) async {
    final historyId = _historyId(preview.examId, item.student.id);
    final historyRef = _history.doc(historyId);
    final studentRef = _service
        .collection(FirestorePaths.students)
        .doc(item.student.id);
    final resultRef = _service
        .collection(FirestorePaths.examResults)
        .doc(item.result!.id);

    return _service.instance.runTransaction<bool>((transaction) async {
      final historySnapshot = await transaction.get(historyRef);
      if (historySnapshot.exists) return false;
      final studentSnapshot = await transaction.get(studentRef);
      final resultSnapshot = await transaction.get(resultRef);
      if (!studentSnapshot.exists || !resultSnapshot.exists) {
        throw StateError(
          '${item.student.fullName}: student or final result no longer exists.',
        );
      }
      final studentData = studentSnapshot.data()!;
      final resultData = resultSnapshot.data()!;
      if (studentData['classId'] != item.previousClassId ||
          studentData['sectionId'] != item.previousSectionId) {
        throw StateError(
          '${item.student.fullName}: class/section changed after preview.',
        );
      }
      final currentResultUpdatedAt = _dateText(resultData['updatedAt']);
      if (resultData['examId'] != preview.examId ||
          resultData['academicSession'] != preview.fromSession ||
          resultData['studentId'] != item.student.id ||
          resultData['classId'] != item.previousClassId ||
          resultData['isPassed'] != item.result!.isPassed ||
          currentResultUpdatedAt !=
              item.result!.updatedAt.toUtc().toIso8601String() ||
          !const ['published', 'locked'].contains(resultData['status'])) {
        throw StateError(
          '${item.student.fullName}: final result changed after preview.',
        );
      }

      if (item.action == AnnualPromotionAction.promote) {
        await _validateTarget(transaction, item);
      }
      final now = DateTime.now().toUtc().toIso8601String();
      final studentUpdates = <String, dynamic>{'updatedAt': now};
      if (item.action == AnnualPromotionAction.promote) {
        studentUpdates.addAll({
          'classId': item.targetClassId,
          'sectionId': item.targetSectionId ?? '',
          'isActive': true,
          'status': StudentStatus.active.name,
        });
      } else if (item.action == AnnualPromotionAction.graduate) {
        studentUpdates.addAll({
          'isActive': false,
          'status': StudentStatus.graduated.name,
          'graduatedAt': now,
          'graduatedAcademicSession': preview.fromSession,
        });
      }
      transaction.update(studentRef, studentUpdates);
      transaction.set(historyRef, {
        'id': historyId,
        'studentId': item.student.id,
        'admissionNo': item.student.admissionNo,
        'studentName': item.student.fullName,
        'fromAcademicSession': preview.fromSession,
        'toAcademicSession': preview.toSession,
        'finalExamId': preview.examId,
        'finalResultId': item.result!.id,
        'finalResult': item.resultStatus.name,
        'previousClassId': item.previousClassId,
        'previousSectionId': item.previousSectionId,
        'newClassId': item.action == AnnualPromotionAction.graduate
            ? item.previousClassId
            : item.targetClassId,
        'newSectionId': item.action == AnnualPromotionAction.graduate
            ? item.previousSectionId
            : item.targetSectionId,
        'action': item.action.name,
        'processedAt': now,
        'processedBy': actorId,
        'promotionRunId': runId,
      });
      return true;
    });
  }

  Future<void> _validateTarget(
    Transaction transaction,
    AnnualPromotionPreviewItem item,
  ) async {
    final classId = item.targetClassId?.trim() ?? '';
    if (classId.isEmpty)
      throw StateError('${item.student.fullName}: target class is required.');
    final classSnapshot = await transaction.get(
      _service.collection(FirestorePaths.classes).doc(classId),
    );
    if (!classSnapshot.exists || classSnapshot.data()?['isActive'] != true) {
      throw StateError('${item.student.fullName}: target class is invalid.');
    }
    final sectionId = item.targetSectionId?.trim() ?? '';
    if (sectionId.isNotEmpty) {
      final sectionSnapshot = await transaction.get(
        _service.collection(FirestorePaths.sections).doc(sectionId),
      );
      if (!sectionSnapshot.exists ||
          sectionSnapshot.data()?['isActive'] != true ||
          sectionSnapshot.data()?['classId'] != classId) {
        throw StateError(
          '${item.student.fullName}: target section is invalid.',
        );
      }
    }
  }

  void _validatePreview(AnnualPromotionPreview preview) {
    for (final item in preview.items.where((item) => item.canProcess)) {
      if (item.result == null || !item.result!.isPublished) {
        throw StateError(
          '${item.student.fullName}: a published final result is required.',
        );
      }
      if (item.resultStatus != AnnualPromotionResultStatus.passed &&
          item.resultStatus != AnnualPromotionResultStatus.failed) {
        throw StateError(
          '${item.student.fullName}: incomplete results cannot be processed.',
        );
      }
      if (item.action == AnnualPromotionAction.promote &&
          (item.targetClassId == null || item.warning.isNotEmpty)) {
        throw StateError(
          '${item.student.fullName}: select a valid target class and section.',
        );
      }
    }
  }

  String _historyId(String examId, String studentId) =>
      base64Url.encode(utf8.encode('$examId|$studentId')).replaceAll('=', '');

  String _dateText(dynamic value) {
    if (value is Timestamp) return value.toDate().toUtc().toIso8601String();
    return DateTime.tryParse(
          value?.toString() ?? '',
        )?.toUtc().toIso8601String() ??
        '';
  }
}
