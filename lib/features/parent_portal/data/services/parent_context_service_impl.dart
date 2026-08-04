import 'package:firebase_auth/firebase_auth.dart';

import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/parent_account_entity.dart';
import '../../domain/repositories/parent_portal_repository.dart';
import '../../domain/services/parent_context_service.dart';

class ParentContextServiceImpl extends ParentContextService {
  ParentContextServiceImpl(this._firebaseAuth, this._repository);

  final FirebaseAuth _firebaseAuth;
  final ParentPortalRepository _repository;

  bool _isLoading = false;
  bool _isLoaded = false;

  ParentAccountEntity? _currentParent;
  List<StudentEntity> _linkedStudents = const <StudentEntity>[];
  StudentEntity? _currentStudent;

  String? _errorMessage;

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isLoaded => _isLoaded;

  @override
  ParentAccountEntity? get currentParent => _currentParent;

  @override
  List<StudentEntity> get linkedStudents =>
      List<StudentEntity>.unmodifiable(_linkedStudents);

  @override
  StudentEntity? get currentStudent => _currentStudent;

  @override
  String? get errorMessage => _errorMessage;

  @override
  bool get hasParentAccount => _currentParent != null;

  @override
  bool get hasLinkedStudents => _linkedStudents.isNotEmpty;

  @override
  bool get canAccessPortal =>
      _currentParent?.canAccessParentPortal == true &&
      _linkedStudents.isNotEmpty;

  @override
  Future<void> loadCurrentParent({bool forceRefresh = false}) async {
    if (_isLoading) {
      return;
    }

    if (_isLoaded && !forceRefresh) {
      return;
    }

    final previousStudentId = _currentStudent?.id;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _firebaseAuth.currentUser;

      if (user == null) {
        _setFailure('No authenticated user is available.');
        return;
      }

      final parent = await _repository.getParentByUserId(user.uid);

      if (parent == null) {
        _setFailure(
          'No parent account is linked to this login. '
          'Please contact school administration.',
        );
        return;
      }

      if (parent.isBlocked) {
        _currentParent = parent;
        _setFailure(
          'This parent account has been blocked. '
          'Please contact school administration.',
        );
        return;
      }

      if (parent.isInactive || !parent.canAccessParentPortal) {
        _currentParent = parent;
        _setFailure(
          'This parent account is inactive. '
          'Please contact school administration.',
        );
        return;
      }

      final students = await _repository.getLinkedStudents(parent);

      _currentParent = parent;
      _linkedStudents = List<StudentEntity>.unmodifiable(students);

      if (_linkedStudents.isEmpty) {
        _currentStudent = null;
        _errorMessage = 'No active student is linked to this parent account.';
      } else {
        _currentStudent = _resolveSelectedStudent(previousStudentId);
      }

      _isLoaded = true;
    } catch (error) {
      _setFailure(_cleanError(error));
      return;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void selectStudent(String studentId) {
    final normalizedStudentId = studentId.trim();

    if (normalizedStudentId.isEmpty) {
      return;
    }

    for (final student in _linkedStudents) {
      if (student.id == normalizedStudentId) {
        if (_currentStudent?.id == student.id) {
          return;
        }

        _currentStudent = student;
        _errorMessage = null;
        notifyListeners();
        return;
      }
    }

    _errorMessage = 'You are not authorized to access this student.';
    notifyListeners();
  }

  @override
  bool canAccessStudent(String studentId) {
    final normalizedStudentId = studentId.trim();

    if (!canAccessPortal || normalizedStudentId.isEmpty) {
      return false;
    }

    return _linkedStudents.any(
      (student) => student.id == normalizedStudentId && student.isActive,
    );
  }

  @override
  Future<void> clear() async {
    _isLoading = false;
    _isLoaded = false;
    _currentParent = null;
    _linkedStudents = const <StudentEntity>[];
    _currentStudent = null;
    _errorMessage = null;

    notifyListeners();
  }

  StudentEntity _resolveSelectedStudent(String? previousStudentId) {
    if (previousStudentId != null && previousStudentId.trim().isNotEmpty) {
      for (final student in _linkedStudents) {
        if (student.id == previousStudentId) {
          return student;
        }
      }
    }

    return _linkedStudents.first;
  }

  void _setFailure(String message) {
    _linkedStudents = const <StudentEntity>[];
    _currentStudent = null;
    _errorMessage = message;
    _isLoaded = true;
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('StateError: ', '')
        .replaceFirst('Exception: ', '');
  }
}
