import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/parent_account_entity.dart';
import '../../domain/repositories/parent_portal_repository.dart';
import 'parent_account_form_page.dart';

class ParentManagementPage extends StatefulWidget {
  const ParentManagementPage({super.key});

  @override
  State<ParentManagementPage> createState() => _ParentManagementPageState();
}

class _ParentManagementPageState extends State<ParentManagementPage> {
  final ParentPortalRepository _repository = sl<ParentPortalRepository>();
  final TextEditingController _searchController = TextEditingController();

  List<ParentAccountEntity> _parents = const <ParentAccountEntity>[];

  bool _isLoading = true;
  String? _errorMessage;
  String _statusFilter = 'all';
  String _relationshipFilter = 'all';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshView);
    _loadParents();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshView)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadParents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final values = await _repository.getParents();

      if (!mounted) return;

      setState(() {
        _parents = values;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error
            .toString()
            .replaceFirst('StateError: ', '')
            .replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openParentForm([ParentAccountEntity? existing]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ParentAccountFormPage(existing: existing),
      ),
    );

    if (saved == true && mounted) {
      await _loadParents();
    }
  }

  void _refreshView() {
    if (mounted) {
      setState(() {});
    }
  }

  List<ParentAccountEntity> get _filteredParents {
    final query = _searchController.text.trim().toLowerCase();

    final values =
        _parents.where((parent) {
          final matchesSearch =
              query.isEmpty ||
              parent.fullName.toLowerCase().contains(query) ||
              parent.mobileNumber.toLowerCase().contains(query) ||
              parent.whatsappNumber.toLowerCase().contains(query) ||
              parent.email.toLowerCase().contains(query) ||
              parent.userId.toLowerCase().contains(query) ||
              parent.studentIds.any(
                (studentId) => studentId.toLowerCase().contains(query),
              );

          final matchesStatus =
              _statusFilter == 'all' ||
              parent.normalizedAccountStatus == _statusFilter;

          final matchesRelationship =
              _relationshipFilter == 'all' ||
              parent.relationship.trim().toLowerCase() == _relationshipFilter;

          return matchesSearch && matchesStatus && matchesRelationship;
        }).toList()..sort(
          (first, second) => first.fullName.toLowerCase().compareTo(
            second.fullName.toLowerCase(),
          ),
        );

    return List<ParentAccountEntity>.unmodifiable(values);
  }

  Set<String> get _relationships {
    final values =
        _parents
            .map((parent) => parent.relationship.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort(
            (first, second) =>
                first.toLowerCase().compareTo(second.toLowerCase()),
          );

    return values.toSet();
  }

  int _countStatus(String status) {
    return _parents
        .where((parent) => parent.normalizedAccountStatus == status)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredParents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadParents,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openParentForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Parent'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadParents,
        child: _buildBody(filtered),
      ),
    );
  }

  Widget _buildBody(List<ParentAccountEntity> filtered) {
    if (_isLoading) {
      return ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 240),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.error_outline,
            size: 54,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: _loadParents,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth >= 1000 ? 24.0 : 14.0;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            18,
            horizontalPadding,
            100,
          ),
          children: [
            _SummarySection(
              total: _parents.length,
              active: _countStatus(ParentAccountEntity.accountStatusActive),
              inactive: _countStatus(ParentAccountEntity.accountStatusInactive),
              blocked: _countStatus(ParentAccountEntity.accountStatusBlocked),
            ),
            const SizedBox(height: 18),
            _buildFilters(),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Parent Accounts',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(label: Text('${filtered.length} of ${_parents.length}')),
              ],
            ),
            const SizedBox(height: 10),
            if (filtered.isEmpty)
              const _EmptyParentList()
            else
              ...filtered.map(
                (parent) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ParentAccountCard(
                    parent: parent,
                    onEdit: () => _openParentForm(parent),
                    onOpen: () => _openParentForm(parent),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilters() {
    final relationships = _relationships.toList()
      ..sort(
        (first, second) => first.toLowerCase().compareTo(second.toLowerCase()),
      );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;

            final search = TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search name, mobile, WhatsApp, email or linked ID',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.clear),
                      ),
                border: const OutlineInputBorder(),
              ),
            );

            final status = DropdownButtonFormField<String>(
              initialValue: _statusFilter,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                DropdownMenuItem(
                  value: ParentAccountEntity.accountStatusActive,
                  child: Text('Active'),
                ),
                DropdownMenuItem(
                  value: ParentAccountEntity.accountStatusInactive,
                  child: Text('Inactive'),
                ),
                DropdownMenuItem(
                  value: ParentAccountEntity.accountStatusBlocked,
                  child: Text('Blocked'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _statusFilter = value ?? 'all';
                });
              },
            );

            final relationship = DropdownButtonFormField<String>(
              initialValue: _relationshipFilter,
              decoration: const InputDecoration(
                labelText: 'Relationship',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text('All Relationships'),
                ),
                ...relationships.map(
                  (value) => DropdownMenuItem(
                    value: value.toLowerCase(),
                    child: Text(value),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _relationshipFilter = value ?? 'all';
                });
              },
            );

            if (!isWide) {
              return Column(
                children: [
                  search,
                  const SizedBox(height: 12),
                  status,
                  const SizedBox(height: 12),
                  relationship,
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 2, child: search),
                const SizedBox(width: 12),
                Expanded(child: status),
                const SizedBox(width: 12),
                Expanded(child: relationship),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.total,
    required this.active,
    required this.inactive,
    required this.blocked,
  });

  final int total;
  final int active;
  final int inactive;
  final int blocked;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Total Parents', total, Icons.family_restroom),
      ('Active', active, Icons.check_circle_outline),
      ('Inactive', inactive, Icons.pause_circle_outline),
      ('Blocked', blocked, Icons.block_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 520
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 3.8 : 2.5,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(item.$3, size: 30),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.$2}',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(item.$1),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ParentAccountCard extends StatelessWidget {
  const _ParentAccountCard({
    required this.parent,
    required this.onEdit,
    required this.onOpen,
  });

  final ParentAccountEntity parent;
  final VoidCallback onEdit;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;

              final identity = Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.family_restroom)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parent.fullName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          parent.relationship.trim().isEmpty
                              ? 'Guardian'
                              : parent.relationship,
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final details = Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.phone_outlined,
                    label: parent.mobileNumber.isEmpty
                        ? 'No mobile'
                        : parent.mobileNumber,
                  ),
                  _InfoChip(
                    icon: Icons.chat_outlined,
                    label: parent.whatsappNumber.isEmpty
                        ? 'No WhatsApp'
                        : parent.whatsappNumber,
                  ),
                  _InfoChip(
                    icon: Icons.child_care_outlined,
                    label:
                        '${parent.studentIds.length} linked child'
                        '${parent.studentIds.length == 1 ? '' : 'ren'}',
                  ),
                  if (parent.isPrimaryContact)
                    const _InfoChip(
                      icon: Icons.star_outline,
                      label: 'Primary Contact',
                    ),
                ],
              );

              final status = _ParentStatusBadge(
                status: parent.normalizedAccountStatus,
              );

              if (!isWide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    identity,
                    const SizedBox(height: 12),
                    details,
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        status,
                        const Spacer(),
                        IconButton(
                          tooltip: 'Edit',
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  SizedBox(width: 250, child: identity),
                  const SizedBox(width: 16),
                  Expanded(child: details),
                  const SizedBox(width: 16),
                  status,
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ParentStatusBadge extends StatelessWidget {
  const _ParentStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (status) {
      ParentAccountEntity.accountStatusBlocked => ('BLOCKED', Icons.block),
      ParentAccountEntity.accountStatusInactive => (
        'INACTIVE',
        Icons.pause_circle_outline,
      ),
      _ => ('ACTIVE', Icons.check_circle_outline),
    };

    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 17), const SizedBox(width: 5), Text(label)],
    );
  }
}

class _EmptyParentList extends StatelessWidget {
  const _EmptyParentList();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          children: [
            Icon(Icons.family_restroom, size: 52),
            SizedBox(height: 14),
            Text(
              'No parent accounts match the selected filters.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
