import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/app_role_entity.dart';
import '../../domain/entities/user_role_assignment_entity.dart';
import '../../domain/repositories/app_role_repository.dart';
import '../bloc/user_role_assignment_bloc.dart';
import 'user_role_assignment_form_page.dart';

class UserRoleAssignmentsPage extends StatelessWidget {
  const UserRoleAssignmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<UserRoleAssignmentBloc>()..add(const LoadUserRoleAssignments()),
      child: const _UserRoleAssignmentsView(),
    );
  }
}

class _UserRoleAssignmentsView extends StatefulWidget {
  const _UserRoleAssignmentsView();

  @override
  State<_UserRoleAssignmentsView> createState() =>
      _UserRoleAssignmentsViewState();
}

class _UserRoleAssignmentsViewState extends State<_UserRoleAssignmentsView> {
  final _search = TextEditingController();
  List<AppRoleEntity> _roles = const [];
  String? _roleId;
  bool? _isActive;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    final roles = await sl<AppRoleRepository>().getRoles();

    if (!mounted) return;
    setState(() => _roles = roles);
  }

  void _load() {
    context.read<UserRoleAssignmentBloc>().add(
      LoadUserRoleAssignments(
        roleId: _roleId,
        isActive: _isActive,
        searchText: _search.text,
      ),
    );
  }

  Future<void> _open([UserRoleAssignmentEntity? existing]) async {
    final value = await Navigator.of(context).push<UserRoleAssignmentEntity>(
      MaterialPageRoute(
        builder: (_) => UserRoleAssignmentFormPage(existing: existing),
      ),
    );

    if (value != null && mounted) {
      context.read<UserRoleAssignmentBloc>().add(SaveUserRoleAssignment(value));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Role Assignment')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _open,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Assign User'),
      ),
      body: BlocConsumer<UserRoleAssignmentBloc, UserRoleAssignmentState>(
        listener: (context, state) {
          final message = switch (state) {
            UserRoleAssignmentLoaded(:final message) => message,
            UserRoleAssignmentError(:final message) => message,
            _ => null,
          };

          if (message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          }
        },
        builder: (context, state) {
          final loading = state is UserRoleAssignmentLoading;
          final assignments = state is UserRoleAssignmentLoaded
              ? state.assignments
              : <UserRoleAssignmentEntity>[];

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 260,
                            child: TextField(
                              controller: _search,
                              decoration: const InputDecoration(
                                labelText: 'Search name, email or UID',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.search),
                              ),
                              onSubmitted: (_) => _load(),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: DropdownButtonFormField<String?>(
                              initialValue: _roleId,
                              decoration: const InputDecoration(
                                labelText: 'Role',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('All Roles'),
                                ),
                                ..._roles.map(
                                  (role) => DropdownMenuItem(
                                    value: role.id,
                                    child: Text(role.name),
                                  ),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _roleId = value),
                            ),
                          ),
                          SizedBox(
                            width: 180,
                            child: DropdownButtonFormField<bool?>(
                              initialValue: _isActive,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('All'),
                                ),
                                DropdownMenuItem(
                                  value: true,
                                  child: Text('Active'),
                                ),
                                DropdownMenuItem(
                                  value: false,
                                  child: Text('Inactive'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _isActive = value),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.filter_alt),
                            label: const Text('Apply'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('Total: ${assignments.length}')),
                      Chip(
                        label: Text(
                          'Active: ${assignments.where((item) => item.isActive).length}',
                        ),
                      ),
                      Chip(
                        label: Text(
                          'Inactive: ${assignments.where((item) => !item.isActive).length}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (assignments.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('No user role assignments found.'),
                        ),
                      ),
                    )
                  else
                    for (final assignment in assignments)
                      Card(
                        child: ListTile(
                          onTap: () => _open(assignment),
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(assignment.userName),
                          subtitle: Text(
                            '${assignment.email}\n'
                            '${assignment.roleName} • '
                            'Branch: ${assignment.branchId}',
                          ),
                          isThreeLine: true,
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              Chip(
                                label: Text(
                                  assignment.isActive ? 'ACTIVE' : 'INACTIVE',
                                ),
                              ),
                              IconButton(
                                tooltip: 'Edit',
                                onPressed: () => _open(assignment),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                onPressed: () {
                                  context.read<UserRoleAssignmentBloc>().add(
                                    DeleteUserRoleAssignment(assignment.id),
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
