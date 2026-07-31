import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StaffSalaryAdjustmentData {
  const StaffSalaryAdjustmentData({
    required this.allowance,
    required this.deduction,
    required this.attendanceDeduction,
    required this.remarks,
  });

  final double allowance;
  final double deduction;
  final double attendanceDeduction;
  final String remarks;
}

class StaffSalaryAdjustmentForm extends StatefulWidget {
  const StaffSalaryAdjustmentForm({
    required this.initialAllowance,
    required this.initialDeduction,
    required this.initialAttendanceDeduction,
    required this.initialRemarks,
    required this.onSubmit,
    super.key,
    this.isSaving = false,
  });

  final double initialAllowance;
  final double initialDeduction;
  final double initialAttendanceDeduction;
  final String initialRemarks;
  final Future<void> Function(
    StaffSalaryAdjustmentData data,
  ) onSubmit;
  final bool isSaving;

  @override
  State<StaffSalaryAdjustmentForm> createState() =>
      _StaffSalaryAdjustmentFormState();
}

class _StaffSalaryAdjustmentFormState
    extends State<StaffSalaryAdjustmentForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _allowanceController;
  late final TextEditingController _deductionController;
  late final TextEditingController
      _attendanceDeductionController;
  late final TextEditingController _remarksController;

  @override
  void initState() {
    super.initState();

    _allowanceController = TextEditingController(
      text: _numberText(widget.initialAllowance),
    );
    _deductionController = TextEditingController(
      text: _numberText(widget.initialDeduction),
    );
    _attendanceDeductionController = TextEditingController(
      text: _numberText(widget.initialAttendanceDeduction),
    );
    _remarksController = TextEditingController(
      text: widget.initialRemarks,
    );
  }

  @override
  void didUpdateWidget(
    covariant StaffSalaryAdjustmentForm oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialAllowance != widget.initialAllowance) {
      _allowanceController.text =
          _numberText(widget.initialAllowance);
    }

    if (oldWidget.initialDeduction != widget.initialDeduction) {
      _deductionController.text =
          _numberText(widget.initialDeduction);
    }

    if (oldWidget.initialAttendanceDeduction !=
        widget.initialAttendanceDeduction) {
      _attendanceDeductionController.text =
          _numberText(widget.initialAttendanceDeduction);
    }

    if (oldWidget.initialRemarks != widget.initialRemarks) {
      _remarksController.text = widget.initialRemarks;
    }
  }

  @override
  void dispose() {
    _allowanceController.dispose();
    _deductionController.dispose();
    _attendanceDeductionController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  String _numberText(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  double _parseAmount(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  String? _validateAmount(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    final parsedValue = double.tryParse(text);

    if (parsedValue == null) {
      return 'Enter a valid amount';
    }

    if (parsedValue < 0) {
      return 'Amount cannot be negative';
    }

    return null;
  }

  Future<void> _submit() async {
    if (widget.isSaving ||
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await widget.onSubmit(
      StaffSalaryAdjustmentData(
        allowance: _parseAmount(
          _allowanceController.text,
        ),
        deduction: _parseAmount(
          _deductionController.text,
        ),
        attendanceDeduction: _parseAmount(
          _attendanceDeductionController.text,
        ),
        remarks: _remarksController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 14.0;
          final useTwoColumns = constraints.maxWidth >= 700;
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
                    child: TextFormField(
                      controller: _allowanceController,
                      enabled: !widget.isSaving,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      validator: _validateAmount,
                      decoration: const InputDecoration(
                        labelText: 'Allowance',
                        prefixText: 'Rs. ',
                        prefixIcon:
                            Icon(Icons.add_card_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: TextFormField(
                      controller: _deductionController,
                      enabled: !widget.isSaving,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      validator: _validateAmount,
                      decoration: const InputDecoration(
                        labelText: 'Other Deduction',
                        prefixText: 'Rs. ',
                        prefixIcon:
                            Icon(Icons.remove_circle_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: TextFormField(
                      controller:
                          _attendanceDeductionController,
                      enabled: !widget.isSaving,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      validator: _validateAmount,
                      decoration: const InputDecoration(
                        labelText: 'Attendance Deduction',
                        prefixText: 'Rs. ',
                        prefixIcon:
                            Icon(Icons.event_busy_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: TextFormField(
                      controller: _remarksController,
                      enabled: !widget.isSaving,
                      textCapitalization:
                          TextCapitalization.sentences,
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(
                        labelText: 'Remarks',
                        prefixIcon: Icon(Icons.notes_outlined),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
                        : 'Save Adjustments',
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