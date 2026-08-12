import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/app_permission.dart';
import '../../domain/entities/app_role_entity.dart';
import '../../domain/repositories/app_role_repository.dart';
import '../models/app_role_model.dart';

class AppRoleRepositoryImpl implements AppRoleRepository {
  const AppRoleRepositoryImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<List<AppRoleEntity>> getRoles() async {
    final snapshot = await _service.collection(FirestorePaths.appRoles).get();

    final values =
        snapshot.docs
            .map((doc) => AppRoleModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    return List.unmodifiable(values);
  }

  @override
  Future<void> saveRole(AppRoleEntity role) async {
    if (role.name.trim().isEmpty) {
      throw StateError('Role name is required.');
    }
    if (role.permissions.isEmpty) {
      throw StateError('Select at least one permission.');
    }

    await _service
        .collection(FirestorePaths.appRoles)
        .doc(role.id)
        .set(AppRoleModel.fromEntity(role).toMap());
  }

  @override
  Future<void> deleteRole(String id) async {
    final roles = await getRoles();
    final role = roles.where((item) => item.id == id).firstOrNull;

    if (role?.isSystemRole ?? false) {
      throw StateError('System roles cannot be deleted.');
    }

    await _service.collection(FirestorePaths.appRoles).doc(id).delete();
  }

  @override
  Future<void> seedDefaultRoles() async {
    final existing = await getRoles();
    final existingIds = existing.map((role) => role.id).toSet();
    final now = DateTime.now();

    for (final role in _defaultRoles(now)) {
      if (!existingIds.contains(role.id)) {
        await saveRole(role);
      }
    }
  }

  @override
  String generateId() => _service.collection(FirestorePaths.appRoles).doc().id;

  List<AppRoleEntity> _defaultRoles(DateTime now) => [
    AppRoleEntity(
      id: 'super_admin',
      name: 'Super Admin',
      description: 'Complete access to all ERP modules and actions.',
      permissions: AppPermission.values,
      isSystemRole: true,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    AppRoleEntity(
      id: 'school_admin',
      name: 'School Admin',
      description: 'Operational administration with full school-wide access.',
      permissions: AppPermission.values
          .where((permission) => permission != AppPermission.auditLogsView)
          .toList(),
      isSystemRole: true,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    AppRoleEntity(
      id: 'principal',
      name: 'Principal',
      description: 'School-wide monitoring, approvals and reports.',
      permissions: [
        AppPermission.studentsView,
        AppPermission.teachersView,
        AppPermission.staffView,
        AppPermission.classesView,
        AppPermission.attendanceView,
        AppPermission.feesView,
        AppPermission.feesReports,
        AppPermission.examsView,
        AppPermission.dateSheetsView,
        AppPermission.resultsView,
        AppPermission.resultsPublish,
        AppPermission.timetableView,
        AppPermission.homeworkView,
        AppPermission.noticesView,
        AppPermission.noticesManage,
        AppPermission.calendarView,
        AppPermission.parentsView,
        AppPermission.reportsView,
        AppPermission.reportsExport,
      ],
      isSystemRole: true,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    AppRoleEntity(
      id: 'teacher',
      name: 'Teacher',
      description: 'Assigned classes, attendance, homework and result entry.',
      permissions: [
        AppPermission.studentsView,
        AppPermission.attendanceView,
        AppPermission.attendanceMark,
        AppPermission.examsView,
        AppPermission.examsManage,
        AppPermission.dateSheetsView,
        AppPermission.resultsView,
        AppPermission.resultsEnter,
        AppPermission.timetableView,
        AppPermission.homeworkView,
        AppPermission.homeworkCreate,
        AppPermission.noticesView,
        AppPermission.calendarView,
      ],
      isSystemRole: true,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    AppRoleEntity(
      id: 'cashier',
      name: 'Cashier / Accountant',
      description: 'Fee collection, challans, receipts and financial reports.',
      permissions: [
        AppPermission.studentsView,
        AppPermission.feesView,
        AppPermission.feesCollect,
        AppPermission.feesReports,
        AppPermission.reportsView,
        AppPermission.reportsExport,
      ],
      isSystemRole: true,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    AppRoleEntity(
      id: 'receptionist',
      name: 'Receptionist',
      description: 'Student directory, basic attendance and parent support.',
      permissions: [
        AppPermission.studentsView,
        AppPermission.studentsCreate,
        AppPermission.studentsEdit,
        AppPermission.attendanceView,
        AppPermission.parentsView,
        AppPermission.parentsManage,
        AppPermission.noticesView,
        AppPermission.calendarView,
      ],
      isSystemRole: true,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    AppRoleEntity(
      id: 'parent',
      name: 'Parent',
      description: 'Read-only access to linked children and communication.',
      permissions: [
        AppPermission.attendanceView,
        AppPermission.feesView,
        AppPermission.dateSheetsView,
        AppPermission.resultsView,
        AppPermission.timetableView,
        AppPermission.homeworkView,
        AppPermission.noticesView,
        AppPermission.calendarView,
        AppPermission.parentsView,
      ],
      isSystemRole: true,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    AppRoleEntity(
      id: 'student',
      name: 'Student',
      description: 'Read-only academic access and homework submission.',
      permissions: [
        AppPermission.attendanceView,
        AppPermission.dateSheetsView,
        AppPermission.resultsView,
        AppPermission.timetableView,
        AppPermission.homeworkView,
        AppPermission.noticesView,
        AppPermission.calendarView,
      ],
      isSystemRole: true,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}
