import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/app_role_entity.dart';
import '../../domain/entities/user_role_assignment_entity.dart';
import '../../domain/repositories/app_role_repository.dart';

class UserRoleAssignmentFormPage extends StatefulWidget {
  const UserRoleAssignmentFormPage({super.key, this.existing});

  final UserRoleAssignmentEntity? existing;

  @override
  State<UserRoleAssignmentFormPage> createState() =>
      _UserRoleAssignmentFormPageState();
}

class _UserRoleAssignmentFormPageState
    extends State<UserRoleAssignmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _userId;
  late final TextEditingController _userName;
  late final TextEditingController _email;
  late final TextEditingController _branchId;
  List<AppRoleEntity> _roles = const [];
  String? _roleId;
  bool _isActive = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;

    _userId = TextEditingController(text: existing?.userId ?? '');
    _userName = TextEditingController(text: existing?.userName ?? '');
    _email = TextEditingController(text: existing?.email ?? '');
    _branchId = TextEditingController(text: existing?.branchId ?? 'main');
    _roleId = existing?.roleId;
    _isActive = existing?.isActive ?? true;

    _loadRoles();
  }

  @override
  void dispose() {
    _userId.dispose();
    _userName.dispose();
    _email.dispose();
    _branchId.dispose();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    try {
      final values = await sl<AppRoleRepository>().getRoles();

      if (!mounted) return;

      setState(() {
        _roles = values.where((role) => role.isActive).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _loading = false);
      _show(error.toString());
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final selectedRole = _roles.where((role) => role.id == _roleId).firstOrNull;

    if (selectedRole == null) {
      _show('Select a valid active role.');
      return;
    }

    final old = widget.existing;
    final now = DateTime.now();

    Navigator.pop(
      context,
      UserRoleAssignmentEntity(
        id: old?.id ?? _userId.text.trim(),
        userId: _userId.text.trim(),
        userName: _userName.text.trim(),
        email: _email.text.trim().toLowerCase(),
        roleId: selectedRole.id,
        roleName: selectedRole.name,
        branchId: _branchId.text.trim().isEmpty
            ? 'main'
            : _branchId.text.trim(),
        isActive: _isActive,
        assignedBy: old?.assignedBy ?? 'Admin',
        assignedAt: old?.assignedAt ?? now,
        updatedAt: now,
      ),
    );
  }

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(actions: const [DashboardNavigationButton()],
        title: Text(
          widget.existing == null ? 'Assign User Role' : 'Edit User Role',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Firebase Auth UID Firebase Console → '
                  'Authentication → Users se copy karein.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _userId,
              readOnly: widget.existing != null,
              decoration: const InputDecoration(
                labelText: 'Firebase Auth UID',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Firebase Auth UID is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _userName,
              decoration: const InputDecoration(
                labelText: 'User Display Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'User name is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Login Email',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';

                if (text.isEmpty) return 'Email is required';
                if (!text.contains('@')) {
                  return 'Enter a valid email address';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _roleId,
              decoration: const InputDecoration(
                labelText: 'Assigned Role',
                border: OutlineInputBorder(),
              ),
              items: _roles
                  .map(
                    (role) => DropdownMenuItem(
                      value: role.id,
                      child: Text(role.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _roleId = value),
              validator: (value) => value == null ? 'Role is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _branchId,
              decoration: const InputDecoration(
                labelText: 'Branch ID',
                helperText: 'Use main for the current school branch.',
                border: OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('User Access Active'),
              subtitle: const Text(
                'Inactive users will be blocked in Phase 3.',
              ),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Assignment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
