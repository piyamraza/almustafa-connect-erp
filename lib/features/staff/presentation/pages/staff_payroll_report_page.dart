import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../core/di/service_locator.dart';
import '../bloc/staff_salary_bloc.dart';
import '../bloc/staff_salary_event.dart';
import '../bloc/staff_salary_state.dart';
import '../services/staff_payroll_report_service.dart';

class StaffPayrollReportPage extends StatelessWidget {
  const StaffPayrollReportPage({
    required this.salaryMonth,
    super.key,
  });

  final DateTime salaryMonth;

  String _fileName() {
    final month =
        salaryMonth.month.toString().padLeft(2, '0');

    return 'Staff_Payroll_Report_'
        '${salaryMonth.year}_$month.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffSalaryBloc>(
      create: (_) => sl<StaffSalaryBloc>()
        ..add(
          LoadStaffSalariesByMonthEvent(
            salaryMonth,
          ),
        ),
      child: Scaffold(
        appBar: AppBar(actions: const [DashboardNavigationButton()],
          title: const Text('Monthly Payroll Report'),
        ),
        body: BlocBuilder<
            StaffSalaryBloc,
            StaffSalaryState>(
          builder: (context, state) {
            if (state is StaffSalaryInitial ||
                state is StaffSalaryLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is StaffSalaryError) {
              return _ReportErrorView(
                message: state.message,
                onRetry: () {
                  context.read<StaffSalaryBloc>().add(
                        LoadStaffSalariesByMonthEvent(
                          salaryMonth,
                        ),
                      );
                },
              );
            }

            if (state is StaffSalaryLoaded) {
              if (state.salaries.isEmpty) {
                return const _EmptyReportView();
              }

              return PdfPreview(
                pdfFileName: _fileName(),
                initialPageFormat:
                    PdfPageFormat.a4.landscape,
                canChangeOrientation: true,
                canChangePageFormat: true,
                allowPrinting: true,
                allowSharing: true,
                build: (pageFormat) {
                  return StaffPayrollReportService
                      .buildMonthlyPayrollPdf(
                    salaries: state.salaries,
                    salaryMonth: salaryMonth,
                    pageFormat: pageFormat,
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _EmptyReportView extends StatelessWidget {
  const _EmptyReportView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.description_outlined,
              size: 70,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No payroll records found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate salaries for this month before opening the payroll report.',
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

class _ReportErrorView extends StatelessWidget {
  const _ReportErrorView({
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
              'Unable to load payroll report',
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