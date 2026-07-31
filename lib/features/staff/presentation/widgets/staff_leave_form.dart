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