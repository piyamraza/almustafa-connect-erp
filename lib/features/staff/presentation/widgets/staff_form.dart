import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/manual_date_picker.dart';
import 'package:flutter/services.dart';

class StaffFormData {
  const StaffFormData({
    required this.firstName,
    required this.lastName,
    required this.fatherName,
    required this.cnic,
    required this.phone,
    required this.address,
    required this.designation,
    required this.joiningDate,
    required this.monthlySalary,
    required this.profileImageUrl,
    required this.isActive,
  });

  final String firstName;
  final String lastName;
  final String fatherName;
  final String cnic;
  final String phone;
  final String address;
  final String designation;
  final DateTime joiningDate;
  final double monthlySalary;
  final String profileImageUrl;
  final bool isActive;
}

class StaffForm extends StatefulWidget {
  const StaffForm({
    required this.onSubmit,
    super.key,
    this.initialData,
    this.submitLabel = 'Save Staff',
    this.isSubmitting = false,
  });

  final StaffFormData? initialData;
  final Future<void> Function(StaffFormData data) onSubmit;
  final String submitLabel;
  final bool isSubmitting;

  @override
  State<StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends State<StaffForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _fatherNameController;
  late final TextEditingController _cnicController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _designationController;
  late final TextEditingController _joiningDateController;
  late final TextEditingController _salaryController;

  DateTime? _joiningDate;
  bool _isActive = true;
  bool _isSubmittingInternally = false;

  @override
  void initState() {
    super.initState();

    final initialData = widget.initialData;

    _firstNameController = TextEditingController(
      text: initialData?.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: initialData?.lastName ?? '',
    );
    _fatherNameController = TextEditingController(
      text: initialData?.fatherName ?? '',
    );
    _cnicController = TextEditingController(
      text: initialData?.cnic ?? '',
    );
    _phoneController = TextEditingController(
      text: initialData?.phone ?? '',
    );
    _addressController = TextEditingController(
      text: initialData?.address ?? '',
    );
    _designationController = TextEditingController(
      text: initialData?.designation ?? '',
    );
    _salaryController = TextEditingController(
      text: initialData == null
          ? ''
          : initialData.monthlySalary.toStringAsFixed(
              initialData.monthlySalary % 1 == 0 ? 0 : 2,
            ),
    );

    _joiningDate = initialData?.joiningDate;
    _joiningDateController = TextEditingController(
      text: _joiningDate == null ? '' : _formatDate(_joiningDate!),
    );

    _isActive = initialData?.isActive ?? true;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _fatherNameController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _designationController.dispose();
    _joiningDateController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day-$month-${date.year}';
  }

  Future<void> _pickJoiningDate() async {
    final now = DateTime.now();

    final selectedDate = await showManualDatePicker(
      context: context,
      initialDate: _joiningDate ?? now,
      firstDate: DateTime(1980),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'Select joining date',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _joiningDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      _joiningDateController.text = _formatDate(_joiningDate!);
    });
  }

  String? _validateRequired(
    String? value,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }

    return null;
  }

  String? _validateCnic(String? value) {
    final requiredError = _validateRequired(value, 'CNIC');

    if (requiredError != null) {
      return requiredError;
    }

    if (value!.trim().length != 13) {
      return 'CNIC must contain exactly 13 digits.';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final requiredError = _validateRequired(value, 'Phone number');

    if (requiredError != null) {
      return requiredError;
    }

    if (value!.trim().length != 11) {
      return 'Phone number must contain exactly 11 digits.';
    }

    return null;
  }

  String? _validateSalary(String? value) {
    final requiredError = _validateRequired(value, 'Monthly salary');

    if (requiredError != null) {
      return requiredError;
    }

    final salary = double.tryParse(value!.trim());

    if (salary == null || salary <= 0) {
      return 'Enter a valid monthly salary.';
    }

    return null;
  }

  Future<void> _submitForm() async {
    if (_isSubmittingInternally || widget.isSubmitting) {
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    if (_joiningDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the joining date.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmittingInternally = true;
    });

    final data = StaffFormData(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      fatherName: _fatherNameController.text.trim(),
      cnic: _cnicController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      designation: _designationController.text.trim(),
      joiningDate: _joiningDate!,
      monthlySalary: double.parse(_salaryController.text.trim()),
      profileImageUrl: widget.initialData?.profileImageUrl ?? '',
      isActive: _isActive,
    );

    try {
      await widget.onSubmit(data);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingInternally = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBusy = widget.isSubmitting || _isSubmittingInternally;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FormSection(
            title: 'Personal Information',
            subtitle: 'Enter the staff member’s basic information.',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useTwoColumns = constraints.maxWidth >= 700;
                final fieldWidth = useTwoColumns
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      child: TextFormField(
                        controller: _firstNameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'First Name *',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          return _validateRequired(value, 'First name');
                        },
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: TextFormField(
                        controller: _lastNameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: TextFormField(
                        controller: _fatherNameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Father Name *',
                          prefixIcon: Icon(Icons.family_restroom_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          return _validateRequired(value, 'Father name');
                        },
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: TextFormField(
                        controller: _cnicController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(13),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'CNIC *',
                          hintText: '3520212345671',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateCnic,
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          hintText: '03001234567',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: _validatePhone,
                      ),
                    ),
                    SizedBox(
                      width: useTwoColumns
                          ? constraints.maxWidth
                          : fieldWidth,
                      child: TextFormField(
                        controller: _addressController,
                        minLines: 2,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Address *',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          return _validateRequired(value, 'Address');
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          _FormSection(
            title: 'Employment Information',
            subtitle: 'Enter designation, joining date and salary.',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useTwoColumns = constraints.maxWidth >= 700;
                final fieldWidth = useTwoColumns
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      child: TextFormField(
                        controller: _designationController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Designation *',
                          hintText: 'Accountant, Clerk, Guard',
                          prefixIcon: Icon(Icons.work_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          return _validateRequired(value, 'Designation');
                        },
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: TextFormField(
                        controller: _joiningDateController,
                        readOnly: true,
                        onTap: isBusy ? null : _pickJoiningDate,
                        decoration: InputDecoration(
                          labelText: 'Joining Date *',
                          prefixIcon:
                              const Icon(Icons.calendar_month_outlined),
                          suffixIcon: IconButton(
                            tooltip: 'Select date',
                            onPressed: isBusy ? null : _pickJoiningDate,
                            icon: const Icon(Icons.date_range_outlined),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          return _validateRequired(value, 'Joining date');
                        },
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: TextFormField(
                        controller: _salaryController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Monthly Salary *',
                          prefixText: 'Rs. ',
                          prefixIcon: Icon(Icons.payments_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateSalary,
                        onFieldSubmitted: (_) => _submitForm(),
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 58),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SwitchListTile(
                          value: _isActive,
                          onChanged: isBusy
                              ? null
                              : (value) {
                                  setState(() {
                                    _isActive = value;
                                  });
                                },
                          title: const Text('Active Staff Member'),
                          subtitle: Text(
                            _isActive
                                ? 'Staff member is currently active.'
                                : 'Staff member is currently inactive.',
                          ),
                          secondary: Icon(
                            _isActive
                                ? Icons.check_circle_outline
                                : Icons.cancel_outlined,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: isBusy ? null : _submitForm,
              icon: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                isBusy ? 'Saving...' : widget.submitLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}