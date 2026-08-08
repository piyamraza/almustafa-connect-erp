import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../settings/domain/entities/school_settings_entity.dart';
import '../../../settings/domain/usecases/manage_settings.dart';
import '../../../staff/domain/entities/staff_salary_entity.dart';
import '../../../accounts/domain/entities/payroll_profile_entity.dart';
import '../../../accounts/domain/entities/payroll_record_entity.dart';
import '../../../accounts/domain/repositories/accounts_repository.dart';
import '../../domain/entities/document_branding_entity.dart';
import '../../domain/entities/document_data_entity.dart';
import '../../domain/entities/document_type.dart';
import '../../domain/services/default_document_placeholder_resolver.dart';
import '../../templates/salary_slip/salary_slip_template_v1.dart';
import '../export/document_export_service.dart';
import '../renderer/document_element_visibility_resolver.dart';
import '../renderer/document_render_context.dart';
import '../renderer/document_renderer_registry_factory.dart';
import '../renderer/flutter_document_renderer.dart';
import '../renderer/widgets/document_canvas.dart';

const _pageBackground = Color(0xFFF5F7FA);
const _textPrimary = Color(0xFF182230);
const _textSecondary = Color(0xFF667085);
const _borderColor = Color(0xFFE1E6ED);

class SalarySlipPreviewPage extends StatefulWidget {
  const SalarySlipPreviewPage({
    super.key,
  });

  @override
  State<SalarySlipPreviewPage> createState() =>
      _SalarySlipPreviewPageState();
}

