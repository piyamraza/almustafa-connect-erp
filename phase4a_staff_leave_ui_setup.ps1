$ErrorActionPreference = "Stop"

$projectRoot = "D:\Projects\almustafa-connect-erp"

if (-not (Test-Path -LiteralPath $projectRoot)) {
    throw "Project folder not found: $projectRoot"
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Write-ProjectFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,

        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $fullPath = Join-Path $projectRoot $RelativePath
    $directory = Split-Path -Parent $fullPath

    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    [System.IO.File]::WriteAllText(
        $fullPath,
        $Content,
        $utf8NoBom
    )

    Write-Host "Written: $RelativePath" -ForegroundColor Green
}

Write-Host ""
Write-Host "Almustafa Connect ERP - Staff Leave Phase 4A UI Setup" -ForegroundColor Cyan
Write-Host "Project: $projectRoot" -ForegroundColor DarkGray
Write-Host ""

# ============================================================
# SUMMARY CARD
# ============================================================

Write-ProjectFile `
    -RelativePath "lib\features\staff\presentation\widgets\staff_leave_summary_card.dart" `
    -Content @'
import 'package:flutter/material.dart';

class StaffLeaveSummaryCard extends StatelessWidget {
  const StaffLeaveSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    super.key,
    this.subtitle,
    this.iconColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor =
        iconColor ?? theme.colorScheme.primary;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: effectiveIconColor,
                size: 27,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null &&
                      subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
'@

# ============================================================
# LIST ITEM
# ============================================================

Write-ProjectFile `
    -RelativePath "lib\features\staff\presentation\widgets\staff_leave_list_item.dart" `
    -Content @'
import 'package:flutter/material.dart';

import '../../domain/entities/staff_leave_entity.dart';

class StaffLeaveListItem extends StatelessWidget {
  const StaffLeaveListItem({
    required this.leave,
    super.key,
    this.onTap,
    this.trailing,
  });

  final StaffLeaveEntity leave;
  final VoidCallback? onTap;
  final Widget? trailing;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _leaveTypeLabel(StaffLeaveType type) {
    switch (type) {
      case StaffLeaveType.casual:
        return 'Casual Leave';
      case StaffLeaveType.sick:
        return 'Sick Leave';
      case StaffLeaveType.annual:
        return 'Annual Leave';
      case StaffLeaveType.unpaid:
        return 'Unpaid Leave';
      case StaffLeaveType.other:
        return 'Other Leave';
    }
  }

  String _durationLabel(StaffLeaveDuration duration) {
    switch (duration) {
      case StaffLeaveDuration.fullDay:
        return 'Full Day';
      case StaffLeaveDuration.halfDay:
        return 'Half Day';
    }
  }

