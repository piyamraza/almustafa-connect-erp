import 'package:flutter/material.dart';

import '../../domain/entities/staff_entity.dart';

class StaffListItem extends StatelessWidget {
  const StaffListItem({
    required this.staff,
    super.key,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onStatusChanged,
  });

  final StaffEntity staff;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 600;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StaffAvatar(staff: staff),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staff.fullName.isEmpty
                                  ? 'Unnamed Staff'
                                  : staff.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              staff.designation.trim().isEmpty
                                  ? 'Staff Member'
                                  : staff.designation,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Staff ID: ${staff.staffId}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<_StaffAction>(
                        tooltip: 'Staff actions',
                        onSelected: (action) {
                          switch (action) {
                            case _StaffAction.edit:
                              onEdit?.call();
                            case _StaffAction.delete:
                              onDelete?.call();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<_StaffAction>(
                            value: _StaffAction.edit,
                            enabled: onEdit != null,
                            child: const Row(
                              children: [
                                Icon(Icons.edit_outlined),
                                SizedBox(width: 12),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem<_StaffAction>(
                            value: _StaffAction.delete,
                            enabled: onDelete != null,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: colorScheme.error,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _InformationChip(
                        icon: Icons.phone_outlined,
                        label: staff.phone.trim().isEmpty
                            ? 'No phone'
                            : staff.phone,
                      ),
                      _InformationChip(
                        icon: Icons.badge_outlined,
                        label: staff.cnic.trim().isEmpty
                            ? 'No CNIC'
                            : staff.cnic,
                      ),
                      _InformationChip(
                        icon: Icons.payments_outlined,
                        label:
                            'Rs. ${staff.monthlySalary.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (isCompact)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatusLabel(isActive: staff.isActive),
                        if (onStatusChanged != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: staff.isActive,
                                onChanged: onStatusChanged,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                staff.isActive
                                    ? 'Active Staff'
                                    : 'Inactive Staff',
                              ),
                            ],
                          ),
                        ],
                      ],
                    )
                  else
                    Row(
                      children: [
                        _StatusLabel(isActive: staff.isActive),
                        const Spacer(),
                        if (onStatusChanged != null) ...[
                          Text(
                            staff.isActive ? 'Active' : 'Inactive',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: staff.isActive,
                            onChanged: onStatusChanged,
                          ),
                        ],
                      ],
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

class _StaffAvatar extends StatelessWidget {
  const _StaffAvatar({
    required this.staff,
  });

  final StaffEntity staff;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = staff.profileImageUrl.trim();

    return Container(
      width: 58,
      height: 58,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer,
      ),
      child: imageUrl.isEmpty
          ? Icon(
              Icons.person_rounded,
              size: 32,
              color: colorScheme.onPrimaryContainer,
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.person_rounded,
                  size: 32,
                  color: colorScheme.onPrimaryContainer,
                );
              },
            ),
    );
  }
}

class _InformationChip extends StatelessWidget {
  const _InformationChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({
    required this.isActive,
  });

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = isActive
        ? Colors.green.withValues(alpha: 0.12)
        : theme.colorScheme.errorContainer;
    final foregroundColor =
        isActive ? Colors.green.shade800 : theme.colorScheme.onErrorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: theme.textTheme.labelMedium?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum _StaffAction {
  edit,
  delete,
}