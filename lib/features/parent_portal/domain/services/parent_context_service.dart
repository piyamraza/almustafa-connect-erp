import 'package:flutter/foundation.dart';

import '../../../students/domain/entities/student_entity.dart';
import '../entities/parent_account_entity.dart';

abstract class ParentContextService extends ChangeNotifier {
  bool get isLoading;

  bool get isLoaded;

  ParentAccountEntity? get currentParent;

  List<StudentEntity> get linkedStudents;

  StudentEntity? get currentStudent;

  String? get errorMessage;

  bool get hasParentAccount;

  bool get hasLinkedStudents;

  bool get canAccessPortal;

  Future<void> loadCurrentParent({bool forceRefresh = false});

  void selectStudent(String studentId);

  bool canAccessStudent(String studentId);

  Future<void> clear();
}
