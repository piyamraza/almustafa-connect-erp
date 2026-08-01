import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/service_locator.dart';
import '../../data/services/user_account_service_impl.dart';
import '../../domain/entities/app_role_entity.dart';
import '../../domain/entities/user_account_entity.dart';
import '../../domain/repositories/app_role_repository.dart';
import '../../domain/services/user_account_service.dart';

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

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final values = await Future.wait<Object>([
        _service.listAccounts(),
        sl<AppRoleRepository>().getRoles(),
      ]);

      if (!mounted) return;

      setState(() {
        _accounts = values[0] as List<UserAccountEntity>;
        _roles = (values[1] as List<AppRoleEntity>)
            .where((role) => role.isActive)
            .toList(growable: false);
      });
    } catch (error) {
      if (!mounted) return;
      _show(_message(error));
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
              account.roleName.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _createAccount() async {
    if (_roles.isEmpty) {
      _show('Create active roles before creating user accounts.');
      return;
    }

    final request = await showDialog<_CreateAccountRequest>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateUserDialog(roles: _roles),
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

  Future<void> _changeRole(UserAccountEntity account) async {
    AppRoleEntity? selected = _roles
        .where((role) => role.id == account.roleId)
        .firstOrNull;
    final branch = TextEditingController(text: account.branchId);

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: Text('Change Role — ${account.displayName}'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<AppRoleEntity>(
                      initialValue: selected,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: _roles
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => selected = value),
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: selected == null
                      ? null
                      : () => Navigator.pop(dialogContext, true),
                  child: const Text('Update Role'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!confirmed || selected == null || !mounted) {
      branch.dispose();
      return;
    }

    setState(() => _loading = true);

    try {
      await _service.updateRole(
        uid: account.uid,
        roleId: selected!.id,
        roleName: selected!.name,
        branchId: branch.text.trim().isEmpty ? 'main' : branch.text.trim(),
      );
      await _load();
      _show('User role updated.');
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

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(title: const Text('User Accounts Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _createAccount,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Create User'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _search,
                          onChanged: (value) => setState(() => _query = value),
                          decoration: const InputDecoration(
                            labelText: 'Search name, username, email or role',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonalIcon(
                        onPressed: _loading ? null : _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ],
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
                      onToggle: () => _toggleAccount(account),
                      onChangeRole: () => _changeRole(account),
                      onResetPassword: () => _resetPassword(account),
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

class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog({required this.roles});

  final List<AppRoleEntity> roles;

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
  final _linkedId = TextEditingController();

  AppRoleEntity? _role;
  String _linkedType = '';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _login.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _branch.dispose();
    _linkedId.dispose();
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
                _field(
                  controller: _name,
                  label: 'Display Name',
                  validator: _required,
                ),
                _field(
                  controller: _login,
                  label: 'Email or Username',
                  helper:
                      'Username automatically becomes username@almustafa.school',
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
                SizedBox(
                  width: 285,
                  child: DropdownButtonFormField<String>(
                    initialValue: _linkedType,
                    decoration: const InputDecoration(
                      labelText: 'Link Account To',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('No Link')),
                      DropdownMenuItem(
                        value: 'teacher',
                        child: Text('Teacher'),
                      ),
                      DropdownMenuItem(value: 'staff', child: Text('Staff')),
                      DropdownMenuItem(value: 'parent', child: Text('Parent')),
                      DropdownMenuItem(
                        value: 'student',
                        child: Text('Student'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _linkedType = value ?? ''),
                  ),
                ),
                _field(
                  controller: _linkedId,
                  label: 'Linked Record ID',
                  helper: 'Optional in this phase',
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
        linkedEntityId: _linkedId.text.trim(),
      ),
    );
  }
}

class _UserAccountCard extends StatelessWidget {
  const _UserAccountCard({
    required this.account,
    required this.onToggle,
    required this.onChangeRole,
    required this.onResetPassword,
  });

  final UserAccountEntity account;
  final VoidCallback onToggle;
  final VoidCallback onChangeRole;
  final VoidCallback onResetPassword;

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
          '${account.roleName} • Branch ${account.branchId}\n'
          'UID: ${account.uid}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
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
                  case 'role':
                    onChangeRole();
                  case 'password':
                    onResetPassword();
                  case 'toggle':
                    onToggle();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'role', child: Text('Change Role')),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
