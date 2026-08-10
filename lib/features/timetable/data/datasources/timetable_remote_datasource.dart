import 'package:almustafa_connect_erp/features/academic_structure/domain/services/academic_class_order.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/manual_timetable_change_entity.dart';
import '../../domain/entities/timetable_version_entity.dart';
import '../models/class_timetable_entry_model.dart';
import '../models/timetable_configuration_model.dart';
import '../models/timetable_version_model.dart';

abstract class TimetableRemoteDataSource {
  Future<TimetableConfigurationModel?> getConfiguration({
    required String branchId,
    required String academicSession,
    String? classId,
  });
  Future<List<TimetableConfigurationModel>> getConfigurations({
    required String branchId,
    required String academicSession,
  });

  Future<void> saveConfiguration(TimetableConfigurationModel configuration);

  String generateConfigurationId();

  Future<List<TimetableVersionModel>> getTimetableVersions({
    required String branchId,
    required String academicSession,
  });
  Future<void> saveTimetableVersion(TimetableVersionEntity version);
  Future<void> publishTimetableVersion(String versionId);
  Future<void> archiveTimetableVersion(String versionId);
  Future<void> restoreTimetableVersion(String versionId);
  String generateTimetableVersionId();
  Future<void> applyManualTimetableChanges(ManualTimetableChangeSet changes);

  Future<List<ClassTimetableEntryModel>> getAllTimetableEntries({
    required String branchId,
    required String academicSession,
  });
  Future<List<ClassTimetableEntryModel>> getClassTimetable({
    required String branchId,
    required String academicSession,
    required String classId,
    required String sectionId,
  });

  Future<List<ClassTimetableEntryModel>> getTeacherTimetable({
    required String branchId,
    required String academicSession,
    required String teacherId,
  });
  Future<List<ClassTimetableEntryModel>> getDayTimetable({
    required String branchId,
    required String academicSession,
    required int weekday,
  });
  Future<void> saveClassTimetableEntry(ClassTimetableEntryModel entry);

  Future<void> deleteClassTimetableEntry(String entryId);

  String generateClassTimetableEntryId();
}

class TimetableRemoteDataSourceImpl implements TimetableRemoteDataSource {
  TimetableRemoteDataSourceImpl({required this.firestoreService});

  final FirebaseFirestoreService firestoreService;

  @override
  Future<TimetableConfigurationModel?> getConfiguration({
    required String branchId,
    required String academicSession,
    String? classId,
  }) async {
    final configurations = await getConfigurations(
      branchId: branchId,
      academicSession: academicSession,
    );
    final requestedClassId = classId?.trim() ?? '';
    if (requestedClassId.isNotEmpty) {
      for (final configuration in configurations) {
        if (configuration.classIds.contains(requestedClassId)) {
          return configuration;
        }
      }
    }
    for (final configuration in configurations) {
      if (configuration.classIds.isEmpty) {
        return configuration;
      }
    }
    return null;
  }

  @override
  Future<List<TimetableConfigurationModel>> getConfigurations({
    required String branchId,
    required String academicSession,
  }) async {
    final snapshot = await firestoreService
        .collection(FirestorePaths.timetableConfigurations)
        .where('branchId', isEqualTo: branchId.trim())
        .where('academicSession', isEqualTo: academicSession.trim())
        .get();
    return snapshot.docs
        .map(
          (document) => TimetableConfigurationModel.fromMap({
            ...document.data(),
            'id': document.id,
          }),
        )
        .where((configuration) => configuration.isActive)
        .toList(growable: false);
  }

  @override
  Future<void> saveConfiguration(
    TimetableConfigurationModel configuration,
  ) async {
    final existingConfigurations = await getConfigurations(
      branchId: configuration.branchId,
      academicSession: configuration.academicSession,
    );

    for (final existing in existingConfigurations) {
      if (existing.id == configuration.id) continue;
      final bothDefault =
          existing.classIds.isEmpty && configuration.classIds.isEmpty;
      final overlappingClasses = existing.classIds.toSet().intersection(
        configuration.classIds.toSet(),
      );
      if (bothDefault || overlappingClasses.isNotEmpty) {
        throw StateError(
          bothDefault
              ? 'A default timetable schedule already exists for this session.'
              : 'One or more selected classes already have a timetable schedule.',
        );
      }
    }

    await firestoreService
        .collection(FirestorePaths.timetableConfigurations)
        .doc(configuration.id)
        .set(configuration.toMap());
  }

  @override
  String generateConfigurationId() {
    return firestoreService
        .collection(FirestorePaths.timetableConfigurations)
        .doc()
        .id;
  }

