import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/service_locator.dart';
import '../../data/services/user_account_service_impl.dart';
import '../../domain/entities/app_role_entity.dart';
import '../../domain/entities/user_account_entity.dart';
import '../../domain/repositories/app_role_repository.dart';
import '../../domain/services/user_account_service.dart';
import '../../../teachers/domain/repositories/teacher_repository.dart';
import '../../../staff/domain/repositories/staff_repository.dart';
import '../../../parent_portal/domain/repositories/parent_portal_repository.dart';

const _pageBackground = Color(0xFFF3F6FB);
const _textPrimary = Color(0xFF182230);

class UserAccountsManagementPage extends StatefulWidget {
  const UserAccountsManagementPage({super.key});

  @override
  State<UserAccountsManagementPage> createState() =>
      _UserAccountsManagementPageState();
}

class _UserAccountsManagementPageState
    extends State<UserAccountsManagementPage> {
  late final UserAccountService _service;
  final _search = TextEditingController();

  List<UserAccountEntity> _accounts = const [];
  List<AppRoleEntity> _roles = const [];
  bool _loading = true;
  String _query = '';
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _service = UserAccountServiceImpl();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<AppRoleEntity>> _loadActiveRoles() async {
    final repository = sl<AppRoleRepository>();
    var roles = await repository.getRoles();
    if (!roles.any((role) => role.isActive)) {
      try {
        await repository.seedDefaultRoles();
      } catch (_) {
        await _service.bootstrapAdministration();
        await repository.seedDefaultRoles();
      }
      roles = await repository.getRoles();
    }
    return roles.where((role) => role.isActive).toList(growable: false);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      var roles = await _loadActiveRoles();
      List<UserAccountEntity> accounts;
      try {
        accounts = await _service.listAccounts();
      } on FirebaseFunctionsException catch (error) {
        if (error.code != 'permission-denied') rethrow;
        await _service.bootstrapAdministration();
        roles = await _loadActiveRoles();
        accounts = await _service.listAccounts();
      }

      if (!mounted) return;

      setState(() {
        _accounts = accounts;
        _roles = roles;
      });
    } catch (error) {
      if (!mounted) return;
      final message = _message(error);
      setState(() => _loadError = message);
      _show(message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<UserAccountEntity> get _visibleAccounts {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _accounts;

    return _accounts
        .where((account) {
          return account.displayName.toLowerCase().contains(query) ||
              account.email.toLowerCase().contains(query) ||
              account.username.toLowerCase().contains(query) ||
              account.roleName.toLowerCase().contains(query) ||
              account.roleNames.any(
                (role) => role.toLowerCase().contains(query),
              );
        })
        .toList(growable: false);
  }

  Future<void> _createAccount() async {
    if (_roles.isEmpty) {
      _show(
        _loadError ??
            'Active roles could not be loaded. Refresh this page and try again.',
      );
      return;
    }

    final linkedRecords = await _loadLinkedRecords();
    if (!mounted) return;

    final request = await showDialog<_CreateAccountRequest>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _CreateUserDialog(roles: _roles, linkedRecords: linkedRecords),
    );

    if (request == null || !mounted) return;

    setState(() => _loading = true);

    try {
      final created = await _service.createAccount(
        displayName: request.displayName,
        login: request.login,
        password: request.password,
        roleId: request.role.id,
        roleName: request.role.name,
        branchId: request.branchId,
        linkedEntityType: request.linkedEntityType,
        linkedEntityId: request.linkedEntityId,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('User Account Created'),
          content: SelectableText(
            'Name: ${created.displayName}\n'
            'Username: ${created.username.isEmpty ? '-' : created.username}\n'
            'Login Email: ${created.email}\n'
            'Temporary Password: ${request.password}\n'
            'Role: ${created.roleName}\n'
            'Firebase UID: ${created.uid}\n\n'
            'Give these credentials to the user securely. '
            'The password is not stored in Firestore.',
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(
                    text:
                        'Login: ${created.username.isEmpty ? created.email : created.username}\n'
                        'Email: ${created.email}\n'
                        'Temporary Password: ${request.password}',
                  ),
                );
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Credentials copied.')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Credentials'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );

      await _load();
    } catch (error) {
      if (!mounted) return;
      _show(_message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<_LinkedRecordOption>> _loadLinkedRecords({String? includeId}) async {
    final teachersFuture = sl<TeacherRepository>().getTeachers();
    final staffFuture = sl<StaffRepository>().getStaff();
    final parentsFuture = sl<ParentPortalRepository>().getParents();
    final teachers = await teachersFuture;
    final staff = await staffFuture;
    final parents = await parentsFuture;
    final alreadyLinkedIds = _accounts
        .map((account) => account.linkedEntityId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    return <_LinkedRecordOption>[
      for (final teacher in teachers)
        if (teacher.isActive &&
            (!alreadyLinkedIds.contains(teacher.id) || teacher.id == includeId))
          _LinkedRecordOption(
            type: 'teacher',
            id: teacher.id,
            label: '${teacher.fullName} • ${teacher.employeeId}',
            displayName: teacher.fullName,
            login: teacher.email.trim().isNotEmpty
                ? teacher.email
                : teacher.phone,
          ),
      for (final member in staff)
        if (member.isActive &&
            (!alreadyLinkedIds.contains(member.id) || member.id == includeId))
          _LinkedRecordOption(
            type: 'staff',
            id: member.id,
            label:
                '${member.fullName} • ${member.staffId} • ${member.designation}',
            displayName: member.fullName,
            login: member.phone,
          ),
      for (final parent in parents)
        if (parent.canAccessParentPortal &&
            (parent.userId.trim().isEmpty || parent.id == includeId) &&
            (!alreadyLinkedIds.contains(parent.id) || parent.id == includeId))
          _LinkedRecordOption(
            type: 'parent',
            id: parent.id,
            label:
                '${parent.fullName} • ${parent.mobileNumber} • ${parent.studentIds.length} student(s)',
            displayName: parent.fullName,
            login: parent.email.trim().isNotEmpty
                ? parent.email
                : parent.mobileNumber,
          ),
    ];
  }

  Future<void> _toggleAccount(UserAccountEntity account) async {
    final disable = !account.disabled;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              disable ? 'Disable User Account' : 'Enable User Account',
            ),
            content: Text(
              '${disable ? 'Disable' : 'Enable'} '
              '${account.displayName.isEmpty ? account.email : account.displayName}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(disable ? 'Disable' : 'Enable'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    setState(() => _loading = true);

    try {
      await _service.setDisabled(uid: account.uid, disabled: disable);
      await _load();
      _show(disable ? 'User account disabled.' : 'User account enabled.');
    } catch (error) {
      if (!mounted) return;
      _show(_message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteAccount(UserAccountEntity account) async {
    final accountName = account.displayName.isEmpty
        ? account.email
        : account.displayName;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(
              Icons.delete_forever_rounded,
              color: Colors.red,
              size: 40,
            ),
            title: const Text('Delete User Account?'),
            content: Text(
              '$accountName (${account.email}) will permanently lose access. '
              'This removes the login account and its role assignment.\n\n'
              'This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text('Delete Account'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;
    setState(() => _loading = true);
    try {
      await _service.deleteAccount(uid: account.uid);
      await _load();
      _show('User account deleted permanently.');
    } catch (error) {
      if (mounted) _show(_message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editAccount(UserAccountEntity account) async {
    final linkedRecords = await _loadLinkedRecords(
      includeId: account.linkedEntityId,
    );
    if (!mounted) return;
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: account.displayName);
    final login = TextEditingController(
      text: account.username.isEmpty ? account.email : account.username,
    );
    final branch = TextEditingController(text: account.branchId);
    var linkedType = account.linkedEntityType;
    _LinkedRecordOption? linkedRecord;
    for (final option in linkedRecords) {
      if (option.type == linkedType && option.id == account.linkedEntityId) {
        linkedRecord = option;
        break;
      }
    }

    final confirmed =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('Edit User Account'),
              content: SizedBox(
                width: 520,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: name,
                          decoration: const InputDecoration(
                            labelText: 'Display Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Display name is required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: login,
                          decoration: const InputDecoration(
                            labelText: 'Username / Mobile / Email',
                            helperText:
                                'Changing this also changes login credentials.',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Login is required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: branch,
                          decoration: const InputDecoration(
                            labelText: 'Branch ID',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: linkedType,
                          decoration: const InputDecoration(
                            labelText: '1. Link Account To',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: '',
                              child: Text('System user / no profile'),
                            ),
                            DropdownMenuItem(
                              value: 'parent',
                              child: Text('Parent'),
                            ),
                            DropdownMenuItem(
                              value: 'teacher',
                              child: Text('Teacher'),
                            ),
                            DropdownMenuItem(
                              value: 'staff',
                              child: Text('Staff'),
                            ),
                          ],
                          onChanged: (value) => setDialogState(() {
                            linkedType = value ?? '';
                            linkedRecord = null;
                          }),
                        ),
                        if (linkedType.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<_LinkedRecordOption>(
                            key: ValueKey(
                              'edit-$linkedType-${linkedRecord?.id ?? ''}',
                            ),
                            initialValue: linkedRecord,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: '2. Select ${_linkTypeLabel(linkedType)}',
                              border: const OutlineInputBorder(),
                            ),
                            items: linkedRecords
                                .where((option) => option.type == linkedType)
                                .map(
                                  (option) => DropdownMenuItem(
                                    value: option,
                                    child: Text(
                                      option.label,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            validator: (value) => value == null
                                ? 'Select the actual ${_linkTypeLabel(linkedType).toLowerCase()} record'
                                : null,
                            onChanged: (value) => setDialogState(() {
                              linkedRecord = value;
                              if (value != null) {
                                name.text = value.displayName;
                                if (value.login.trim().isNotEmpty) {
                                  login.text = value.login;
                                }
                              }
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(dialogContext, true);
                    }
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (confirmed && mounted) {
      setState(() => _loading = true);
      try {
        await _service.updateAccount(
          uid: account.uid,
          displayName: name.text.trim(),
          login: login.text.trim(),
          branchId: branch.text.trim().isEmpty ? 'main' : branch.text.trim(),
          linkedEntityType: linkedType,
          linkedEntityId: linkedType.isEmpty ? '' : linkedRecord!.id,
        );
        await _load();
        _show('User account updated successfully.');
      } catch (error) {
        if (mounted) _show(_message(error));
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }

    name.dispose();
    login.dispose();
    branch.dispose();
  }

  Future<void> _changeRole(UserAccountEntity account) async {
    final selectedIds = <String>{
      ...(account.roleIds.isEmpty ? <String>[account.roleId] : account.roleIds),
    }..removeWhere((id) => id.isEmpty);
    String? primaryRoleId = account.roleId.isEmpty ? null : account.roleId;
    final branch = TextEditingController(text: account.branchId);

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: Text('Assign Roles — ${account.displayName}'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Select one or more roles'),
                      ),
                      ..._roles.map(
                        (role) => CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(role.name),
                          value: selectedIds.contains(role.id),
                          onChanged: (checked) => setDialogState(() {
                            if (checked == true) {
                              selectedIds.add(role.id);
                              primaryRoleId ??= role.id;
                            } else {
                              selectedIds.remove(role.id);
                              if (primaryRoleId == role.id)
                                primaryRoleId = selectedIds.firstOrNull;
                            }
                          }),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedIds.contains(primaryRoleId)
                            ? primaryRoleId
                            : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Primary Role (main workspace)',
                          border: OutlineInputBorder(),
                        ),
                        items: _roles
                            .where((role) => selectedIds.contains(role.id))
                            .map(
                              (role) => DropdownMenuItem(
                                value: role.id,
                                child: Text(role.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setDialogState(() => primaryRoleId = value),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: branch,
                        decoration: const InputDecoration(
                          labelText: 'Branch ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: selectedIds.isEmpty || primaryRoleId == null
                      ? null
                      : () => Navigator.pop(dialogContext, true),
                  child: const Text('Save Roles'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!confirmed ||
        selectedIds.isEmpty ||
        primaryRoleId == null ||
        !mounted) {
      branch.dispose();
      return;
    }

    setState(() => _loading = true);

    try {
      await _service.updateRole(
        uid: account.uid,
        roleIds: selectedIds.toList(),
        primaryRoleId: primaryRoleId!,
        branchId: branch.text.trim().isEmpty ? 'main' : branch.text.trim(),
      );
      await _load();
      _show('User roles and primary workspace updated.');
    } catch (error) {
      if (!mounted) return;
      _show(_message(error));
    } finally {
      branch.dispose();
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword(UserAccountEntity account) async {
    if (account.email.isEmpty) {
      _show('This user has no email address.');
      return;
    }

    setState(() => _loading = true);

    try {
      final link = await _service.generatePasswordResetLink(account.email);

      if (!mounted) return;

      await Clipboard.setData(ClipboardData(text: link));
      _show('Password reset link copied to clipboard.');
    } catch (error) {
      if (!mounted) return;
      _show(_message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _message(Object error) {
    if (error is FirebaseFunctionsException) {
      if (error.code == 'not-found' || error.code == 'unimplemented') {
        return 'User-account Cloud Functions are not deployed. Deploy the '
            'functions backend and refresh this page.';
      }
      if (error.code == 'internal') {
        return 'User-account backend is unavailable or not configured for '
            'this Firebase project. Deploy the Functions backend, then retry.';
      }
      return error.message ?? error.code;
    }

    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('StateError: ', '');
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleAccounts;
    final compact = MediaQuery.sizeOf(context).width < 650;

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        actions: const [DashboardNavigationButton()],
        title: const Text('User Accounts Management'),
      ),
      floatingActionButton: compact
          ? FloatingActionButton(
              onPressed: _loading || _roles.isEmpty ? null : _createAccount,
              tooltip: 'Create user',
              child: const Icon(Icons.person_add_alt_1),
            )
          : FloatingActionButton.extended(
              onPressed: _loading || _roles.isEmpty ? null : _createAccount,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Create User'),
            ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
            children: [
              if (_loadError != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_loadError!)),
                      TextButton(
                        onPressed: _loading ? null : _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              _buildHeader(),
              const SizedBox(height: 14),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final search = TextField(
                        controller: _search,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: const InputDecoration(
                          labelText: 'Search name, username, email or role',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      );
                      final refresh = FilledButton.tonalIcon(
                        onPressed: _loading ? null : _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      );
                      if (constraints.maxWidth < 560) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            search,
                            const SizedBox(height: 10),
                            refresh,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: search),
                          const SizedBox(width: 12),
                          refresh,
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('Total: ${_accounts.length}')),
                  Chip(
                    label: Text(
                      'Active: ${_accounts.where((item) => !item.disabled).length}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Disabled: ${_accounts.where((item) => item.disabled).length}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Without Role: ${_accounts.where((item) => item.roleId.isEmpty).length}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: Text('No user accounts found.')),
                  ),
                )
              else
                for (final account in visible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _UserAccountCard(
                      account: account,
                      onEdit: () => _editAccount(account),
                      onToggle: () => _toggleAccount(account),
                      onChangeRole: () => _changeRole(account),
                      onResetPassword: () => _resetPassword(account),
                      onDelete: () => _deleteAccount(account),
                    ),
                  ),
            ],
          ),
          if (_loading) const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B63CE), Color(0xFF7C3AED), Color(0xFFDB2777)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.admin_panel_settings_outlined,
            color: Colors.white,
            size: 42,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Firebase User Accounts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Create login credentials, assign roles, reset passwords and control account access.',
                  style: TextStyle(color: Color(0xFFF3E8FF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateAccountRequest {
  const _CreateAccountRequest({
    required this.displayName,
    required this.login,
    required this.password,
    required this.role,
    required this.branchId,
    required this.linkedEntityType,
    required this.linkedEntityId,
  });

  final String displayName;
  final String login;
  final String password;
  final AppRoleEntity role;
  final String branchId;
  final String linkedEntityType;
  final String linkedEntityId;
}

class _LinkedRecordOption {
  const _LinkedRecordOption({
    required this.type,
    required this.id,
    required this.label,
    required this.displayName,
    required this.login,
  });

  final String type;
  final String id;
  final String label;
  final String displayName;
  final String login;
}

String _linkTypeLabel(String type) => switch (type) {
  'teacher' => 'Teacher',
  'staff' => 'Staff Member',
  'parent' => 'Parent',
  _ => 'Record',
};

class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog({required this.roles, required this.linkedRecords});

  final List<AppRoleEntity> roles;
  final List<_LinkedRecordOption> linkedRecords;

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _login = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _branch = TextEditingController(text: 'main');

  AppRoleEntity? _role;
  String _linkedType = '';
  _LinkedRecordOption? _linkedRecord;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _login.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _branch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create User Account'),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 285,
                  child: DropdownButtonFormField<String>(
                    initialValue: _linkedType,
                    decoration: const InputDecoration(
                      labelText: '1. Link Account To',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: '',
                        child: Text('System user (no profile link)'),
                      ),
                      DropdownMenuItem(
                        value: 'teacher',
                        child: Text('Teacher'),
                      ),
                      DropdownMenuItem(value: 'staff', child: Text('Staff')),
                      DropdownMenuItem(value: 'parent', child: Text('Parent')),
                    ],
                    onChanged: _selectLinkedType,
                  ),
                ),
                SizedBox(
                  width: 285,
                  child: DropdownButtonFormField<_LinkedRecordOption>(
                    key: ValueKey(_linkedType),
                    initialValue: _linkedRecord,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: _linkedType.isEmpty
                          ? '2. Select profile'
                          : '2. Select ${_linkedTypeLabel()}',
                      border: const OutlineInputBorder(),
                    ),
                    items: _recordsForSelectedType
                        .map(
                          (record) => DropdownMenuItem(
                            value: record,
                            child: Text(
                              record.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _linkedType.isEmpty ? null : _selectRecord,
                    validator: (value) =>
                        _linkedType.isNotEmpty && value == null
                        ? 'Select the $_linkedType record'
                        : null,
                  ),
                ),
                _field(
                  controller: _name,
                  label: 'Display Name',
                  validator: _required,
                ),
                _field(
                  controller: _login,
                  label: 'Username / Mobile / Email',
                  helper:
                      'Username or mobile is converted to a secure internal login',
                  validator: _required,
                ),
                _field(
                  controller: _password,
                  label: 'Temporary Password',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  validator: (value) {
                    if ((value ?? '').length < 6) {
                      return 'Minimum 6 characters required';
                    }
                    return null;
                  },
                ),
                _field(
                  controller: _confirmPassword,
                  label: 'Confirm Password',
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value != _password.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(
                  width: 285,
                  child: DropdownButtonFormField<AppRoleEntity>(
                    key: ValueKey('role-${_role?.id ?? ''}'),
                    initialValue: _role,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.roles
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Text(role.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _role = value),
                    validator: (value) =>
                        value == null ? 'Role is required' : null,
                  ),
                ),
                _field(
                  controller: _branch,
                  label: 'Branch ID',
                  validator: _required,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Create User'),
        ),
      ],
    );
  }

  List<_LinkedRecordOption> get _recordsForSelectedType => widget.linkedRecords
      .where((record) => record.type == _linkedType)
      .toList(growable: false);

  String _linkedTypeLabel() => switch (_linkedType) {
    'teacher' => 'teacher',
    'staff' => 'staff member',
    'parent' => 'parent/guardian',
    _ => 'profile',
  };

  void _selectLinkedType(String? value) {
    final type = value ?? '';
    final matchingRole = widget.roles.where((role) => role.id == type);
    setState(() {
      _linkedType = type;
      _linkedRecord = null;
      if (matchingRole.isNotEmpty) _role = matchingRole.first;
      if (type.isEmpty) return;
      _name.clear();
      _login.clear();
    });
  }

  void _selectRecord(_LinkedRecordOption? record) {
    setState(() {
      _linkedRecord = record;
      if (record == null) return;
      _name.text = record.displayName;
      _login.text = record.login;
    });
  }

  SizedBox _field({
    required TextEditingController controller,
    required String label,
    String? helper,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      width: 285,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          suffixIcon: suffixIcon,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? 'This field is required'
        : null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _role == null) return;

    Navigator.pop(
      context,
      _CreateAccountRequest(
        displayName: _name.text.trim(),
        login: _login.text.trim(),
        password: _password.text,
        role: _role!,
        branchId: _branch.text.trim(),
        linkedEntityType: _linkedType,
        linkedEntityId: _linkedRecord?.id ?? '',
      ),
    );
  }
}

class _UserAccountCard extends StatelessWidget {
  const _UserAccountCard({
    required this.account,
    required this.onEdit,
    required this.onToggle,
    required this.onChangeRole,
    required this.onResetPassword,
    required this.onDelete,
  });

  final UserAccountEntity account;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onChangeRole;
  final VoidCallback onResetPassword;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final activeColor = account.disabled
        ? const Color(0xFFDC2626)
        : const Color(0xFF059669);

    return Card(
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        leading: CircleAvatar(
          backgroundColor: activeColor.withValues(alpha: .12),
          child: Icon(
            account.disabled ? Icons.person_off_outlined : Icons.person_outline,
            color: activeColor,
          ),
        ),
        title: Text(
          account.displayName.isEmpty ? account.email : account.displayName,
          style: const TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          '${account.username.isEmpty ? account.email : account.username} • '
          '${account.roleNames.isEmpty ? account.roleName : account.roleNames.join(', ')} • Branch ${account.branchId}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Wrap(
          spacing: 5,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
              avatar: Icon(
                account.disabled ? Icons.block : Icons.check_circle_outline,
                size: 17,
              ),
              label: Text(account.disabled ? 'DISABLED' : 'ACTIVE'),
            ),
            PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'edit':
                    onEdit();
                  case 'role':
                    onChangeRole();
                  case 'password':
                    onResetPassword();
                  case 'toggle':
                    onToggle();
                  case 'delete':
                    onDelete();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Account')),
                const PopupMenuItem(value: 'role', child: Text('Assign Roles')),
                const PopupMenuItem(
                  value: 'password',
                  child: Text('Copy Password Reset Link'),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(
                    account.disabled ? 'Enable Account' : 'Disable Account',
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever_rounded, color: Colors.red),
                      SizedBox(width: 10),
                      Text(
                        'Delete Account',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
