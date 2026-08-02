import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/manual_date_picker.dart';

import '../../domain/entities/staff_leave_entity.dart';
import '../../../teachers/domain/entities/teacher_entity.dart';

enum TeacherLeaveType { leave, unpaidLeave }

class TeacherLeaveFormData {
  const TeacherLeaveFormData({
    required this.teacher,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.duration,
    required this.totalDays,
    required this.reason,
  });

  final TeacherEntity teacher;
  final TeacherLeaveType leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final StaffLeaveDuration duration;
  final double totalDays;
  final String reason;

  StaffLeaveType get staffLeaveType {
    return leaveType == TeacherLeaveType.unpaidLeave
        ? StaffLeaveType.unpaid
        : StaffLeaveType.other;
  }
}

class TeacherLeaveForm extends StatefulWidget {
  const TeacherLeaveForm({
    required this.teachers,
    required this.onSubmit,
    super.key,
    this.isSaving = false,
  });

  final List<TeacherEntity> teachers;
  final Future<void> Function(TeacherLeaveFormData data) onSubmit;
  final bool isSaving;

  @override
  State<TeacherLeaveForm> createState() => _TeacherLeaveFormState();
}

class _TeacherLeaveFormState extends State<TeacherLeaveForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  TeacherEntity? _selectedTeacher;
  TeacherLeaveType _leaveType = TeacherLeaveType.leave;
  StaffLeaveDuration _duration = StaffLeaveDuration.fullDay;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
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

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Select date';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();

    final selected = await showManualDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      helpText: 'Select leave start date',
    );

    if (selected == null || !mounted) {
      return;
    }

    final normalized = DateTime(selected.year, selected.month, selected.day);

    setState(() {
      _startDate = normalized;

      if (_duration == StaffLeaveDuration.halfDay) {
        _endDate = normalized;
      } else if (_endDate == null || _endDate!.isBefore(normalized)) {
        _endDate = normalized;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final startDate = _startDate;

    if (startDate == null) {
      _showMessage('Select start date first.');
      return;
    }

    final selected = await showManualDatePicker(
      context: context,
      initialDate: _endDate ?? startDate,
      firstDate: startDate,
      lastDate: DateTime(startDate.year + 2),
      helpText: 'Select leave end date',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = DateTime(selected.year, selected.month, selected.day);
    });
  }

  Future<void> _submit() async {
    if (widget.isSaving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final teacher = _selectedTeacher;
    final startDate = _startDate;
    final endDate = _endDate;

    if (teacher == null) {
      _showMessage('Please select a teacher.');
      return;
    }

    if (startDate == null || endDate == null) {
      _showMessage('Please select leave dates.');
      return;
    }

    await widget.onSubmit(
      TeacherLeaveFormData(
        teacher: teacher,
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
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
          final twoColumns = constraints.maxWidth >= 760;
          final fieldWidth = twoColumns
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
                    child: DropdownButtonFormField<TeacherEntity>(
                      initialValue: _selectedTeacher,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Teacher',
                        prefixIcon: Icon(Icons.school_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: widget.teachers.map((teacher) {
                        return DropdownMenuItem<TeacherEntity>(
                          value: teacher,
                          child: Text(
                            '${teacher.fullName} '
                            '(${teacher.employeeId})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      validator: (value) {
                        return value == null ? 'Teacher is required' : null;
                      },
                      onChanged: widget.isSaving
                          ? null
                          : (value) {
                              setState(() {
                                _selectedTeacher = value;
                              });
                            },
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<TeacherLeaveType>(
                      initialValue: _leaveType,
                      decoration: const InputDecoration(
                        labelText: 'Leave Type',
                        prefixIcon: Icon(Icons.category_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: TeacherLeaveType.leave,
                          child: Text('Leave'),
                        ),
                        DropdownMenuItem(
                          value: TeacherLeaveType.unpaidLeave,
                          child: Text('Unpaid Leave'),
                        ),
                      ],
                      onChanged: widget.isSaving
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                _leaveType = value;
                              });
                            },
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<StaffLeaveDuration>(
                      initialValue: _duration,
                      decoration: const InputDecoration(
                        labelText: 'Leave Duration',
                        prefixIcon: Icon(Icons.timelapse_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: StaffLeaveDuration.fullDay,
                          child: Text('Full Day'),
                        ),
                        DropdownMenuItem(
                          value: StaffLeaveDuration.halfDay,
                          child: Text('Half Day'),
                        ),
                      ],
                      onChanged: widget.isSaving
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                _duration = value;

                                if (value == StaffLeaveDuration.halfDay &&
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
                      onPressed: widget.isSaving ? null : _pickStartDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        child: Text('Start: ${_formatDate(_startDate)}'),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: OutlinedButton.icon(
                      onPressed:
                          widget.isSaving ||
                              _duration == StaffLeaveDuration.halfDay
                          ? null
                          : _pickEndDate,
                      icon: const Icon(Icons.event_outlined),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        child: Text('End: ${_formatDate(_endDate)}'),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Total Leave Days',
                        prefixIcon: Icon(Icons.calculate_outlined),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _totalDays.toStringAsFixed(
                          _totalDays == _totalDays.roundToDouble() ? 0 : 1,
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
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
                      minLines: 3,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        return (value ?? '').trim().isEmpty
                            ? 'Leave reason is required'
                            : null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Leave Reason',
                        hintText: 'Enter the reason for this leave request',
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    widget.isSaving ? 'Saving...' : 'Submit Leave Request',
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