  @override
  Future<List<TimetableVersionModel>> getTimetableVersions({
    required String branchId,
    required String academicSession,
  }) async {
    final snapshot = await firestoreService
        .collection(FirestorePaths.timetableVersions)
        .where('branchId', isEqualTo: branchId.trim())
        .where('academicSession', isEqualTo: academicSession.trim())
        .get();

    final values =
        snapshot.docs
            .map(
              (document) => TimetableVersionModel.fromMap({
                ...document.data(),
                'id': document.id,
              }),
            )
            .toList()
          ..sort(
            (first, second) =>
                second.versionNumber.compareTo(first.versionNumber),
          );

    return List<TimetableVersionModel>.unmodifiable(values);
  }

  @override
  Future<void> saveTimetableVersion(TimetableVersionEntity version) {
    return firestoreService
        .collection(FirestorePaths.timetableVersions)
        .doc(version.id)
        .set(TimetableVersionModel.fromEntity(version).toMap());
  }

  @override
  Future<void> publishTimetableVersion(String versionId) async {
    final targetReference = firestoreService
        .collection(FirestorePaths.timetableVersions)
        .doc(versionId);
    final targetSnapshot = await targetReference.get();

    if (!targetSnapshot.exists || targetSnapshot.data() == null) {
      throw StateError('Timetable version was not found.');
    }

    final target = TimetableVersionModel.fromMap({
      ...targetSnapshot.data()!,
      'id': targetSnapshot.id,
    });

    final snapshot = await firestoreService
        .collection(FirestorePaths.timetableVersions)
        .where('branchId', isEqualTo: target.branchId)
        .where('academicSession', isEqualTo: target.academicSession)
        .get();

    final batch = firestoreService.instance.batch();
    final now = DateTime.now();

    for (final document in snapshot.docs) {
      final status = document.data()['status'];

      if (document.id == versionId) {
        batch.update(document.reference, {
          'status': TimetableVersionStatus.published.name,
          'publishedAt': now,
          'updatedAt': now,
        });
      } else if (status == TimetableVersionStatus.published.name) {
        batch.update(document.reference, {
          'status': TimetableVersionStatus.archived.name,
          'updatedAt': now,
        });
      }
    }

    await batch.commit();
  }

  @override
  Future<void> archiveTimetableVersion(String versionId) {
    return firestoreService
        .collection(FirestorePaths.timetableVersions)
        .doc(versionId)
        .update({
          'status': TimetableVersionStatus.archived.name,
          'updatedAt': DateTime.now(),
        });
  }

  @override
  Future<void> restoreTimetableVersion(String versionId) async {
    final document = await firestoreService
        .collection(FirestorePaths.timetableVersions)
        .doc(versionId)
        .get();

    if (!document.exists || document.data() == null) {
      throw StateError('Timetable version was not found.');
    }

    final version = TimetableVersionModel.fromMap({
      ...document.data()!,
      'id': document.id,
    });

    final currentEntries = await _getSessionEntries(
      branchId: version.branchId,
      academicSession: version.academicSession,
    );

    final batch = firestoreService.instance.batch();
    final collection = firestoreService.collection(
      FirestorePaths.timetableEntries,
    );

    for (final entry in currentEntries) {
      batch.delete(collection.doc(entry.id));
    }

    for (final entry in version.entries) {
      batch.set(
        collection.doc(entry.id),
        ClassTimetableEntryModel.fromEntity(entry).toMap(),
      );
    }

    await batch.commit();
  }

  @override
  String generateTimetableVersionId() {
    return firestoreService
        .collection(FirestorePaths.timetableVersions)
        .doc()
        .id;
  }

  @override
  Future<void> applyManualTimetableChanges(
    ManualTimetableChangeSet changes,
  ) async {
    final sessionEntries = await _getSessionEntries(
      branchId: changes.branchId,
      academicSession: changes.academicSession,
    );
    final replacingIds = changes.entries.map((entry) => entry.id).toSet();
    final deletedIds = changes.deletedEntryIds.toSet();

    final retained = sessionEntries.where(
      (entry) =>
          !replacingIds.contains(entry.id) && !deletedIds.contains(entry.id),
    );

    for (final entry in changes.entries) {
      for (final existing in retained) {
        if (existing.weekday != entry.weekday ||
            existing.periodId != entry.periodId) {
          continue;
        }

        if (existing.classId == entry.classId &&
            existing.sectionId == entry.sectionId) {
          throw StateError(
            '${entry.className} - ${entry.sectionName} already has '
            'an assignment in ${entry.periodLabel}.',
          );
        }

        if (existing.teacherId == entry.teacherId) {
          throw StateError(
            '${entry.teacherName} is already assigned to '
            '${existing.className} - ${existing.sectionName} in '
            '${entry.periodLabel}.',
          );
        }
      }
    }

    final batch = firestoreService.instance.batch();
    final collection = firestoreService.collection(
      FirestorePaths.timetableEntries,
    );

    for (final id in changes.deletedEntryIds) {
      batch.delete(collection.doc(id));
    }

    for (final entry in changes.entries) {
      batch.set(
        collection.doc(entry.id),
        ClassTimetableEntryModel.fromEntity(entry).toMap(),
      );
    }

    await batch.commit();
  }

