import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/usecases/generate_staff_id.dart';
import '../bloc/staff_bloc.dart';
import '../bloc/staff_event.dart';
import '../bloc/staff_state.dart';
import '../widgets/staff_form.dart';

class AddStaffPage extends StatelessWidget {
  const AddStaffPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffBloc>(
      create: (_) => sl<StaffBloc>(),
      child: const _AddStaffView(),
    );
  }
}

class _AddStaffView extends StatefulWidget {
  const _AddStaffView();

  @override
  State<_AddStaffView> createState() => _AddStaffViewState();
}

class _AddStaffViewState extends State<_AddStaffView> {
  final GenerateStaffId _generateStaffId = sl<GenerateStaffId>();

  bool _isSubmitting = false;
  bool _submissionStarted = false;

  Future<void> _submitStaff(StaffFormData data) async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submissionStarted = true;
    });

    final now = DateTime.now();
    final documentId = _generateStaffId();
    final readableStaffId = 'STF${now.millisecondsSinceEpoch}';

    final staff = StaffEntity(
      id: documentId,
      staffId: readableStaffId,
      firstName: data.firstName,
      lastName: data.lastName,
      fatherName: data.fatherName,
      dateOfBirth: data.dateOfBirth,
      cnic: data.cnic,
      phone: data.phone,
      whatsappNumber: data.whatsappNumber,
      address: data.address,
      designation: data.designation,
      joiningDate: data.joiningDate,
      monthlySalary: data.monthlySalary,
      profileImageUrl: data.profileImageUrl,
      isActive: data.isActive,
      createdAt: now,
      updatedAt: now,
    );

    context.read<StaffBloc>().add(AddStaffEvent(staff));
  }

  void _handleState(BuildContext context, StaffState state) {
    if (!_submissionStarted) {
      return;
    }

    if (state is StaffLoaded &&
        state.successMessage == 'Staff member added successfully.') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.successMessage!),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(true);
      return;
    }

    if (state is StaffError) {
      setState(() {
        _isSubmitting = false;
        _submissionStarted = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StaffBloc, StaffState>(
      listener: _handleState,
      child: Scaffold(
        appBar: AppBar(
          actions: const [DashboardNavigationButton()],
          title: const Text('Add Staff'),
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
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: StaffForm(
                      onSubmit: _submitStaff,
                      submitLabel: 'Save Staff',
                      isSubmitting: _isSubmitting,
                    ),
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
