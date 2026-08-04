import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../domain/entities/app_role_entity.dart';
import '../../domain/entities/user_role_assignment_entity.dart';
import '../../domain/repositories/app_role_repository.dart';
import '../../domain/repositories/user_role_assignment_repository.dart';

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
  bool _isPrimary = false;
  bool _isTemporary = false;
  bool _loading = true;

  DateTime? _validFrom;
  DateTime? _validUntil;

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
    _isPrimary = existing?.isPrimary ?? false;
    _validFrom = existing?.validFrom;
    _validUntil = existing?.validUntil;
    _isTemporary = existing?.validFrom != null || existing?.validUntil != null;

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

      if (!mounted) {
        return;
      }

      setState(() {
        _roles = values
            .where(
              (role) => role.isActive || role.id == widget.existing?.roleId,
            )
            .toList();

        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _loading = false);
      _show(error.toString());
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    AppRoleEntity? selectedRole;

    for (final role in _roles) {
      if (role.id == _roleId) {
        selectedRole = role;
        break;
      }
    }

    if (selectedRole == null) {
      _show('Select a valid active role.');
      return;
    }

    if (_isTemporary) {
      if (_validFrom == null) {
        _show('Select role start date.');
        return;
      }

      if (_validUntil == null) {
        _show('Select role expiry date.');
        return;
      }

      if (_validUntil!.isBefore(_validFrom!)) {
        _show('Role expiry date cannot be before start date.');
        return;
      }
    }

    final old = widget.existing;
    final now = DateTime.now();

    final assignmentId =
        old?.id ?? sl<UserRoleAssignmentRepository>().generateId();

    Navigator.pop(
      context,
      UserRoleAssignmentEntity(
        id: assignmentId,
        userId: _userId.text.trim(),
        userName: _userName.text.trim(),
        email: _email.text.trim().toLowerCase(),
        roleId: selectedRole.id,
        roleName: selectedRole.name,
        branchId: _branchId.text.trim().isEmpty
            ? 'main'
            : _branchId.text.trim(),
        isActive: _isActive,
        isPrimary: _isPrimary,
        validFrom: _isTemporary ? _validFrom : null,
        validUntil: _isTemporary ? _validUntil : null,
        assignedBy: old?.assignedBy ?? 'Admin',
        assignedAt: old?.assignedAt ?? now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _selectFromDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _validFrom ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _validFrom = selected;

      if (_validUntil != null && _validUntil!.isBefore(selected)) {
        _validUntil = selected;
      }
    });
  }

  Future<void> _selectUntilDate() async {
    final firstDate = _validFrom ?? DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _validUntil ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() => _validUntil = selected);
  }

  void _clearDates() {
    setState(() {
      _validFrom = null;
      _validUntil = null;
    });
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Not selected';
    }

    return '${value.day.toString().padLeft(2, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final editing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing ? 'Edit Role Assignment' : 'Assign Additional Role',
        ),
        actions: const [DashboardNavigationButton()],
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
                  editing
                      ? 'Update this role assignment. Other roles '
                            'assigned to the same login will remain unchanged.'
                      : 'The same Firebase user can receive multiple '
                            'roles. Use the same UID and create a separate '
                            'assignment for each additional role.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _userId,
              readOnly: editing,
              decoration: const InputDecoration(
                labelText: 'Firebase Auth UID',
                helperText: 'Firebase Console → Authentication → Users',
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

                if (text.isEmpty) {
                  return 'Email is required';
                }

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
                    (role) => DropdownMenuItem<String>(
                      value: role.id,
                      child: Text(role.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _roleId = value);
              },
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
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Primary Role'),
              subtitle: const Text(
                'The primary role determines the user’s main '
                'workspace. Only one role can remain primary.',
              ),
              value: _isPrimary,
              onChanged: (value) {
                setState(() => _isPrimary = value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Role Assignment Active'),
              subtitle: const Text(
                'Inactive assignments do not provide access.',
              ),
              value: _isActive,
              onChanged: (value) {
                setState(() => _isActive = value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Temporary Role'),
              subtitle: const Text(
                'Enable this for duties that automatically '
                'expire after a specified date.',
              ),
              value: _isTemporary,
              onChanged: (value) {
                setState(() {
                  _isTemporary = value;

                  if (!value) {
                    _validFrom = null;
                    _validUntil = null;
                  }
                });
              },
            ),
            if (_isTemporary) ...[
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.event_available),
                      title: const Text('Valid From'),
                      subtitle: Text(_formatDate(_validFrom)),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: _selectFromDate,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.event_busy),
                      title: const Text('Valid Until'),
                      subtitle: Text(_formatDate(_validUntil)),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: _selectUntilDate,
                    ),
                    if (_validFrom != null || _validUntil != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _clearDates,
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Dates'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(
                  editing ? 'Update Assignment' : 'Save Role Assignment',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