  @override
  Future<List<ClassTimetableEntryModel>> getAllTimetableEntries({
    required String branchId,
    required String academicSession,
  }) async {
    final entries = await _getSessionEntries(
      branchId: branchId,
      academicSession: academicSession,
    );

    entries.sort((first, second) {
      final teacherComparison = first.teacherName.compareTo(second.teacherName);
      if (teacherComparison != 0) {
        return teacherComparison;
      }

      final dayComparison = first.weekday.compareTo(second.weekday);
      if (dayComparison != 0) {
        return dayComparison;
      }

      return first.periodOrder.compareTo(second.periodOrder);
    });

    return List<ClassTimetableEntryModel>.unmodifiable(entries);
  }

  @override
  Future<List<ClassTimetableEntryModel>> getClassTimetable({
    required String branchId,
    required String academicSession,
    required String classId,
    required String sectionId,
  }) async {
    final entries = await _getSessionEntries(
      branchId: branchId,
      academicSession: academicSession,
    );

    final filtered =
        entries
            .where(
              (entry) =>
                  entry.classId == classId.trim() &&
                  entry.sectionId == sectionId.trim(),
            )
            .toList()
          ..sort((first, second) {
            final dayComparison = first.weekday.compareTo(second.weekday);
            if (dayComparison != 0) {
              return dayComparison;
            }
            return first.periodOrder.compareTo(second.periodOrder);
          });

    return List<ClassTimetableEntryModel>.unmodifiable(filtered);
  }

  @override
  Future<List<ClassTimetableEntryModel>> getTeacherTimetable({
    required String branchId,
    required String academicSession,
    required String teacherId,
  }) async {
    final entries = await _getSessionEntries(
      branchId: branchId,
      academicSession: academicSession,
    );

    final filtered =
        entries.where((entry) => entry.teacherId == teacherId.trim()).toList()
          ..sort((first, second) {
            final dayComparison = first.weekday.compareTo(second.weekday);
            if (dayComparison != 0) {
              return dayComparison;
            }
            return first.periodOrder.compareTo(second.periodOrder);
          });

    return List<ClassTimetableEntryModel>.unmodifiable(filtered);
  }

  @override
  Future<List<ClassTimetableEntryModel>> getDayTimetable({
    required String branchId,
    required String academicSession,
    required int weekday,
  }) async {
    final entries = await _getSessionEntries(
      branchId: branchId,
      academicSession: academicSession,
    );

    final filtered = entries.where((entry) => entry.weekday == weekday).toList()
      ..sort((first, second) {
        final periodComparison = first.periodOrder.compareTo(
          second.periodOrder,
        );
        if (periodComparison != 0) {
          return periodComparison;
        }
        final classComparison = compareAcademicClassNames(
          first.className,
          second.className,
        );
        if (classComparison != 0) {
          return classComparison;
        }
        return first.sectionName.compareTo(second.sectionName);
      });

    return List<ClassTimetableEntryModel>.unmodifiable(filtered);
  }

  @override
  Future<void> saveClassTimetableEntry(ClassTimetableEntryModel entry) async {
    final entries = await _getSessionEntries(
      branchId: entry.branchId,
      academicSession: entry.academicSession,
    );

    for (final existing in entries) {
      if (existing.id == entry.id ||
          existing.weekday != entry.weekday ||
          existing.periodId != entry.periodId) {
        continue;
      }

      final sameClassSlot =
          existing.classId == entry.classId &&
          existing.sectionId == entry.sectionId;
      if (sameClassSlot) {
        throw StateError(
          '${entry.className} - ${entry.sectionName} already has '
          '${existing.subjectName} in ${entry.periodLabel}.',
        );
      }

      if (existing.teacherId == entry.teacherId) {
        throw StateError(
          '${entry.teacherName} is already assigned to '
          '${existing.className} - ${existing.sectionName} '
          'in ${entry.periodLabel}.',
        );
      }
    }

    await firestoreService
        .collection(FirestorePaths.timetableEntries)
        .doc(entry.id)
        .set(entry.toMap());
  }

  @override
  Future<void> deleteClassTimetableEntry(String entryId) {
    return firestoreService
        .collection(FirestorePaths.timetableEntries)
        .doc(entryId.trim())
        .delete();
  }

  @override
  String generateClassTimetableEntryId() {
    return firestoreService
        .collection(FirestorePaths.timetableEntries)
        .doc()
        .id;
  }

  Future<List<ClassTimetableEntryModel>> _getSessionEntries({
    required String branchId,
    required String academicSession,
  }) async {
    final snapshot = await firestoreService
        .collection(FirestorePaths.timetableEntries)
        .where('branchId', isEqualTo: branchId.trim())
        .where('academicSession', isEqualTo: academicSession.trim())
        .get();

    return snapshot.docs
        .map(
          (document) => ClassTimetableEntryModel.fromMap({
            ...document.data(),
            'id': document.id,
          }),
        )
        .toList(growable: false);
  }
}
