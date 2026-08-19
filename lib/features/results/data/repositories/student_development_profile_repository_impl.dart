import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/student_development_profile_entity.dart';
import '../../domain/repositories/student_development_profile_repository.dart';

class StudentDevelopmentProfileRepositoryImpl
    implements StudentDevelopmentProfileRepository {
  StudentDevelopmentProfileRepositoryImpl(this._service);

  final FirebaseFirestoreService _service;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _service.collection(FirestorePaths.studentDevelopmentProfiles);

  @override
  Future<StudentDevelopmentProfileEntity?> getForStudent({
    required String examId,
    required String studentId,
  }) async {
    final id = StudentDevelopmentProfileEntity.documentIdFor(examId, studentId);
    final snapshot = await _collection.doc(id).get();
    if (snapshot.exists && snapshot.data() != null) {
      return _fromMap(snapshot.id, snapshot.data()!);
    }

    // Older records may have been saved with a generated/legacy document ID.
    // Resolve them by their actual fields so the result card does not lose
    // already-entered teacher ratings merely because the document key differs.
    final matches = await _collection
        .where('studentId', isEqualTo: studentId.trim())
        .get();
    for (final document in matches.docs) {
      final data = document.data();
      if ((data['examId'] as String? ?? '').trim() == examId.trim()) {
        return _fromMap(document.id, data);
      }
    }
    return null;
  }

  @override
  Future<List<StudentDevelopmentProfileEntity>> getForExam(
    String examId,
  ) async {
    final snapshot = await _collection.where('examId', isEqualTo: examId).get();
    return snapshot.docs.map((doc) => _fromMap(doc.id, doc.data())).toList();
  }

  @override
  Future<StudentDevelopmentProfileEntity?> getLatestForStudentSession({
    required String studentId,
    required String academicSession,
  }) async {
    final snapshot = await _collection
        .where('studentId', isEqualTo: studentId.trim())
        .get();
    final session = academicSession.trim().toLowerCase();
    final matches =
        snapshot.docs
            .map((document) => _fromMap(document.id, document.data()))
            .where(
              (profile) =>
                  profile.academicSession.trim().toLowerCase() == session &&
                  profile.isComplete,
            )
            .toList()
          ..sort((a, b) {
            final left = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final right = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return right.compareTo(left);
          });
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<void> saveAll(List<StudentDevelopmentProfileEntity> profiles) async {
    for (var start = 0; start < profiles.length; start += 500) {
      final end = (start + 500).clamp(0, profiles.length);
      final batch = _service.instance.batch();
      for (final profile in profiles.sublist(start, end)) {
        batch.set(_collection.doc(profile.id), _toMap(profile));
      }
      await batch.commit();
    }
  }

  StudentDevelopmentProfileEntity _fromMap(
    String id,
    Map<String, dynamic> map,
  ) => StudentDevelopmentProfileEntity(
    id: id,
    examId: map['examId'] as String? ?? '',
    academicSession: map['academicSession'] as String? ?? '',
    studentId: map['studentId'] as String? ?? '',
    classId: map['classId'] as String? ?? '',
    sectionId: map['sectionId'] as String? ?? '',
    discipline: (map['discipline'] as num?)?.toInt() ?? 0,
    communication: (map['communication'] as num?)?.toInt() ?? 0,
    classParticipation: (map['classParticipation'] as num?)?.toInt() ?? 0,
    homework: (map['homework'] as num?)?.toInt() ?? 0,
    personalHygiene: (map['personalHygiene'] as num?)?.toInt() ?? 0,
    updatedBy: map['updatedBy'] as String? ?? '',
    updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
  );

  Map<String, dynamic> _toMap(StudentDevelopmentProfileEntity value) => {
    'examId': value.examId,
    'academicSession': value.academicSession,
    'studentId': value.studentId,
    'classId': value.classId,
    'sectionId': value.sectionId,
    'discipline': value.discipline.clamp(1, 5),
    'communication': value.communication.clamp(1, 5),
    'classParticipation': value.classParticipation.clamp(1, 5),
    'homework': value.homework.clamp(1, 5),
    'personalHygiene': value.personalHygiene.clamp(1, 5),
    'updatedBy': value.updatedBy,
    'updatedAt': Timestamp.fromDate(value.updatedAt ?? DateTime.now()),
  };
}
