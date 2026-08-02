import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/staff_entity.dart';
import '../bloc/staff_bloc.dart';
import '../bloc/staff_event.dart';
import '../bloc/staff_state.dart';
import '../widgets/staff_list_item.dart';
import 'add_staff_page.dart';
import 'edit_staff_page.dart';
import 'staff_details_page.dart';

class StaffListPage extends StatelessWidget {
  const StaffListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffBloc>(
      create: (_) => sl<StaffBloc>()..add(const LoadStaffEvent()),
      child: const _StaffListView(),
    );
  }
}

class _StaffListView extends StatefulWidget {
  const _StaffListView();

  @override
  State<_StaffListView> createState() => _StaffListViewState();
}

class _StaffListViewState extends State<_StaffListView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshStaff() async {
    final staffBloc = context.read<StaffBloc>();

    staffBloc.add(const LoadStaffEvent());

    await staffBloc.stream.firstWhere(
      (state) => state is StaffLoaded || state is StaffError,
    );
  }

  void _reloadStaff() {
    _searchController.clear();
    context.read<StaffBloc>().add(const LoadStaffEvent());
  }

  Future<void> _openAddStaff() async {
    final wasAdded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AddStaffPage(),
      ),
    );

    if (!mounted) {
      return;
    }

    if (wasAdded == true) {
      _reloadStaff();
    }
  }

  Future<void> _openEditStaff(StaffEntity staff) async {
    final wasUpdated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditStaffPage(
          staff: staff,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (wasUpdated == true) {
      _reloadStaff();
    }
  }

  Future<void> _openEditFromDetails(
    BuildContext detailsContext,
    StaffEntity staff,
  ) async {
    final wasUpdated = await Navigator.of(detailsContext).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditStaffPage(
          staff: staff,
        ),
      ),
    );

    if (!detailsContext.mounted) {
      return;
    }

    if (wasUpdated == true) {
      Navigator.of(detailsContext).pop(true);
    }
  }

  Future<void> _openStaffDetails(StaffEntity staff) async {
    final wasUpdated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (detailsContext) {
          return StaffDetailsPage(
            staff: staff,
            onEdit: () {
              _openEditFromDetails(
                detailsContext,
                staff,
              );
            },
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    if (wasUpdated == true) {
      _reloadStaff();
    }
  }

  Future<void> _confirmDeleteStaff(StaffEntity staff) async {
    final staffName = staff.fullName.trim().isEmpty
        ? 'this staff member'
        : staff.fullName.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded),
          title: const Text('Delete Staff Member?'),
          content: Text(
            'Are you sure you want to permanently delete $staffName?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    context.read<StaffBloc>().add(
          DeleteStaffEvent(staff.id),
        );
  }

  void _toggleStaffStatus(
    StaffEntity staff,
    bool isActive,
  ) {
    context.read<StaffBloc>().add(
          ToggleStaffStatusEvent(
            staff: staff,
            isActive: isActive,
          ),
        );
  }

  void _clearSearch() {
    _searchController.clear();

    context.read<StaffBloc>().add(
          const SearchStaffEvent(''),
        );
  }

  void _showSuccessMessage(
    BuildContext context,
    StaffState state,
  ) {
    if (state is StaffLoaded &&
        state.successMessage != null &&
        state.successMessage!.trim().isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(state.successMessage!),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff List'),
        actions: [const DashboardNavigationButton(),
          IconButton(
            tooltip: 'Refresh Staff',
            onPressed: _reloadStaff,
            icon: const Icon(Icons.refresh_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddStaff,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Add Staff'),
      ),
      body: SafeArea(
        child: BlocConsumer<StaffBloc, StaffState>(
          listener: _showSuccessMessage,
          builder: (context, state) {
            if (state is StaffInitial || state is StaffLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is StaffError) {
              return _StaffErrorView(
                message: state.message,
                onRetry: _reloadStaff,
              );
            }

            if (state is StaffLoaded) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth >= 1200
                      ? 32.0
                      : constraints.maxWidth >= 700
                          ? 24.0
                          : 16.0;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      20,
                      horizontalPadding,
                      0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 1200,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _StaffListHeader(
                              totalStaff: state.allStaff.length,
                              visibleStaff: state.visibleStaff.length,
                              onAddStaff: _openAddStaff,
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              controller: _searchController,
                              onChanged: (query) {
                                context.read<StaffBloc>().add(
                                      SearchStaffEvent(query),
                                    );
                              },
                              decoration: InputDecoration(
                                hintText:
                                    'Search by name, Staff ID, CNIC, phone or designation',
                                prefixIcon: const Icon(Icons.search_outlined),
                                suffixIcon: state.searchQuery.trim().isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Clear Search',
                                        onPressed: _clearSearch,
                                        icon: const Icon(Icons.clear),
                                      ),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _refreshStaff,
                                child: state.visibleStaff.isEmpty
                                    ? _EmptyStaffList(
                                        hasSearch:
                                            state.searchQuery.trim().isNotEmpty,
                                        onClearSearch: _clearSearch,
                                        onAddStaff: _openAddStaff,
                                      )
                                    : ListView.separated(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        padding: const EdgeInsets.only(
                                          bottom: 100,
                                        ),
                                        itemCount: state.visibleStaff.length,
                                        separatorBuilder: (context, index) {
                                          return const SizedBox(height: 14);
                                        },
                                        itemBuilder: (context, index) {
                                          final staff =
                                              state.visibleStaff[index];

                                          return StaffListItem(
                                            staff: staff,
                                            onTap: () {
                                              _openStaffDetails(staff);
                                            },
                                            onEdit: () {
                                              _openEditStaff(staff);
                                            },
                                            onDelete: () {
                                              _confirmDeleteStaff(staff);
                                            },
                                            onStatusChanged: (isActive) {
                                              _toggleStaffStatus(
                                                staff,
                                                isActive,
                                              );
                                            },
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _StaffListHeader extends StatelessWidget {
  const _StaffListHeader({
    required this.totalStaff,
    required this.visibleStaff,
    required this.onAddStaff,
  });

  final int totalStaff;
  final int visibleStaff;
  final VoidCallback onAddStaff;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 650;

            final information = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Staff Records',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  visibleStaff == totalStaff
                      ? '$totalStaff staff record${totalStaff == 1 ? '' : 's'}'
                      : 'Showing $visibleStaff of $totalStaff staff records',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );

            final addButton = FilledButton.icon(
              onPressed: onAddStaff,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Add Staff'),
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  information,
                  const SizedBox(height: 16),
                  addButton,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: information),
                const SizedBox(width: 20),
                addButton,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyStaffList extends StatelessWidget {
  const _EmptyStaffList({
    required this.hasSearch,
    required this.onClearSearch,
    required this.onAddStaff,
  });

  final bool hasSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onAddStaff;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 50,
      ),
      children: [
        Icon(
          hasSearch
              ? Icons.search_off_outlined
              : Icons.groups_outlined,
          size: 70,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 18),
        Text(
          hasSearch
              ? 'No matching staff found'
              : 'No staff records available',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasSearch
              ? 'Try changing or clearing your search.'
              : 'Add the first non-teaching staff member.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: hasSearch
              ? OutlinedButton.icon(
                  onPressed: onClearSearch,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Search'),
                )
              : FilledButton.icon(
                  onPressed: onAddStaff,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Add Staff'),
                ),
        ),
      ],
    );
  }
}

class _StaffErrorView extends StatelessWidget {
  const _StaffErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 450,
          ),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load staff',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}