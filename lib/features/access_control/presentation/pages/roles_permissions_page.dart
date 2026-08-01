import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/app_role_entity.dart';
import '../bloc/app_role_bloc.dart';
import 'app_role_form_page.dart';

import 'user_role_assignments_page.dart';

import 'access_control_production_readiness_page.dart';

import 'user_accounts_management_page.dart';

class RolesPermissionsPage extends StatelessWidget {
  const RolesPermissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AppRoleBloc>()..add(const LoadAppRoles()),
      child: const _RolesPermissionsView(),
    );
  }
}

class _RolesPermissionsView extends StatelessWidget {
  const _RolesPermissionsView();

  Future<void> _openForm(
    BuildContext context, [
    AppRoleEntity? existing,
  ]) async {
    final value = await Navigator.of(context).push<AppRoleEntity>(
      MaterialPageRoute(builder: (_) => AppRoleFormPage(existing: existing)),
    );

    if (value != null && context.mounted) {
      context.read<AppRoleBloc>().add(SaveAppRole(value));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roles & Permissions'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const UserAccountsManagementPage(),
                ),
              );
            },
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('User Accounts'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const AccessControlProductionReadinessPage(),
                ),
              );
            },
            icon: const Icon(Icons.security_outlined),
            label: const Text('Production Readiness'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const UserRoleAssignmentsPage(),
                ),
              );
            },
            icon: const Icon(Icons.manage_accounts_outlined),
            label: const Text('User Assignments'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Create Custom Role'),
      ),
      body: BlocConsumer<AppRoleBloc, AppRoleState>(
        listener: (context, state) {
          final message = switch (state) {
            AppRoleLoaded(:final message) => message,
            AppRoleError(:final message) => message,
            _ => null,
          };

          if (message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          }
        },
        builder: (context, state) {
          final loading = state is AppRoleLoading;
          final roles = state is AppRoleLoaded
              ? state.roles
              : <AppRoleEntity>[];

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Roles: ${roles.length}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Chip(
                            label: Text(
                              'Active: ${roles.where((role) => role.isActive).length}',
                            ),
                          ),
                          Chip(
                            label: Text(
                              'System: ${roles.where((role) => role.isSystemRole).length}',
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              context.read<AppRoleBloc>().add(
                                const SeedDefaultAppRoles(),
                              );
                            },
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Create Default Roles'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (roles.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No roles found. Use Create Default Roles.',
                          ),
                        ),
                      ),
                    )
                  else
                    for (final role in roles)
                      Card(
                        child: ListTile(
                          onTap: () => _openForm(context, role),
                          leading: CircleAvatar(
                            child: Icon(
                              role.isSystemRole
                                  ? Icons.verified_user
                                  : Icons.manage_accounts,
                            ),
                          ),
                          title: Text(role.name),
                          subtitle: Text(
                            '${role.description}\n'
                            '${role.permissions.length} permissions',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          isThreeLine: true,
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              Chip(
                                label: Text(
                                  role.isActive ? 'ACTIVE' : 'INACTIVE',
                                ),
                              ),
                              IconButton(
                                tooltip: 'Edit',
                                onPressed: () => _openForm(context, role),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              if (!role.isSystemRole)
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () {
                                    context.read<AppRoleBloc>().add(
                                      DeleteAppRole(role.id),
                                    );
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
              if (loading) const LinearProgressIndicator(),
            ],
          );
        },
      ),
    );
  }
}