  String _statusLabel(StaffLeaveStatus status) {
    switch (status) {
      case StaffLeaveStatus.pending:
        return 'Pending';
      case StaffLeaveStatus.approved:
        return 'Approved';
      case StaffLeaveStatus.rejected:
        return 'Rejected';
      case StaffLeaveStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _statusColor(StaffLeaveStatus status) {
    switch (status) {
      case StaffLeaveStatus.pending:
        return Colors.orange;
      case StaffLeaveStatus.approved:
        return Colors.green;
      case StaffLeaveStatus.rejected:
        return Colors.red;
      case StaffLeaveStatus.cancelled:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(leave.status);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;

              final staffInformation = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.event_note_outlined,
                      color:
                          theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          leave.staffName.trim().isEmpty
                              ? 'Unnamed Staff Member'
                              : leave.staffName.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${leave.staffCode} • '
                          '${leave.designation}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              theme.textTheme.bodyMedium?.copyWith(
                            color: theme
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _leaveTypeLabel(leave.leaveType),
                          style:
                              theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final leaveInformation = Column(
                crossAxisAlignment: compact
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  Text(
                    leave.startDate.year == leave.endDate.year &&
                            leave.startDate.month ==
                                leave.endDate.month &&
                            leave.startDate.day ==
                                leave.endDate.day
                        ? _formatDate(leave.startDate)
                        : '${_formatDate(leave.startDate)} - '
                            '${_formatDate(leave.endDate)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${leave.totalDays.toStringAsFixed(
                      leave.totalDays == leave.totalDays.roundToDouble()
                          ? 0
                          : 1,
                    )} day(s) • ${_durationLabel(leave.duration)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    avatar: Icon(
                      leave.isApproved
                          ? Icons.check_circle_outline
                          : leave.isRejected
                              ? Icons.cancel_outlined
                              : leave.isCancelled
                                  ? Icons.block_outlined
                                  : Icons.pending_outlined,
                      size: 18,
                      color: statusColor,
                    ),
                    label: Text(
                      _statusLabel(leave.status),
                    ),
                    side: BorderSide.none,
                    backgroundColor:
                        statusColor.withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    staffInformation,
                    const SizedBox(height: 16),
                    leaveInformation,
                    if (trailing != null) ...[
                      const SizedBox(height: 14),
                      trailing!,
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 5,
                    child: staffInformation,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 3,
                    child: Text(
                      leave.reason.trim().isEmpty
                          ? 'No reason provided'
                          : leave.reason.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  leaveInformation,
                  if (trailing != null) ...[
                    const SizedBox(width: 16),
                    trailing!,
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
'@

# ============================================================
# FORM
# ============================================================

Write-ProjectFile `
    -RelativePath "lib\features\staff\presentation\widgets\staff_leave_form.dart" `
    -Content @'
import 'package:flutter/material.dart';

import '../../domain/entities/staff_entity.dart';
import '../../domain/entities/staff_leave_entity.dart';

class StaffLeaveFormData {
  const StaffLeaveFormData({
    required this.staff,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.duration,
    required this.totalDays,
    required this.reason,
  });

  final StaffEntity staff;
  final StaffLeaveType leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final StaffLeaveDuration duration;
  final double totalDays;
  final String reason;
}

class StaffLeaveForm extends StatefulWidget {
  const StaffLeaveForm({
    required this.staff,
    required this.onSubmit,
    super.key,
    this.isSaving = false,
  });

  final List<StaffEntity> staff;
  final Future<void> Function(StaffLeaveFormData data)
      onSubmit;
  final bool isSaving;

  @override
  State<StaffLeaveForm> createState() =>
      _StaffLeaveFormState();
}

class _StaffLeaveFormState extends State<StaffLeaveForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  StaffEntity? _selectedStaff;
  StaffLeaveType _leaveType = StaffLeaveType.casual;
  StaffLeaveDuration _duration =
      StaffLeaveDuration.fullDay;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Select date';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _leaveTypeLabel(StaffLeaveType type) {
    switch (type) {
      case StaffLeaveType.casual:
        return 'Casual Leave';
      case StaffLeaveType.sick:
        return 'Sick Leave';
      case StaffLeaveType.annual:
        return 'Annual Leave';
      case StaffLeaveType.unpaid:
        return 'Unpaid Leave';
      case StaffLeaveType.other:
        return 'Other Leave';
    }
  }

  String _durationLabel(StaffLeaveDuration duration) {
    switch (duration) {
      case StaffLeaveDuration.fullDay:
        return 'Full Day';
      case StaffLeaveDuration.halfDay:
        return 'Half Day';
    }
  }

  double get _totalDays {
    final startDate = _startDate;
    final endDate = _endDate;

    if (startDate == null || endDate == null) {
      return 0;
    }

    if (_duration == StaffLeaveDuration.halfDay) {
      return 0.5;
    }

    return endDate.difference(startDate).inDays + 1.0;
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      helpText: 'Select leave start date',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    final normalizedDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    setState(() {
      _startDate = normalizedDate;

      if (_duration == StaffLeaveDuration.halfDay) {
        _endDate = normalizedDate;
      } else if (_endDate == null ||
          _endDate!.isBefore(normalizedDate)) {
        _endDate = normalizedDate;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final startDate = _startDate;

    if (startDate == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Select start date first.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? startDate,
      firstDate: startDate,
      lastDate: DateTime(startDate.year + 2),
      helpText: 'Select leave end date',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
    });
  }

  Future<void> _submit() async {
    if (widget.isSaving ||
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final selectedStaff = _selectedStaff;
    final startDate = _startDate;
    final endDate = _endDate;

    if (selectedStaff == null) {
      _showMessage('Please select a staff member.');
      return;
    }

    if (startDate == null) {
      _showMessage('Please select start date.');
      return;
    }

    if (endDate == null) {
      _showMessage('Please select end date.');
      return;
    }

    if (endDate.isBefore(startDate)) {
      _showMessage('End date cannot be before start date.');
      return;
    }

    await widget.onSubmit(
      StaffLeaveFormData(
        staff: selectedStaff,
        leaveType: _leaveType,
        startDate: startDate,
        endDate: endDate,
        duration: _duration,
        totalDays: _totalDays,
        reason: _reasonController.text.trim(),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 14.0;
          final useTwoColumns = constraints.maxWidth >= 760;
          final fieldWidth = useTwoColumns
              ? (constraints.maxWidth - spacing) / 2
              : constraints.maxWidth;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<StaffEntity>(
                      initialValue: _selectedStaff,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Staff Member',
                        prefixIcon:
                            Icon(Icons.person_search_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: widget.staff.map((staffMember) {
                        return DropdownMenuItem(
                          value: staffMember,
                          child: Text(
                            '${staffMember.fullName} '
                            '(${staffMember.staffId})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null) {
                          return 'Staff member is required';
                        }

                        return null;
                      },
                      onChanged: widget.isSaving
                          ? null
                          : (value) {
                              setState(() {
                                _selectedStaff = value;
                              });
                            },
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<StaffLeaveType>(
                      initialValue: _leaveType,
                      decoration: const InputDecoration(
                        labelText: 'Leave Type',
                        prefixIcon:
                            Icon(Icons.category_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: StaffLeaveType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_leaveTypeLabel(type)),
                        );
                      }).toList(),
                      onChanged: widget.isSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _leaveType = value;
                                });
                              }
                            },
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child:
                        DropdownButtonFormField<StaffLeaveDuration>(
                      initialValue: _duration,
                      decoration: const InputDecoration(
                        labelText: 'Leave Duration',
                        prefixIcon: Icon(
                          Icons.timelapse_outlined,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      items:
                          StaffLeaveDuration.values.map((duration) {
                        return DropdownMenuItem(
                          value: duration,
                          child: Text(
                            _durationLabel(duration),
                          ),
                        );
                      }).toList(),
                      onChanged: widget.isSaving
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                _duration = value;

                                if (value ==
                                        StaffLeaveDuration
                                            .halfDay &&
                                    _startDate != null) {
                                  _endDate = _startDate;
                                }
                              });
                            },
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: OutlinedButton.icon(
                      onPressed:
                          widget.isSaving ? null : _pickStartDate,
                      icon: const Icon(
                        Icons.calendar_today_outlined,
                      ),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 17,
                        ),
                        child: Text(
                          'Start: ${_formatDate(_startDate)}',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: OutlinedButton.icon(
                      onPressed: widget.isSaving ||
                              _duration ==
                                  StaffLeaveDuration.halfDay
                          ? null
                          : _pickEndDate,
                      icon: const Icon(
                        Icons.event_outlined,
                      ),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 17,
                        ),
                        child: Text(
                          'End: ${_formatDate(_endDate)}',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Total Leave Days',
                        prefixIcon:
                            Icon(Icons.calculate_outlined),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _totalDays.toStringAsFixed(
                          _totalDays ==
                                  _totalDays.roundToDouble()
                              ? 0
                              : 1,
                        ),
                        style:
                            theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: constraints.maxWidth,
                    child: TextFormField(
                      controller: _reasonController,
                      enabled: !widget.isSaving,
                      maxLines: 4,
                      minLines: 3,
                      textCapitalization:
                          TextCapitalization.sentences,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Leave reason is required';
                        }

                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Leave Reason',
                        hintText:
                            'Enter the reason for this leave request',
                        prefixIcon: Icon(Icons.notes_outlined),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: widget.isSaving ? null : _submit,
                  icon: widget.isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    widget.isSaving
                        ? 'Saving...'
                        : 'Submit Leave Request',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
'@

# ============================================================
# ADD LEAVE PAGE
# ============================================================

Write-ProjectFile `
    -RelativePath "lib\features\staff\presentation\pages\add_staff_leave_page.dart" `
    -Content @'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/entities/staff_leave_entity.dart';
import '../../domain/repositories/staff_repository.dart';
import '../bloc/staff_leave_bloc.dart';
import '../bloc/staff_leave_event.dart';
import '../bloc/staff_leave_state.dart';
import '../widgets/staff_leave_form.dart';

class AddStaffLeavePage extends StatelessWidget {
  const AddStaffLeavePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffLeaveBloc>(
      create: (_) => sl<StaffLeaveBloc>(),
      child: const _AddStaffLeaveView(),
    );
  }
}

class _AddStaffLeaveView extends StatefulWidget {
  const _AddStaffLeaveView();

  @override
  State<_AddStaffLeaveView> createState() =>
      _AddStaffLeaveViewState();
}

class _AddStaffLeaveViewState
    extends State<_AddStaffLeaveView> {
  late final Future<List<StaffEntity>> _staffFuture;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _staffFuture = _loadStaff();
  }

  Future<List<StaffEntity>> _loadStaff() async {
    final staff = await sl<StaffRepository>().getStaff();

    final activeStaff = staff
        .where((staffMember) => staffMember.isActive)
        .toList();

    activeStaff.sort(
      (first, second) => first.fullName
          .toLowerCase()
          .compareTo(second.fullName.toLowerCase()),
    );

    return activeStaff;
  }

  Future<void> _saveLeave(
    StaffLeaveFormData data,
  ) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();
    final leaveId =
        '${data.staff.id}_${now.microsecondsSinceEpoch}';

    final leave = StaffLeaveEntity(
      id: leaveId,
      staffId: data.staff.id,
      staffCode: data.staff.staffId,
      staffName: data.staff.fullName,
      designation: data.staff.designation,
      leaveType: data.leaveType,
      startDate: data.startDate,
      endDate: data.endDate,
      duration: data.duration,
      totalDays: data.totalDays,
      reason: data.reason,
      status: StaffLeaveStatus.pending,
      approvalRemarks: '',
      approvedBy: '',
      createdAt: now,
      updatedAt: now,
    );

    context.read<StaffLeaveBloc>().add(
          SaveStaffLeaveEvent(leave),
        );
  }

  void _handleState(
    BuildContext context,
    StaffLeaveState state,
  ) {
    if (state is StaffLeaveError) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(state.message),
            behavior: SnackBarBehavior.floating,
          ),
        );

      return;
    }

    if (state is StaffLeaveLoaded &&
        state.successMessage != null) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StaffLeaveBloc, StaffLeaveState>(
      listener: _handleState,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Staff Leave'),
        ),
        body: SafeArea(
          child: FutureBuilder<List<StaffEntity>>(
            future: _staffFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return _LoadStaffError(
                  message: snapshot.error.toString(),
                );
              }

              final staff =
                  snapshot.data ?? const <StaffEntity>[];

              if (staff.isEmpty) {
                return const _NoStaffView();
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding =
                      constraints.maxWidth >= 1000
                          ? 32.0
                          : constraints.maxWidth >= 700
                              ? 24.0
                              : 16.0;

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 1000,
                      ),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          20,
                          horizontalPadding,
                          32,
                        ),
                        children: [
                          Card(
                            elevation: 0,
                            margin: EdgeInsets.zero,
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(18),
                              side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'New Leave Request',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight:
                                              FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Enter staff member and leave details.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 20),
                                  StaffLeaveForm(
                                    staff: staff,
                                    isSaving: _isSaving,
                                    onSubmit: _saveLeave,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoadStaffError extends StatelessWidget {
  const _LoadStaffError({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoStaffView extends StatelessWidget {
  const _NoStaffView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.group_off_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No active staff found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add or activate a staff member before creating leave.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
'@

# ============================================================
# APPROVAL PAGE
# ============================================================

Write-ProjectFile `
    -RelativePath "lib\features\staff\presentation\pages\staff_leave_approval_page.dart" `
    -Content @'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/staff_leave_entity.dart';
import '../bloc/staff_leave_bloc.dart';
import '../bloc/staff_leave_event.dart';
import '../bloc/staff_leave_state.dart';
import '../widgets/staff_leave_list_item.dart';

class StaffLeaveApprovalPage extends StatelessWidget {
  const StaffLeaveApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffLeaveBloc>(
      create: (_) => sl<StaffLeaveBloc>()
        ..add(const LoadPendingStaffLeavesEvent()),
      child: const _StaffLeaveApprovalView(),
    );
  }
}

class _StaffLeaveApprovalView extends StatelessWidget {
  const _StaffLeaveApprovalView();

  Future<void> _showDecisionDialog({
    required BuildContext context,
    required StaffLeaveEntity leave,
    required StaffLeaveStatus status,
  }) async {
    final remarksController = TextEditingController();
    final approvedByController = TextEditingController(
      text: 'Admin',
    );

    final result = await showDialog<_DecisionData>(
      context: context,
      builder: (dialogContext) {
        final isApproval =
            status == StaffLeaveStatus.approved;

        return AlertDialog(
          title: Text(
            isApproval
                ? 'Approve Leave Request'
                : 'Reject Leave Request',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${leave.staffName} • '
                  '${leave.totalDays.toStringAsFixed(
                    leave.totalDays ==
                            leave.totalDays.roundToDouble()
                        ? 0
                        : 1,
                  )} day(s)',
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: approvedByController,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Approved / Reviewed By',
                    prefixIcon:
                        Icon(Icons.admin_panel_settings_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: remarksController,
                  maxLines: 3,
                  textCapitalization:
                      TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: isApproval
                        ? 'Approval Remarks'
                        : 'Rejection Remarks',
                    prefixIcon: const Icon(
                      Icons.notes_outlined,
                    ),
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final approvedBy =
                    approvedByController.text.trim();

                if (approvedBy.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(
                  _DecisionData(
                    approvedBy: approvedBy,
                    remarks:
                        remarksController.text.trim(),
                  ),
                );
              },
              child: Text(
                isApproval ? 'Approve' : 'Reject',
              ),
            ),
          ],
        );
      },
    );

    remarksController.dispose();
    approvedByController.dispose();

    if (result == null || !context.mounted) {
      return;
    }

    context.read<StaffLeaveBloc>().add(
          UpdateStaffLeaveStatusEvent(
            leaveId: leave.id,
            status: status,
            approvalRemarks: result.remarks,
            approvedBy: result.approvedBy,
          ),
        );
  }

  void _handleState(
    BuildContext context,
    StaffLeaveState state,
  ) {
    if (state is StaffLeaveError) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(state.message),
            behavior: SnackBarBehavior.floating,
          ),
        );

      return;
    }

    if (state is StaffLeaveLoaded &&
        state.successMessage != null) {
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
    return BlocListener<StaffLeaveBloc, StaffLeaveState>(
      listener: _handleState,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pending Leave Approvals'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () {
                context.read<StaffLeaveBloc>().add(
                      const LoadPendingStaffLeavesEvent(),
                    );
              },
              icon: const Icon(Icons.refresh_outlined),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding =
                  constraints.maxWidth >= 1200
                      ? 32.0
                      : constraints.maxWidth >= 700
                          ? 24.0
                          : 16.0;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1200,
                  ),
                  child: BlocBuilder<
                      StaffLeaveBloc,
                      StaffLeaveState>(
                    builder: (context, state) {
                      if (state is StaffLeaveInitial ||
                          state is StaffLeaveLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (state is StaffLeaveError) {
                        return _ApprovalError(
                          message: state.message,
                          onRetry: () {
                            context.read<StaffLeaveBloc>().add(
                                  const LoadPendingStaffLeavesEvent(),
                                );
                          },
                        );
                      }

                      if (state is StaffLeaveLoaded) {
                        if (state.leaves.isEmpty) {
                          return const _NoPendingLeaves();
                        }

                        return ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            20,
                            horizontalPadding,
                            32,
                          ),
                          itemCount: state.leaves.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final leave = state.leaves[index];

                            return StaffLeaveListItem(
                              leave: leave,
                              trailing: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      _showDecisionDialog(
                                        context: context,
                                        leave: leave,
                                        status:
                                            StaffLeaveStatus
                                                .rejected,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                    ),
                                    label:
                                        const Text('Reject'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () {
                                      _showDecisionDialog(
                                        context: context,
                                        leave: leave,
                                        status:
                                            StaffLeaveStatus
                                                .approved,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.check_rounded,
                                    ),
                                    label:
                                        const Text('Approve'),
                                  ),
                                ],
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
            },
          ),
        ),
      ),
    );
  }
}

class _DecisionData {
  const _DecisionData({
    required this.approvedBy,
    required this.remarks,
  });

  final String approvedBy;
  final String remarks;
}

class _NoPendingLeaves extends StatelessWidget {
  const _NoPendingLeaves();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.task_alt_outlined,
              size: 70,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'No pending leave requests',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All staff leave requests have been reviewed.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalError extends StatelessWidget {
  const _ApprovalError({
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
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load pending leaves',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
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
    );
  }
}
'@

# ============================================================
# HISTORY PAGE
# ============================================================

Write-ProjectFile `
    -RelativePath "lib\features\staff\presentation\pages\staff_leave_history_page.dart" `
    -Content @'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/entities/staff_leave_entity.dart';
import '../../domain/repositories/staff_repository.dart';
import '../bloc/staff_leave_bloc.dart';
import '../bloc/staff_leave_event.dart';
import '../bloc/staff_leave_state.dart';
import '../widgets/staff_leave_list_item.dart';
import '../widgets/staff_leave_summary_card.dart';

class StaffLeaveHistoryPage extends StatelessWidget {
  const StaffLeaveHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffLeaveBloc>(
      create: (_) => sl<StaffLeaveBloc>(),
      child: const _StaffLeaveHistoryView(),
    );
  }
}

class _StaffLeaveHistoryView extends StatefulWidget {
  const _StaffLeaveHistoryView();

  @override
  State<_StaffLeaveHistoryView> createState() =>
      _StaffLeaveHistoryViewState();
}

class _StaffLeaveHistoryViewState
    extends State<_StaffLeaveHistoryView> {
  late final Future<List<StaffEntity>> _staffFuture;

  StaffEntity? _selectedStaff;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _startDate = DateTime(now.year, 1, 1);
    _endDate = DateTime(now.year, 12, 31);
    _staffFuture = _loadStaff();
  }

  Future<List<StaffEntity>> _loadStaff() async {
    final staff = await sl<StaffRepository>().getStaff();

    staff.sort(
      (first, second) => first.fullName
          .toLowerCase()
          .compareTo(second.fullName.toLowerCase()),
    );

    return staff;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  void _loadHistory() {
    final selectedStaff = _selectedStaff;

    if (selectedStaff == null) {
      return;
    }

    context.read<StaffLeaveBloc>().add(
          LoadStaffLeaveHistoryEvent(
            staffId: selectedStaff.id,
            startDate: _startDate,
            endDate: _endDate,
          ),
        );
  }

  Future<void> _pickStartDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
      helpText: 'Select history start date',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
    });

    _loadHistory();
  }

  Future<void> _pickEndDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(
        DateTime.now().year + 2,
        12,
        31,
      ),
      helpText: 'Select history end date',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
    });

    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Leave History'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _selectedStaff == null ? null : _loadHistory,
            icon: const Icon(Icons.refresh_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth >= 1200
                    ? 32.0
                    : constraints.maxWidth >= 700
                        ? 24.0
                        : 16.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1200,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        20,
                        horizontalPadding,
                        18,
                      ),
                      child: _HistoryFilters(
                        staffFuture: _staffFuture,
                        selectedStaff: _selectedStaff,
                        startDateLabel:
                            _formatDate(_startDate),
                        endDateLabel: _formatDate(_endDate),
                        onStaffChanged: (staff) {
                          setState(() {
                            _selectedStaff = staff;
                          });

                          _loadHistory();
                        },
                        onPickStartDate: _pickStartDate,
                        onPickEndDate: _pickEndDate,
                      ),
                    ),
                    Expanded(
                      child: BlocBuilder<
                          StaffLeaveBloc,
                          StaffLeaveState>(
                        builder: (context, state) {
                          if (_selectedStaff == null) {
                            return const _SelectStaffView();
                          }

                          if (state is StaffLeaveLoading) {
                            return const Center(
                              child:
                                  CircularProgressIndicator(),
                            );
                          }

                          if (state is StaffLeaveError) {
                            return _HistoryError(
                              message: state.message,
                              onRetry: _loadHistory,
                            );
                          }

                          if (state is StaffLeaveLoaded) {
                            return _HistoryContent(
                              leaves: state.leaves,
                              horizontalPadding:
                                  horizontalPadding,
                            );
                          }

                          return const _SelectStaffView();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HistoryFilters extends StatelessWidget {
  const _HistoryFilters({
    required this.staffFuture,
    required this.selectedStaff,
    required this.startDateLabel,
    required this.endDateLabel,
    required this.onStaffChanged,
    required this.onPickStartDate,
    required this.onPickEndDate,
  });

  final Future<List<StaffEntity>> staffFuture;
  final StaffEntity? selectedStaff;
  final String startDateLabel;
  final String endDateLabel;
  final ValueChanged<StaffEntity?> onStaffChanged;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 14.0;
            final columns =
                constraints.maxWidth >= 850 ? 3 : 1;
            final fieldWidth =
                (constraints.maxWidth -
                    spacing * (columns - 1)) /
                columns;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leave History Filters',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Select staff member and date range.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      child:
                          FutureBuilder<List<StaffEntity>>(
                        future: staffFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Staff Member',
                                border: OutlineInputBorder(),
                              ),
                              child:
                                  LinearProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return const InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Staff Member',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                'Unable to load staff',
                              ),
                            );
                          }

                          return DropdownButtonFormField<
                              StaffEntity>(
                            initialValue: selectedStaff,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Staff Member',
                              prefixIcon: Icon(
                                Icons.person_search_outlined,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            items: (snapshot.data ??
                                    const <StaffEntity>[])
                                .map((staffMember) {
                              return DropdownMenuItem(
                                value: staffMember,
                                child: Text(
                                  '${staffMember.fullName} '
                                  '(${staffMember.staffId})',
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: onStaffChanged,
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: OutlinedButton.icon(
                        onPressed: onPickStartDate,
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                        ),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 17,
                          ),
                          child: Text(
                            'From: $startDateLabel',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: OutlinedButton.icon(
                        onPressed: onPickEndDate,
                        icon: const Icon(
                          Icons.event_outlined,
                        ),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 17,
                          ),
                          child: Text(
                            'To: $endDateLabel',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({
    required this.leaves,
    required this.horizontalPadding,
  });

  final List<StaffLeaveEntity> leaves;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final approved = leaves
        .where((leave) => leave.isApproved)
        .toList();
    final rejected = leaves
        .where((leave) => leave.isRejected)
        .toList();
    final pending = leaves
        .where((leave) => leave.isPending)
        .toList();

    final approvedDays = approved.fold<double>(
      0,
      (total, leave) => total + leave.totalDays,
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        32,
      ),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 14.0;
            final columns =
                constraints.maxWidth >= 900 ? 4 : 2;
            final cardWidth =
                (constraints.maxWidth -
                    spacing * (columns - 1)) /
                columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: StaffLeaveSummaryCard(
                    title: 'Leave Requests',
                    value: leaves.length.toString(),
                    icon: Icons.event_note_outlined,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StaffLeaveSummaryCard(
                    title: 'Approved',
                    value: approved.length.toString(),
                    subtitle:
                        '${approvedDays.toStringAsFixed(
                      approvedDays ==
                              approvedDays.roundToDouble()
                          ? 0
                          : 1,
                    )} day(s)',
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.green,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StaffLeaveSummaryCard(
                    title: 'Pending',
                    value: pending.length.toString(),
                    icon: Icons.pending_outlined,
                    iconColor: Colors.orange,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StaffLeaveSummaryCard(
                    title: 'Rejected',
                    value: rejected.length.toString(),
                    icon: Icons.cancel_outlined,
                    iconColor: Colors.red,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        if (leaves.isEmpty)
          const _EmptyHistory()
        else
          ...leaves.map(
            (leave) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: StaffLeaveListItem(
                leave: leave,
              ),
            ),
          ),
      ],
    );
  }
}

class _SelectStaffView extends StatelessWidget {
  const _SelectStaffView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 70,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a staff member',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a staff member to view leave history.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 50,
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No leave history found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No leave requests exist for the selected period.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({
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
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load leave history',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
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
    );
  }
}
'@

# ============================================================
# MAIN LEAVE PAGE
# ============================================================

Write-ProjectFile `
    -RelativePath "lib\features\staff\presentation\pages\staff_leave_page.dart" `
    -Content @'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/staff_leave_entity.dart';
import '../bloc/staff_leave_bloc.dart';
import '../bloc/staff_leave_event.dart';
import '../bloc/staff_leave_state.dart';
import '../widgets/staff_leave_list_item.dart';
import '../widgets/staff_leave_summary_card.dart';
import 'add_staff_leave_page.dart';
import 'staff_leave_approval_page.dart';
import 'staff_leave_history_page.dart';

class StaffLeavePage extends StatelessWidget {
  const StaffLeavePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffLeaveBloc>(
      create: (_) => sl<StaffLeaveBloc>(),
      child: const _StaffLeaveView(),
    );
  }
}

class _StaffLeaveView extends StatefulWidget {
  const _StaffLeaveView();

  @override
  State<_StaffLeaveView> createState() =>
      _StaffLeaveViewState();
}

class _StaffLeaveViewState extends State<_StaffLeaveView> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadMonth();
      }
    });
  }

  bool get _canMoveNext {
    final now = DateTime.now();

    return _selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year &&
            _selectedMonth.month < now.month);
  }

  DateTime get _monthEnd {
    return DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    );
  }

  String _formatMonth(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  void _loadMonth() {
    context.read<StaffLeaveBloc>().add(
          LoadStaffLeavesByDateRangeEvent(
            startDate: _selectedMonth,
            endDate: _monthEnd,
          ),
        );
  }

  void _showPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );
    });

