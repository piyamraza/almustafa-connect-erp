import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
              (document) => ParentAccountModel.fromMap({
                ...document.data(),
                'id': document.id,
              }),
            )
            .toList()
          ..sort(
            (first, second) => first.fullName.toLowerCase().compareTo(
              second.fullName.toLowerCase(),
            ),
          );

    return List<ParentAccountEntity>.unmodifiable(values);
  }

  @override
  Future<ParentAccountEntity?> getParentById(String id) async {
    final parentId = id.trim();

    if (parentId.isEmpty) {
      return null;
    }

    final snapshot = await _firestoreService
        .collection(FirestorePaths.parentAccounts)
        .doc(parentId)
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return ParentAccountModel.fromMap({...snapshot.data()!, 'id': snapshot.id});
  }

  @override
  Future<ParentAccountEntity?> getParentByUserId(String userId) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return null;
    }

    final snapshot = await _firestoreService
        .collection(FirestorePaths.parentAccounts)
        .where('userId', isEqualTo: normalizedUserId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final document = snapshot.docs.first;

    return ParentAccountModel.fromMap({...document.data(), 'id': document.id});
  }

  @override
  Future<List<StudentEntity>> getLinkedStudents(
    ParentAccountEntity parent,
  ) async {
    if (!parent.canAccessParentPortal) {
      return const <StudentEntity>[];
    }

    final linkedIds = parent.studentIds.toSet();

    if (linkedIds.isEmpty) {
      return const <StudentEntity>[];
    }

    // Parent accounts must never query the complete student directory. Fetch
    // only the explicitly linked records so Firestore can enforce per-student
    // access and no unrelated student data is exposed.
    final linkedStudents = await Future.wait(
      linkedIds.map(_studentRepository.getStudentById),
    );

    final students =
        linkedStudents
            .whereType<StudentEntity>()
            .where((student) => student.isActive)
            .toList()
          ..sort((first, second) {
            final classComparison = first.classId.toLowerCase().compareTo(
              second.classId.toLowerCase(),
            );

            if (classComparison != 0) {
              return classComparison;
            }

            return first.fullName.toLowerCase().compareTo(
              second.fullName.toLowerCase(),
            );
          });

    return List<StudentEntity>.unmodifiable(students);
  }

  @override
  Future<List<StudentEntity>> findStudentsByGuardian({
    required String mobileNumber,
    required String email,
  }) async {
    final phone = _normalizePhone(mobileNumber);
    final normalizedEmail = email.trim().toLowerCase();

    if (phone.isEmpty && normalizedEmail.isEmpty) {
      return const <StudentEntity>[];
    }

    final allStudents = await _studentRepository.getStudents();

    final students = allStudents.where((student) {
      if (!student.isActive) {
        return false;
      }

      final matchesPhone =
          phone.isNotEmpty &&
          <String>{
            student.fatherPhone,
            student.fatherWhatsapp,
            student.motherPhone,
            student.motherWhatsapp,
            student.guardianPhone,
            student.guardianWhatsapp,
          }.any((value) => _normalizePhone(value) == phone);

      final matchesEmail =
          normalizedEmail.isNotEmpty &&
          student.guardianEmail.trim().toLowerCase() == normalizedEmail;

      return matchesPhone || matchesEmail;
    }).toList();

    return List<StudentEntity>.unmodifiable(students);
  }

  @override
  Future<List<ParentAccountEntity>> getParentsForStudent(
    String studentId,
  ) async {
    final normalizedStudentId = studentId.trim();

    if (normalizedStudentId.isEmpty) {
      return const <ParentAccountEntity>[];
    }

    final snapshot = await _firestoreService
        .collection(FirestorePaths.parentAccounts)
        .where('studentIds', arrayContains: normalizedStudentId)
        .get();

    final parents =
        snapshot.docs
            .map(
              (document) => ParentAccountModel.fromMap({
                ...document.data(),
                'id': document.id,
              }),
            )
            .toList()
          ..sort((first, second) {
            if (first.isPrimaryContact != second.isPrimaryContact) {
              return first.isPrimaryContact ? -1 : 1;
            }

            return first.fullName.toLowerCase().compareTo(
              second.fullName.toLowerCase(),
            );
          });

    return List<ParentAccountEntity>.unmodifiable(parents);
  }

  @override
  Future<bool> isUserLinkedToAnotherParent(
    String userId, {
    String? excludingParentId,
  }) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return false;
    }

    final existing = await getParentByUserId(normalizedUserId);

    if (existing == null) {
      return false;
    }

    final excludedId = excludingParentId?.trim() ?? '';

    if (excludedId.isNotEmpty && existing.id == excludedId) {
      return false;
    }

    return true;
  }

  @override
  Future<bool> canParentAccessStudent({
    required String parentUserId,
    required String studentId,
  }) async {
    final normalizedUserId = parentUserId.trim();
    final normalizedStudentId = studentId.trim();

    if (normalizedUserId.isEmpty || normalizedStudentId.isEmpty) {
      return false;
    }

    final parent = await getParentByUserId(normalizedUserId);

    if (parent == null || !parent.canAccessParentPortal) {
      return false;
    }

    if (!parent.studentIds.contains(normalizedStudentId)) {
      return false;
    }

    final student = await _studentRepository.getStudentById(
      normalizedStudentId,
    );

    return student != null && student.isActive;
  }

  @override
  Future<void> saveParent(ParentAccountEntity parent) async {
    _validateParent(parent);

    if (parent.userId.trim().isNotEmpty) {
      final duplicateUser = await isUserLinkedToAnotherParent(
        parent.userId,
        excludingParentId: parent.id,
      );

      if (duplicateUser) {
        throw StateError(
          'This login is already linked with another parent account.',
        );
      }
    }

    final model = ParentAccountModel.fromEntity(parent);

    await _firestoreService
        .collection(FirestorePaths.parentAccounts)
        .doc(parent.id)
        .set(model.toMap());

    // Keep the RBAC assignment and the parent profile linked in both
    // directions. Parent portal security rules use linkedEntityId to prove
    // which student records this login is allowed to read.
    final authUserId = parent.userId.trim();
    if (authUserId.isNotEmpty) {
      await _firestoreService
          .collection(FirestorePaths.userRoleAssignments)
          .doc(authUserId)
          .set({
            'linkedEntityType': 'parent',
            'linkedEntityId': parent.id,
            'updatedAt': DateTime.now(),
          }, SetOptions(merge: true));
    }
  }

  @override
  Future<void> setParentStatus({
    required String parentId,
    required String accountStatus,
  }) async {
    final parent = await getParentById(parentId);

    if (parent == null) {
      throw StateError('Parent account was not found.');
    }

    final normalizedStatus = ParentAccountEntity.normalizeAccountStatus(
      accountStatus: accountStatus,
      isActive:
          accountStatus.trim().toLowerCase() ==
          ParentAccountEntity.accountStatusActive,
    );

    final updated = parent.copyWith(
      accountStatus: normalizedStatus,
      isActive: normalizedStatus == ParentAccountEntity.accountStatusActive,
      updatedAt: DateTime.now(),
    );

    await saveParent(updated);
  }

  @override
  Future<void> deleteParent(String id) async {
    final parentId = id.trim();

    if (parentId.isEmpty) {
      throw StateError('Parent account ID is required.');
    }

    await _firestoreService
        .collection(FirestorePaths.parentAccounts)
        .doc(parentId)
        .delete();
  }

  @override
  String generateId() {
    return _firestoreService.collection(FirestorePaths.parentAccounts).doc().id;
  }

  void _validateParent(ParentAccountEntity parent) {
    if (parent.id.trim().isEmpty) {
      throw StateError('Parent account ID is required.');
    }

    if (parent.fullName.trim().isEmpty) {
      throw StateError('Parent/guardian name is required.');
    }

    if (parent.mobileNumber.trim().isEmpty && parent.email.trim().isEmpty) {
      throw StateError('Mobile number or email address is required.');
    }

    if (parent.studentIds.isEmpty) {
      throw StateError('Link at least one student.');
    }

    final validStatuses = <String>{
      ParentAccountEntity.accountStatusActive,
      ParentAccountEntity.accountStatusInactive,
      ParentAccountEntity.accountStatusBlocked,
    };

    if (!validStatuses.contains(parent.normalizedAccountStatus)) {
      throw StateError('Invalid parent account status.');
    }
  }

  String _normalizePhone(String value) {
    var digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.startsWith('0092')) {
      digits = digits.substring(4);
    } else if (digits.startsWith('92')) {
      digits = digits.substring(2);
    }

    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    return digits;
  }
}
