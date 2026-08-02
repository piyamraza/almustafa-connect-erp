import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../../domain/entities/parent_account_entity.dart';
import '../../domain/repositories/parent_portal_repository.dart';
import '../models/parent_account_model.dart';

class ParentPortalRepositoryImpl implements ParentPortalRepository {
  const ParentPortalRepositoryImpl(
    this._firestoreService,
    this._studentRepository,
  );

  final FirebaseFirestoreService _firestoreService;
  final StudentRepository _studentRepository;

  @override
  Future<List<ParentAccountEntity>> getParents() async {
    final snapshot = await _firestoreService
        .collection(FirestorePaths.parentAccounts)
        .get();

    final values =
        snapshot.docs
            .map(
              (doc) =>
                  ParentAccountModel.fromMap({...doc.data(), 'id': doc.id}),
            )
            .toList()
          ..sort(
            (a, b) =>
                a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
          );

    return List.unmodifiable(values);
  }

  @override
  Future<ParentAccountEntity?> getParentById(String id) async {
    final snapshot = await _firestoreService
        .collection(FirestorePaths.parentAccounts)
        .doc(id)
        .get();

    if (!snapshot.exists || snapshot.data() == null) return null;

    return ParentAccountModel.fromMap({...snapshot.data()!, 'id': snapshot.id});
  }

  @override
  Future<List<StudentEntity>> getLinkedStudents(
    ParentAccountEntity parent,
  ) async {
    final allStudents = await _studentRepository.getStudents();

    return allStudents
        .where(
          (student) =>
              parent.studentIds.contains(student.id) && student.isActive,
        )
        .toList(growable: false);
  }

  @override
  Future<List<StudentEntity>> findStudentsByGuardian({
    required String mobileNumber,
    required String email,
  }) async {
    final phone = _normalizePhone(mobileNumber);
    final normalizedEmail = email.trim().toLowerCase();
    final allStudents = await _studentRepository.getStudents();

    return allStudents
        .where((student) {
          final matchesPhone =
              phone.isNotEmpty &&
              <String>{
                student.fatherPhone,
                student.motherPhone,
                student.guardianPhone,
              }.any((value) => _normalizePhone(value) == phone);
          final matchesEmail =
              normalizedEmail.isNotEmpty &&
              student.guardianEmail.trim().toLowerCase() == normalizedEmail;

          return student.isActive && (matchesPhone || matchesEmail);
        })
        .toList(growable: false);
  }

  /// Converts common Pakistani phone-number formats to one comparable value.
  /// For example 03366328402, +923366328402 and 00923366328402 all match.
  String _normalizePhone(String value) {
    var digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0092')) {
      digits = digits.substring(4);
    } else if (digits.startsWith('92')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits;
  }

  @override
  Future<void> saveParent(ParentAccountEntity parent) async {
    if (parent.fullName.trim().isEmpty) {
      throw StateError('Parent/guardian name is required.');
    }

    if (parent.mobileNumber.trim().isEmpty && parent.email.trim().isEmpty) {
      throw StateError('Mobile number or email address is required.');
    }

    if (parent.studentIds.isEmpty) {
      throw StateError('Link at least one student.');
    }

    await _firestoreService
        .collection(FirestorePaths.parentAccounts)
        .doc(parent.id)
        .set(ParentAccountModel.fromEntity(parent).toMap());
  }

  @override
  Future<void> deleteParent(String id) {
    return _firestoreService
        .collection(FirestorePaths.parentAccounts)
        .doc(id)
        .delete();
  }

  @override
  String generateId() {
    return _firestoreService.collection(FirestorePaths.parentAccounts).doc().id;
  }
}