class _SalarySlipPreviewPageState
    extends State<SalarySlipPreviewPage> {
  final GlobalKey _documentBoundaryKey = GlobalKey();

  final DocumentExportService _exportService =
      const DocumentExportService();

  late Future<SchoolSettingsEntity> _settingsFuture;
  late Future<List<StaffSalaryEntity>> _salaryFuture;

  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month);

  StaffSalaryEntity? _selectedSalary;

  bool _exporting = false;

  @override
  void initState() {
    super.initState();

    _settingsFuture = sl<GetSchoolSettings>()();
    _salaryFuture = _loadSalaries();
  }

  Future<List<StaffSalaryEntity>> _loadSalaries() async {
    final payrollRecords =
        await sl<AccountsRepository>().getPayrollRecords();

    final monthRecords = payrollRecords.where((record) {
      return record.payrollMonth.year == _selectedMonth.year &&
          record.payrollMonth.month == _selectedMonth.month &&
          record.paymentStatus != PayrollPaymentStatus.cancelled;
    }).toList();

    final salaries = monthRecords.map((record) {
      return StaffSalaryEntity(
        id: record.id,
        staffId: record.employeeId,
        staffCode: record.employeeId,
        staffName: record.employeeName,
        designation: _employeeTypeLabel(record.employeeType),
        salaryMonth: DateTime(
          record.payrollMonth.year,
          record.payrollMonth.month,
        ),
        basicSalary: record.basicSalary.toDouble(),
        allowance: (record.allowances + record.bonus).toDouble(),
        deduction: (record.deductions +
                record.advanceDeduction +
                record.loanDeduction)
            .toDouble(),
        attendanceDeduction: record.absenceDeduction.toDouble(),
        grossSalary: record.grossSalary.toDouble(),
        netSalary: record.netSalary.toDouble(),
        presentDays: 0,
        absentDays: 0,
        lateDays: 0,
        leaveDays: 0,
        paymentStatus:
            record.paymentStatus == PayrollPaymentStatus.paid
                ? StaffSalaryPaymentStatus.paid
                : StaffSalaryPaymentStatus.unpaid,
        paymentDate: record.paymentDate,
        paymentMethod: _mapPaymentMethod(record.paymentMethod),
        paymentReference: record.referenceNumber,
        remarks: record.remarks,
        createdAt: record.createdAt,
        updatedAt: record.updatedAt,
      );
    }).toList();

    salaries.sort(
      (a, b) => a.staffName
          .toLowerCase()
          .compareTo(b.staffName.toLowerCase()),
    );

    return salaries;
  }

  String _employeeTypeLabel(PayrollEmployeeType type) {
    return switch (type) {
      PayrollEmployeeType.teacher => 'Teacher',
      PayrollEmployeeType.administrativeStaff => 'Administrative Staff',
      PayrollEmployeeType.supportStaff => 'Support Staff',
      PayrollEmployeeType.other => 'Staff',
    };
  }

  StaffSalaryPaymentMethod? _mapPaymentMethod(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('-', '');

    if (normalized.isEmpty) {
      return null;
    }

    return switch (normalized) {
      'cash' => StaffSalaryPaymentMethod.cash,
      'bank' || 'banktransfer' => StaffSalaryPaymentMethod.bankTransfer,
      'easypaisa' => StaffSalaryPaymentMethod.easypaisa,
      'jazzcash' => StaffSalaryPaymentMethod.jazzCash,
      'cheque' || 'check' => StaffSalaryPaymentMethod.cheque,
      _ => StaffSalaryPaymentMethod.other,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: FutureBuilder<SchoolSettingsEntity>(
                future: _settingsFuture,
                builder: (
                  context,
                  settingsSnapshot,
                ) {
                  if (settingsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (settingsSnapshot.hasError ||
                      settingsSnapshot.data == null) {
                    return _Failure(
                      message:
                          settingsSnapshot.error?.toString() ??
                              'School settings could not be loaded.',
                      onRetry: _reloadSettings,
                    );
                  }

                  return FutureBuilder<List<StaffSalaryEntity>>(
                    future: _salaryFuture,
                    builder: (
                      context,
                      salarySnapshot,
                    ) {
                      if (salarySnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (salarySnapshot.hasError) {
                        return _Failure(
                          message:
                              salarySnapshot.error.toString(),
                          onRetry: _reloadSalaries,
                        );
                      }

                      return _buildBody(
                        settingsSnapshot.data!,
                        salarySnapshot.data ??
                            const <StaffSalaryEntity>[],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    SchoolSettingsEntity settings,
    List<StaffSalaryEntity> salaries,
  ) {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final wide = constraints.maxWidth >= 900;

        final selector = _buildSelector(salaries);

        final preview = _selectedSalary == null
            ? const _EmptyPreview()
            : _buildPreview(settings);

        if (!wide) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                selector,
                const SizedBox(height: 20),
                SizedBox(
                  height: 900,
                  child: preview,
                ),
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 350,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: selector,
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: preview),
          ],
        );
      },
    );
  }

  Widget _buildSelector(
    List<StaffSalaryEntity> salaries,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Salary Record',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Salary Month'),
              subtitle: Text(_formatMonth(_selectedMonth)),
              trailing:
                  const Icon(Icons.calendar_month_outlined),
              onTap: _selectMonth,
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<StaffSalaryEntity>(
              initialValue: _selectedSalary,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Teacher / Staff Payroll',
                border: OutlineInputBorder(),
              ),
              items: salaries
                  .map(
                    (salary) =>
                        DropdownMenuItem<StaffSalaryEntity>(
                      value: salary,
                      child: Text(
                        '${salary.staffName} • ${salary.staffCode}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: salaries.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        _selectedSalary = value;
                      });
                    },
            ),

            if (salaries.isEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'No generated payroll records found for this month.',
                style: TextStyle(
                  color: _textSecondary,
                ),
              ),
            ],

            if (_selectedSalary != null) ...[
              const SizedBox(height: 18),
              _InfoRow(
                label: 'Employee',
                value: _selectedSalary!.staffName,
              ),
              _InfoRow(
                label: 'Designation',
                value: _selectedSalary!.designation,
              ),
              _InfoRow(
                label: 'Net Salary',
                value:
                    'Rs. ${_money(_selectedSalary!.netSalary)}',
              ),
              _InfoRow(
                label: 'Status',
                value: _paymentStatus(_selectedSalary!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(
    SchoolSettingsEntity settings,
  ) {
    final salary = _selectedSalary!;
    final template = buildSalarySlipTemplateV1();

    final branding = DocumentBrandingEntity(
      schoolName: settings.schoolName,
      schoolLogoUrl: settings.logoUrl,
      principalName: settings.principalName,
      principalDesignation:
          settings.principalDesignation,
      principalSignatureUrl:
          settings.principalSignatureUrl,
      schoolStampUrl: settings.schoolStampUrl,
    );

    final data = DocumentDataEntity(
      documentType: DocumentType.salarySlip,
      referenceId: salary.id,
      referenceType: 'payroll_record',
      generatedAt: DateTime.now(),
      values: {
        'salary': {
          'staffId': salary.staffId,
          'staffCode': salary.staffCode,
          'staffName': salary.staffName,
          'designation': salary.designation,
          'month': _formatMonth(salary.salaryMonth),
          'basicSalary': _money(salary.basicSalary),
          'allowance': _money(salary.allowance),
          'deduction': _money(salary.deduction),
          'attendanceDeduction':
              _money(salary.attendanceDeduction),
          'grossSalary': _money(salary.grossSalary),
          'netSalary': _money(salary.netSalary),
          'presentDays': salary.presentDays.toString(),
          'absentDays': salary.absentDays.toString(),
          'lateDays': salary.lateDays.toString(),
          'leaveDays': salary.leaveDays.toString(),
          'paymentStatus': _paymentStatus(salary),
          'paymentMethod': _paymentMethod(salary),
          'paymentReference': salary.paymentReference,
          'paymentDate': salary.paymentDate == null
              ? ''
              : _formatDate(salary.paymentDate!),
          'remarks': salary.remarks,
        },
      },
    );

    final values = {
      ...data.values,
      'branding': {
        'schoolName': branding.schoolName,
        'schoolLogo': branding.schoolLogoUrl,
        'principalName': branding.principalName,
        'principalDesignation':
            branding.principalDesignation,
        'principalSignature':
            branding.principalSignatureUrl,
        'schoolStamp': branding.schoolStampUrl,
      },
    };

    final placeholderResolver =
        const DefaultDocumentPlaceholderResolver();

    final renderer = FlutterDocumentRenderer(
      registry:
          DocumentRendererRegistryFactory.create(
        placeholderResolver: placeholderResolver,
      ),
      visibilityResolver:
          DocumentElementVisibilityResolver(
        placeholderResolver,
      ),
    );

    final renderContext = DocumentRenderContext(
      template: template,
      data: data,
      branding: branding,
      values: values,
    );

    return Column(
      children: [
        _ExportToolbar(
          busy: _exporting,
          onSavePdf: _savePdf,
          onSavePng: _savePng,
          onPrint: _printPdf,
          onSharePdf: _sharePdf,
          onSharePng: _sharePng,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Center(
              child: RepaintBoundary(
                key: _documentBoundaryKey,
                child: ColoredBox(
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final page
                          in template.orderedPages)
                        DocumentCanvas(
                          page: page,
                          renderContext: renderContext,
                          renderer: renderer,
                          maxWidth: 720,
                          padding: EdgeInsets.zero,
                          showShadow: true,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectMonth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select any date in salary month',
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _selectedMonth =
          DateTime(selected.year, selected.month);
      _selectedSalary = null;
      _salaryFuture = _loadSalaries();
    });
  }

  String _money(double value) {
    return value.toStringAsFixed(2);
  }

  String _formatMonth(DateTime date) {
    const months = <String>[
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

  String _formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');
    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _paymentStatus(
    StaffSalaryEntity salary,
  ) {
    return salary.paymentStatus ==
            StaffSalaryPaymentStatus.paid
        ? 'Paid'
        : 'Unpaid';
  }

  String _paymentMethod(
    StaffSalaryEntity salary,
  ) {
    final method = salary.paymentMethod;

    if (method == null) {
      return '';
    }

    return switch (method) {
      StaffSalaryPaymentMethod.cash => 'Cash',
      StaffSalaryPaymentMethod.bankTransfer =>
        'Bank Transfer',
      StaffSalaryPaymentMethod.easypaisa =>
        'Easypaisa',
      StaffSalaryPaymentMethod.jazzCash =>
        'JazzCash',
      StaffSalaryPaymentMethod.cheque =>
        'Cheque',
      StaffSalaryPaymentMethod.other =>
        'Other',
    };
  }

  Future<Uint8List> _capturePng({
    required double pixelRatio,
  }) {
    return _exportService.capturePng(
      boundaryKey: _documentBoundaryKey,
      pixelRatio: pixelRatio,
    );
  }

  Future<Uint8List> _buildPdf() async {
    if (_selectedSalary == null) {
      throw StateError(
        'Select a salary record first.',
      );
    }

    final template = buildSalarySlipTemplateV1();
    final page = template.orderedPages.first;

    final png = await _capturePng(
      pixelRatio: 2,
    );

    return _exportService.createPdfFromPng(
      pngBytes: png,
      aspectRatio: page.width / page.height,
      title:
          'Salary Slip - ${_selectedSalary!.staffName}',
    );
  }

  Future<void> _savePdf() async {
    await _runExport(() async {
      final salary = _selectedSalary!;

      final path = await _exportService.savePdf(
        bytes: await _buildPdf(),
        fileName:
            '${_baseName(salary)}_${salary.salaryMonth.year}_${salary.salaryMonth.month}_salary_slip',
      );

      if (path != null) {
        _success(
          'Salary Slip PDF saved successfully.',
        );
      }
    });
  }

  Future<void> _savePng() async {
    await _runExport(() async {
      final salary = _selectedSalary!;

      final path = await _exportService.savePng(
        bytes: await _capturePng(
          pixelRatio: 2,
        ),
        fileName:
            '${_baseName(salary)}_${salary.salaryMonth.year}_${salary.salaryMonth.month}_salary_slip',
      );

      if (path != null) {
        _success(
          'Salary Slip PNG saved successfully.',
        );
      }
    });
  }

  Future<void> _printPdf() async {
    await _runExport(() async {
      await _exportService.printPdf(
        bytes: await _buildPdf(),
        name:
            'Salary Slip - ${_selectedSalary!.staffName}',
      );
    });
  }

  Future<void> _sharePdf() async {
    await _runExport(() async {
      final salary = _selectedSalary!;

      await _exportService.sharePdf(
        bytes: await _buildPdf(),
        fileName:
            '${_baseName(salary)}_salary_slip.pdf',
      );
    });
  }

  Future<void> _sharePng() async {
    await _runExport(() async {
      final salary = _selectedSalary!;

      await _exportService.sharePng(
        bytes: await _capturePng(
          pixelRatio: 2,
        ),
        fileName:
            '${_baseName(salary)}_salary_slip.png',
        text:
            'Salary Slip - ${salary.staffName}',
      );
    });
  }

  Future<void> _runExport(
    Future<void> Function() action,
  ) async {
    if (_exporting ||
        _selectedSalary == null) {
      return;
    }

    setState(() {
      _exporting = true;
    });

    try {
      await action();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content:
                Text('Export failed: $error'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }

  String _baseName(
    StaffSalaryEntity salary,
  ) {
    return _exportService.safeFileName(
      salary.staffName,
      fallback: 'salary_slip',
    );
  }

  void _success(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  void _reloadSettings() {
    setState(() {
      _settingsFuture =
          sl<GetSchoolSettings>()();
    });
  }

  void _reloadSalaries() {
    setState(() {
      _selectedSalary = null;
      _salaryFuture = _loadSalaries();
    });
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(24, 18, 24, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _borderColor,
          ),
        ),
      ),
      child: const Row(
        children: [
          DashboardNavigationButton(),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Salary Slip',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Select salary month and payroll record.',
                  style: TextStyle(
                    fontSize: 13,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 7,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(
                color: _textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportToolbar extends StatelessWidget {
  const _ExportToolbar({
    required this.busy,
    required this.onSavePdf,
    required this.onSavePng,
    required this.onPrint,
    required this.onSharePdf,
    required this.onSharePng,
  });

  final bool busy;
  final VoidCallback onSavePdf;
  final VoidCallback onSavePng;
  final VoidCallback onPrint;
  final VoidCallback onSharePdf;
  final VoidCallback onSharePng;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      color: Colors.white,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed:
                busy ? null : onSavePdf,
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
            ),
            label: const Text('Save PDF'),
          ),
          OutlinedButton.icon(
            onPressed:
                busy ? null : onSavePng,
            icon: const Icon(
              Icons.image_outlined,
            ),
            label: const Text('Save PNG'),
          ),
          OutlinedButton.icon(
            onPressed: busy ? null : onPrint,
            icon: const Icon(
              Icons.print_outlined,
            ),
            label: const Text('Print'),
          ),
          PopupMenuButton<String>(
            enabled: !busy,
            onSelected: (value) {
              if (value == 'pdf') {
                onSharePdf();
              } else {
                onSharePng();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'pdf',
                child: Text('Share PDF'),
              ),
              PopupMenuItem(
                value: 'png',
                child: Text('Share PNG'),
              ),
            ],
            child: const Chip(
              avatar: Icon(
                Icons.share_outlined,
                size: 18,
              ),
              label: Text('Share'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 68,
            color: _textSecondary,
          ),
          SizedBox(height: 14),
          Text(
            'Select a salary record to preview the Salary Slip.',
            style: TextStyle(
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}


