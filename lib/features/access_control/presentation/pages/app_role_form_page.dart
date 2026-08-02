import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/app_permission.dart';
import '../../domain/entities/app_role_entity.dart';
import '../../domain/repositories/app_role_repository.dart';

class AppRoleFormPage extends StatefulWidget {
  const AppRoleFormPage({super.key, this.existing});

  final AppRoleEntity? existing;

  @override
  State<AppRoleFormPage> createState() => _AppRoleFormPageState();
}

class _AppRoleFormPageState extends State<AppRoleFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  final Set<AppPermission> _permissions = {};
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _description = TextEditingController(
      text: widget.existing?.description ?? '',
    );
    _permissions.addAll(widget.existing?.permissions ?? const []);
    _isActive = widget.existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_permissions.isEmpty) {
      _show('Select at least one permission.');
      return;
    }

    final old = widget.existing;
    final now = DateTime.now();

    Navigator.pop(
      context,
      AppRoleEntity(
        id: old?.id ?? sl<AppRoleRepository>().generateId(),
        name: _name.text.trim(),
        description: _description.text.trim(),
        permissions: _permissions.toList(),
        isSystemRole: old?.isSystemRole ?? false,
        isActive: _isActive,
        createdAt: old?.createdAt ?? now,
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
    final grouped = <String, List<AppPermission>>{};
    for (final permission in AppPermission.values) {
      grouped.putIfAbsent(permission.module, () => []).add(permission);
    }

    return Scaffold(
      appBar: AppBar(actions: const [DashboardNavigationButton()],
        title: Text(widget.existing == null ? 'Create Role' : 'Edit Role'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              readOnly: widget.existing?.isSystemRole ?? false,
              decoration: const InputDecoration(
                labelText: 'Role Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Role name is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Role Active'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const Divider(),
            Text(
              'Permission Matrix',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final entry in grouped.entries)
              Card(
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: Text(entry.key),
                  subtitle: Text(
                    '${entry.value.where(_permissions.contains).length}'
                    '/${entry.value.length} selected',
                  ),
                  trailing: Checkbox(
                    value: entry.value.every(_permissions.contains),
                    tristate: true,
                    onChanged: (selected) {
                      setState(() {
                        if (selected ?? false) {
                          _permissions.addAll(entry.value);
                        } else {
                          _permissions.removeAll(entry.value);
                        }
                      });
                    },
                  ),
                  children: [
                    for (final permission in entry.value)
                      CheckboxListTile(
                        value: _permissions.contains(permission),
                        title: Text(permission.label),
                        onChanged: (selected) {
                          setState(() {
                            if (selected ?? false) {
                              _permissions.add(permission);
                            } else {
                              _permissions.remove(permission);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Role'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