    _loadMonth();
  }

  void _showNextMonth() {
    if (!_canMoveNext) {
      return;
    }

    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );
    });

    _loadMonth();
  }

  void _showCurrentMonth() {
    final now = DateTime.now();

    setState(() {
      _selectedMonth = DateTime(
        now.year,
        now.month,
        1,
      );
    });

    _loadMonth();
  }

  Future<void> _openAddLeave() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const AddStaffLeavePage(),
      ),
    );

    if (saved == true && mounted) {
      _loadMonth();
    }
  }

  Future<void> _openApprovals() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            const StaffLeaveApprovalPage(),
      ),
    );

    if (mounted) {
      _loadMonth();
    }
  }

  void _openHistory() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            const StaffLeaveHistoryPage(),
      ),
    );
  }

  void _handleState(
    BuildContext context,
    StaffLeaveState state,
  ) {
    if (state is StaffLeaveError) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(state.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    if (state is StaffLeaveLoaded &&
        state.successMessage != null) {
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
    return BlocListener<StaffLeaveBloc, StaffLeaveState>(
      listener: _handleState,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Staff Leave Management'),
          actions: [
            IconButton(
              tooltip: 'Pending Approvals',
              onPressed: _openApprovals,
              icon: const Icon(
                Icons.approval_outlined,
              ),
            ),
            IconButton(
              tooltip: 'Leave History',
              onPressed: _openHistory,
              icon: const Icon(
                Icons.history_outlined,
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _loadMonth,
              icon: const Icon(
                Icons.refresh_outlined,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddLeave,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Leave'),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding =
                  constraints.maxWidth >= 1200
                      ? 32.0
                      : constraints.maxWidth >= 700
                          ? 24.0
                          : 16.0;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1200,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          20,
                          horizontalPadding,
                          18,
                        ),
                        child: _MonthHeader(
                          monthLabel:
                              _formatMonth(_selectedMonth),
                          canMoveNext: _canMoveNext,
                          onPrevious: _showPreviousMonth,
                          onNext: _showNextMonth,
                          onCurrentMonth:
                              _showCurrentMonth,
                        ),
                      ),
                      Expanded(
                        child: BlocBuilder<
                            StaffLeaveBloc,
                            StaffLeaveState>(
                          builder: (context, state) {
                            if (state is StaffLeaveInitial ||
                                state is StaffLeaveLoading) {
                              return const Center(
                                child:
                                    CircularProgressIndicator(),
                              );
                            }

                            if (state is StaffLeaveError) {
                              return _LeaveError(
                                message: state.message,
                                onRetry: _loadMonth,
                              );
                            }

                            if (state is StaffLeaveLoaded) {
                              return _LeaveContent(
                                leaves: state.leaves,
                                horizontalPadding:
                                    horizontalPadding,
                                onAddLeave: _openAddLeave,
                              );
                            }

                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.monthLabel,
    required this.canMoveNext,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrentMonth,
  });

  final String monthLabel;
  final bool canMoveNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCurrentMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;

            final information = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthLabel,
                  style:
                      theme.textTheme.headlineSmall?.copyWith(
                    color: theme
                        .colorScheme
                        .onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create, approve and review staff leave requests.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme
                        .colorScheme
                        .onPrimaryContainer,
                  ),
                ),
              ],
            );

            final controls = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                IconButton.outlined(
                  tooltip: 'Previous Month',
                  onPressed: onPrevious,
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onCurrentMonth,
                  icon: const Icon(
                    Icons.today_outlined,
                  ),
                  label: const Text('Current Month'),
                ),
                IconButton.outlined(
                  tooltip: 'Next Month',
                  onPressed:
                      canMoveNext ? onNext : null,
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                  ),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  information,
                  const SizedBox(height: 18),
                  controls,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: information),
                const SizedBox(width: 20),
                controls,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LeaveContent extends StatelessWidget {
  const _LeaveContent({
    required this.leaves,
    required this.horizontalPadding,
    required this.onAddLeave,
  });

  final List<StaffLeaveEntity> leaves;
  final double horizontalPadding;
  final VoidCallback onAddLeave;

  @override
  Widget build(BuildContext context) {
    final pending = leaves
        .where((leave) => leave.isPending)
        .toList();
    final approved = leaves
        .where((leave) => leave.isApproved)
        .toList();
    final rejected = leaves
        .where((leave) => leave.isRejected)
        .toList();

    final approvedDays = approved.fold<double>(
      0,
      (total, leave) => total + leave.totalDays,
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        96,
      ),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 14.0;
            final columns =
                constraints.maxWidth >= 1100
                    ? 4
                    : constraints.maxWidth >= 650
                        ? 2
                        : 1;
            final cardWidth =
                (constraints.maxWidth -
                    spacing * (columns - 1)) /
                columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: StaffLeaveSummaryCard(
                    title: 'Leave Requests',
                    value: leaves.length.toString(),
                    icon: Icons.event_note_outlined,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StaffLeaveSummaryCard(
                    title: 'Pending',
                    value: pending.length.toString(),
                    icon: Icons.pending_outlined,
                    iconColor: Colors.orange,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StaffLeaveSummaryCard(
                    title: 'Approved',
                    value: approved.length.toString(),
                    subtitle:
                        '${approvedDays.toStringAsFixed(
                      approvedDays ==
                              approvedDays.roundToDouble()
                          ? 0
                          : 1,
                    )} day(s)',
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.green,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StaffLeaveSummaryCard(
                    title: 'Rejected',
                    value: rejected.length.toString(),
                    icon: Icons.cancel_outlined,
                    iconColor: Colors.red,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        if (leaves.isEmpty)
          _EmptyLeaveView(
            onAddLeave: onAddLeave,
          )
        else
          ...leaves.map(
            (leave) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: StaffLeaveListItem(
                leave: leave,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyLeaveView extends StatelessWidget {
  const _EmptyLeaveView({
    required this.onAddLeave,
  });

  final VoidCallback onAddLeave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 50,
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 68,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No leave requests found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no leave requests for this month.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAddLeave,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Leave'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveError extends StatelessWidget {
  const _LeaveError({
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
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load staff leaves',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
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
    );
  }
}
'@

Write-Host ""
Write-Host "Phase 4A Staff Leave UI files created successfully." -ForegroundColor Cyan
Write-Host "Existing dashboard and Sidebar files were not changed." -ForegroundColor Yellow
Write-Host ""
