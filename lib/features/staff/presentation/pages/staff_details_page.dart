import 'package:flutter/material.dart';

import '../../domain/entities/staff_entity.dart';

class StaffDetailsPage extends StatelessWidget {
  const StaffDetailsPage({
    super.key,
    required this.staff,
    required this.onEdit,
  });

  final StaffEntity staff;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Details'),
        actions: [
          IconButton(
            tooltip: 'Edit Staff',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 1200
                ? 32.0
                : constraints.maxWidth >= 700
                    ? 24.0
                    : 16.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileHeader(
                        staff: staff,
                        onEdit: onEdit,
                      ),
                      const SizedBox(height: 20),
                      _DetailsSection(
                        title: 'Personal Information',
                        icon: Icons.person_outline,
                        children: [
                          _DetailItem(
                            icon: Icons.badge_outlined,
                            label: 'Staff ID',
                            value: _displayValue(staff.staffId),
                          ),
                          _DetailItem(
                            icon: Icons.person_outline,
                            label: 'First Name',
                            value: _displayValue(staff.firstName),
                          ),
                          _DetailItem(
                            icon: Icons.person_outline,
                            label: 'Last Name',
                            value: _displayValue(staff.lastName),
                          ),
                          _DetailItem(
                            icon: Icons.family_restroom_outlined,
                            label: 'Father Name',
                            value: _displayValue(staff.fatherName),
                          ),
                          _DetailItem(
                            icon: Icons.credit_card_outlined,
                            label: 'CNIC',
                            value: _displayValue(staff.cnic),
                          ),
                          _DetailItem(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: _displayValue(staff.phone),
                          ),
                          _DetailItem(
                            icon: Icons.location_on_outlined,
                            label: 'Address',
                            value: _displayValue(staff.address),
                            fullWidth: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _DetailsSection(
                        title: 'Employment Information',
                        icon: Icons.work_outline,
                        children: [
                          _DetailItem(
                            icon: Icons.work_outline,
                            label: 'Designation',
                            value: _displayValue(staff.designation),
                          ),
                          _DetailItem(
                            icon: Icons.calendar_month_outlined,
                            label: 'Joining Date',
                            value: _formatDate(staff.joiningDate),
                          ),
                          _DetailItem(
                            icon: Icons.payments_outlined,
                            label: 'Monthly Salary',
                            value: _formatSalary(staff.monthlySalary),
                          ),
                          _DetailItem(
                            icon: staff.isActive
                                ? Icons.check_circle_outline
                                : Icons.cancel_outlined,
                            label: 'Status',
                            value: staff.isActive ? 'Active' : 'Inactive',
                            valueColor: staff.isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _DetailsSection(
                        title: 'System Information',
                        icon: Icons.info_outline,
                        children: [
                          _DetailItem(
                            icon: Icons.fingerprint,
                            label: 'Record ID',
                            value: _displayValue(staff.id),
                            fullWidth: true,
                          ),
                          _DetailItem(
                            icon: Icons.image_outlined,
                            label: 'Profile Image',
                            value: staff.profileImageUrl.trim().isEmpty
                                ? 'Not uploaded'
                                : 'Uploaded',
                          ),
                          _DetailItem(
                            icon: Icons.add_circle_outline,
                            label: 'Created At',
                            value: _formatDateTime(staff.createdAt),
                          ),
                          _DetailItem(
                            icon: Icons.update_outlined,
                            label: 'Last Updated',
                            value: _formatDateTime(staff.updatedAt),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static String _displayValue(String value) {
    final trimmedValue = value.trim();
    return trimmedValue.isEmpty ? 'Not provided' : trimmedValue;
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  static String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year}  $hour:$minute';
  }

  static String _formatSalary(num salary) {
    final hasDecimal = salary != salary.roundToDouble();
    final salaryText = hasDecimal
        ? salary.toStringAsFixed(2)
        : salary.toStringAsFixed(0);

    final parts = salaryText.split('.');
    final wholeNumber = parts.first;
    final formattedWholeNumber = wholeNumber.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    if (parts.length > 1) {
      return 'Rs. $formattedWholeNumber.${parts.last}';
    }

    return 'Rs. $formattedWholeNumber';
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.staff,
    required this.onEdit,
  });

  final StaffEntity staff;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;

            final profileImage = _StaffProfileImage(staff: staff);

            final information = Column(
              crossAxisAlignment: isCompact
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  staff.fullName.trim().isEmpty
                      ? 'Unnamed Staff Member'
                      : staff.fullName.trim(),
                  textAlign: isCompact ? TextAlign.center : TextAlign.start,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  staff.designation.trim().isEmpty
                      ? 'Designation not provided'
                      : staff.designation.trim(),
                  textAlign: isCompact ? TextAlign.center : TextAlign.start,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment:
                      isCompact ? WrapAlignment.center : WrapAlignment.start,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Chip(
                      avatar: const Icon(
                        Icons.badge_outlined,
                        size: 18,
                      ),
                      label: Text(
                        staff.staffId.trim().isEmpty
                            ? 'No Staff ID'
                            : staff.staffId.trim(),
                      ),
                    ),
                    Chip(
                      avatar: Icon(
                        staff.isActive
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        size: 18,
                      ),
                      label: Text(
                        staff.isActive ? 'Active' : 'Inactive',
                      ),
                    ),
                  ],
                ),
              ],
            );

            final editButton = FilledButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Staff'),
            );

            if (isCompact) {
              return Column(
                children: [
                  profileImage,
                  const SizedBox(height: 18),
                  information,
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: editButton,
                  ),
                ],
              );
            }

            return Row(
              children: [
                profileImage,
                const SizedBox(width: 24),
                Expanded(child: information),
                const SizedBox(width: 20),
                editButton,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StaffProfileImage extends StatelessWidget {
  const _StaffProfileImage({
    required this.staff,
  });

  final StaffEntity staff;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = staff.profileImageUrl.trim();
    final initial = staff.firstName.trim().isEmpty
        ? '?'
        : staff.firstName.trim().substring(0, 1).toUpperCase();

    Widget fallback() {
      return ColoredBox(
        color: theme.colorScheme.primaryContainer,
        child: Center(
          child: Text(
            initial,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isEmpty
          ? fallback()
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback(),
            ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<_DetailItem> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final isTwoColumns = constraints.maxWidth >= 700;
                final itemWidth = isTwoColumns
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 16,
                  runSpacing: 14,
                  children: children.map((item) {
                    return SizedBox(
                      width: item.fullWidth
                          ? constraints.maxWidth
                          : itemWidth,
                      child: item,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 21,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: valueColor ?? theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}