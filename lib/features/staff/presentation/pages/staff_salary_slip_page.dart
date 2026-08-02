import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:printing/printing.dart';

import '../../domain/entities/staff_salary_entity.dart';
import '../services/staff_payroll_report_service.dart';

class StaffSalarySlipPage extends StatelessWidget {
  const StaffSalarySlipPage({
    required this.salary,
    super.key,
  });

  final StaffSalaryEntity salary;

  String _fileName() {
    final month =
        salary.salaryMonth.month.toString().padLeft(2, '0');

    final safeStaffCode = salary.staffCode
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

    return 'Salary_Slip_${safeStaffCode}_'
        '${salary.salaryMonth.year}_$month.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: const [DashboardNavigationButton()],
        title: const Text('Salary Slip'),
      ),
      body: PdfPreview(
        pdfFileName: _fileName(),
        canChangeOrientation: false,
        canChangePageFormat: true,
        allowPrinting: true,
        allowSharing: true,
        build: (pageFormat) {
          return StaffPayrollReportService.buildSalarySlipPdf(
            salary: salary,
            pageFormat: pageFormat,
          );
        },
      ),
    );
  }
}