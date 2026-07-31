import 'package:flutter/material.dart';

import '../../domain/entities/staff_attendance_entity.dart';
import '../../domain/entities/staff_entity.dart';

class StaffAttendanceListItem extends StatelessWidget {
  const StaffAttendanceListItem({
    required this.staff,
    required this.status,
    required this.onStatusChanged,
    super.key,
    this.remarks = '',
    this.onRemarksChanged,
    this.isEnabled = true,
  });

  final StaffEntity staff;
  final StaffAttendanceStatus status;
  final ValueChanged<StaffAttendanceStatus> onStatusChanged;
  final String remarks;
  final ValueChanged<String>? onRemarksChanged;
  final bool isEnabled;

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 700;

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StaffInformation(staff: staff),
                  const SizedBox(height: 16),
                  _StatusSelector(
                    status: status,
                    isEnabled: isEnabled,
                    onStatusChanged: onStatusChanged,
                  ),
                  if (onRemarksChanged != null) ...[
                    const SizedBox(height: 14),
                    _RemarksField(
                      initialValue: remarks,
                      isEnabled: isEnabled,
                      onChanged: onRemarksChanged!,
                    ),
                  ],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: _StaffInformation(staff: staff),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 180,
                  child: _StatusSelector(
                    status: status,
                    isEnabled: isEnabled,
                    onStatusChanged: onStatusChanged,
                  ),
                ),
                if (onRemarksChanged != null) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: _RemarksField(
                      initialValue: remarks,
                      isEnabled: isEnabled,
                      onChanged: onRemarksChanged!,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StaffInformation extends StatelessWidget {
  const _StaffInformation({
    required this.staff,
  });

  final StaffEntity staff;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = staff.profileImageUrl.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primaryContainer,
          ),
          child: imageUrl.isEmpty
              ? Icon(
                  Icons.person_rounded,
                  size: 30,
                  color: theme.colorScheme.onPrimaryContainer,
                )
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person_rounded,
                      size: 30,
                      color: theme.colorScheme.onPrimaryContainer,
                    );
                  },
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                staff.fullName.trim().isEmpty
                    ? 'Unnamed Staff Member'
                    : staff.fullName.trim(),
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
                    : staff.designation.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  _InformationLabel(
                    icon: Icons.badge_outlined,
                    text: staff.staffId.trim().isEmpty
                        ? 'No Staff ID'
                        : staff.staffId.trim(),
                  ),
                  if (staff.phone.trim().isNotEmpty)
                    _InformationLabel(
                      icon: Icons.phone_outlined,
                      text: staff.phone.trim(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusSelector extends StatelessWidget {
  const _StatusSelector({
    required this.status,
    required this.isEnabled,
    required this.onStatusChanged,
  });

  final StaffAttendanceStatus status;
  final bool isEnabled;
  final ValueChanged<StaffAttendanceStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<StaffAttendanceStatus>(
      initialValue: status,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Attendance Status',
        prefixIcon: Icon(Icons.fact_check_outlined),
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: StaffAttendanceStatus.values.map((attendanceStatus) {
        return DropdownMenuItem<StaffAttendanceStatus>(
          value: attendanceStatus,
          child: Text(
            _statusLabel(attendanceStatus),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: isEnabled
          ? (selectedStatus) {
              if (selectedStatus != null) {
                onStatusChanged(selectedStatus);
              }
            }
          : null,
    );
  }

  String _statusLabel(StaffAttendanceStatus status) {
    switch (status) {
      case StaffAttendanceStatus.present:
        return 'Present';
      case StaffAttendanceStatus.absent:
        return 'Absent';
      case StaffAttendanceStatus.late:
        return 'Late';
      case StaffAttendanceStatus.leave:
        return 'Leave';
    }
  }
}

class _RemarksField extends StatefulWidget {
  const _RemarksField({
    required this.initialValue,
    required this.isEnabled,
    required this.onChanged,
  });

  final String initialValue;
  final bool isEnabled;
  final ValueChanged<String> onChanged;

  @override
  State<_RemarksField> createState() => _RemarksFieldState();
}

class _RemarksFieldState extends State<_RemarksField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialValue,
    );
  }

  @override
  void didUpdateWidget(covariant _RemarksField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.isEnabled,
      onChanged: widget.onChanged,
      maxLines: 2,
      minLines: 1,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Remarks',
        hintText: 'Optional remarks',
        prefixIcon: Icon(Icons.notes_outlined),
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
        isDense: true,
      ),
    );
  }
}

class _InformationLabel extends StatelessWidget {
  const _InformationLabel({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}