import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/staff_entity.dart';
import '../bloc/staff_bloc.dart';
import '../bloc/staff_event.dart';
import '../bloc/staff_state.dart';
import '../widgets/staff_form.dart';

class EditStaffPage extends StatelessWidget {
  const EditStaffPage({required this.staff, super.key});

  final StaffEntity staff;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffBloc>(
      create: (_) => sl<StaffBloc>(),
      child: _EditStaffView(staff: staff),
    );
  }
}

class _EditStaffView extends StatefulWidget {
  const _EditStaffView({required this.staff});

  final StaffEntity staff;

  @override
  State<_EditStaffView> createState() => _EditStaffViewState();
}

class _EditStaffViewState extends State<_EditStaffView> {
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

    final updatedStaff = widget.staff.copyWith(
      firstName: data.firstName,
      lastName: data.lastName,
      fatherName: data.fatherName,
      cnic: data.cnic,
      phone: data.phone,
      whatsappNumber: data.whatsappNumber,
      address: data.address,
      designation: data.designation,
      joiningDate: data.joiningDate,
      monthlySalary: data.monthlySalary,
      profileImageUrl: data.profileImageUrl,
      isActive: data.isActive,
      updatedAt: DateTime.now(),
    );

    context.read<StaffBloc>().add(UpdateStaffEvent(updatedStaff));
  }

  void _handleState(BuildContext context, StaffState state) {
    if (!_submissionStarted) {
      return;
    }

    if (state is StaffLoaded &&
        state.successMessage == 'Staff member updated successfully.') {
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
    final initialData = StaffFormData(
      firstName: widget.staff.firstName,
      lastName: widget.staff.lastName,
      fatherName: widget.staff.fatherName,
      cnic: widget.staff.cnic,
      phone: widget.staff.phone,
      whatsappNumber: widget.staff.whatsappNumber,
      address: widget.staff.address,
      designation: widget.staff.designation,
      joiningDate: widget.staff.joiningDate,
      monthlySalary: widget.staff.monthlySalary,
      profileImageUrl: widget.staff.profileImageUrl,
      isActive: widget.staff.isActive,
    );

    return BlocListener<StaffBloc, StaffState>(
      listener: _handleState,
      child: Scaffold(
        appBar: AppBar(
          actions: const [DashboardNavigationButton()],
          title: const Text('Edit Staff'),
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
                      initialData: initialData,
                      onSubmit: _submitStaff,
                      submitLabel: 'Update Staff',
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
