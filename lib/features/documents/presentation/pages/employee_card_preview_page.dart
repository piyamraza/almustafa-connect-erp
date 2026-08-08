import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../settings/domain/entities/school_settings_entity.dart';
import '../../../settings/domain/usecases/manage_settings.dart';
import '../../../staff/domain/entities/staff_entity.dart';
import '../../../staff/domain/repositories/staff_repository.dart';
import '../../../teachers/domain/entities/teacher_entity.dart';
import '../../../teachers/domain/repositories/teacher_repository.dart';
import '../../domain/entities/document_branding_entity.dart';
import '../../domain/entities/document_data_entity.dart';
import '../../domain/entities/document_type.dart';
import '../../domain/services/default_document_placeholder_resolver.dart';
import '../../templates/employee_card/employee_card_template_v1.dart';
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

class EmployeeCardPreviewPage extends StatefulWidget {
  const EmployeeCardPreviewPage({
    super.key,
  });

  @override
  State<EmployeeCardPreviewPage> createState() =>
      _EmployeeCardPreviewPageState();
}

class _EmployeeCardPreviewPageState
    extends State<EmployeeCardPreviewPage> {
  final GlobalKey _documentBoundaryKey = GlobalKey();

  final DocumentExportService _exportService =
      const DocumentExportService();

  late Future<SchoolSettingsEntity> _settingsFuture;
  late Future<List<_EmployeeCardRecord>> _employeesFuture;

  _EmployeeCardRecord? _selectedEmployee;

  bool _exporting = false;

  @override
  void initState() {
    super.initState();

    _settingsFuture = sl<GetSchoolSettings>()();
    _employeesFuture = _loadEmployees();
  }

  Future<List<_EmployeeCardRecord>> _loadEmployees() async {
    final results = await Future.wait<Object>([
      sl<TeacherRepository>().getTeachers(),
      sl<StaffRepository>().getStaff(),
    ]);

    final teachers = results[0] as List<TeacherEntity>;
    final staff = results[1] as List<StaffEntity>;

    final employees = <_EmployeeCardRecord>[
      ...teachers
          .where((teacher) => teacher.isActive)
          .map(
            (teacher) => _EmployeeCardRecord(
              id: teacher.id,
              employeeCode: teacher.employeeId,
              name: teacher.fullName,
              designation: teacher.designation,
              employeeType: 'Teaching Staff',
              phone: teacher.phone,
              cnic: teacher.cnic,
              joiningDate: teacher.joiningDate,
              photoUrl: '',
            ),
          ),
      ...staff
          .where((member) => member.isActive)
          .map(
            (member) => _EmployeeCardRecord(
              id: member.id,
              employeeCode: member.staffId,
              name: member.fullName,
              designation: member.designation,
              employeeType: 'Non-Teaching Staff',
              phone: member.phone,
              cnic: member.cnic,
              joiningDate: member.joiningDate,
              photoUrl: member.profileImageUrl,
            ),
          ),
    ];

    employees.sort(
      (a, b) => a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ),
    );

    return employees;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const _PreviewHeader(),
            Expanded(
              child: FutureBuilder<List<_EmployeeCardRecord>>(
                future: _employeesFuture,
                builder: (
                  context,
                  employeeSnapshot,
                ) {
                  if (employeeSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (employeeSnapshot.hasError) {
                    return _LoadFailure(
                      message: employeeSnapshot.error.toString(),
                      onRetry: _reloadEmployees,
                    );
                  }

                  final employees =
                      employeeSnapshot.data ??
                          const <_EmployeeCardRecord>[];

                  if (employees.isEmpty) {
                    return const Center(
                      child: Text(
                        'No active teachers or staff found.',
                      ),
                    );
                  }

                  return FutureBuilder<SchoolSettingsEntity>(
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

                      if (settingsSnapshot.hasError) {
                        return _LoadFailure(
                          message:
                              settingsSnapshot.error.toString(),
                          onRetry: _reloadSettings,
                        );
                      }

                      final settings =
                          settingsSnapshot.data;

                      if (settings == null) {
                        return _LoadFailure(
                          message:
                              'School Settings could not be loaded.',
                          onRetry: _reloadSettings,
                        );
                      }

                      return _buildBody(
                        employees: employees,
                        settings: settings,
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

  Widget _buildBody({
    required List<_EmployeeCardRecord> employees,
    required SchoolSettingsEntity settings,
  }) {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final wide =
            constraints.maxWidth >= 850;

        final selector = _EmployeeSelector(
          employees: employees,
          selectedEmployee: _selectedEmployee,
          onChanged: (employee) {
            setState(() {
              _selectedEmployee = employee;
            });
          },
        );

        final preview =
            _selectedEmployee == null
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
                  height: 820,
                  child: preview,
                ),
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 330,
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
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

  Widget _buildPreview(
    SchoolSettingsEntity settings,
  ) {
    final employee =
        _selectedEmployee!;

    final template =
        buildEmployeeCardTemplateV1();

    final branding =
        DocumentBrandingEntity(
      schoolName: settings.schoolName,
      schoolLogoUrl: settings.logoUrl,
      principalName: settings.principalName,
      principalDesignation:
          settings.principalDesignation,
      principalSignatureUrl:
          settings.principalSignatureUrl,
      schoolStampUrl:
          settings.schoolStampUrl,
    );

    final data =
        DocumentDataEntity(
      documentType:
          DocumentType.employeeCard,
      referenceId: employee.id,
      referenceType: 'employee',
      generatedAt: DateTime.now(),
      values: {
        'employee': {
          'id': employee.id,
          'employeeCode':
              employee.employeeCode,
          'name': employee.name,
          'designation':
              employee.designation,
          'employeeType':
              employee.employeeType,
          'phone': employee.phone,
          'cnic': employee.cnic,
          'joiningDate':
              _formatDate(
            employee.joiningDate,
          ),
          'photo':
              employee.photoUrl,
        },
      },
    );

    final values = {
      ...data.values,
      'branding': {
        'schoolName':
            branding.schoolName,
        'schoolLogo':
            branding.schoolLogoUrl,
        'principalName':
            branding.principalName,
        'principalDesignation':
            branding.principalDesignation,
        'principalSignature':
            branding.principalSignatureUrl,
        'schoolStamp':
            branding.schoolStampUrl,
      },
    };

    final placeholderResolver =
        const DefaultDocumentPlaceholderResolver();

    final renderer =
        FlutterDocumentRenderer(
      registry:
          DocumentRendererRegistryFactory
              .create(
        placeholderResolver:
            placeholderResolver,
      ),
      visibilityResolver:
          DocumentElementVisibilityResolver(
        placeholderResolver,
      ),
    );

    final renderContext =
        DocumentRenderContext(
      template: template,
      data: data,
      branding: branding,
      values: values,
    );

    return Column(
      children: [
        _ExportToolbar(
          busy: _exporting,
          onSavePng: _savePng,
          onSavePdf: _savePdf,
          onPrint: _printPdf,
          onSharePdf: _sharePdf,
          onSharePng: _sharePng,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              32,
            ),
            child: Center(
              child: RepaintBoundary(
                key:
                    _documentBoundaryKey,
                child: ColoredBox(
                  color: Colors.white,
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      for (final page
                          in template.orderedPages)
                        DocumentCanvas(
                          page: page,
                          renderContext:
                              renderContext,
                          renderer: renderer,
                          maxWidth: 420,
                          padding:
                              EdgeInsets.zero,
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

  String _formatDate(DateTime date) {
    final day =
        date.day
            .toString()
            .padLeft(2, '0');

    final month =
        date.month
            .toString()
            .padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Future<Uint8List> _capturePng({
    required double pixelRatio,
  }) {
    return _exportService.capturePng(
      boundaryKey:
          _documentBoundaryKey,
      pixelRatio: pixelRatio,
    );
  }

  Future<Uint8List> _buildPdf() async {
    final employee =
        _selectedEmployee;

    if (employee == null) {
      throw StateError(
        'Select an employee first.',
      );
    }

    final template =
        buildEmployeeCardTemplateV1();

    final page =
        template.orderedPages.first;

    final png =
        await _capturePng(
      pixelRatio: 3,
    );

    return _exportService
        .createPdfFromPng(
      pngBytes: png,
      aspectRatio:
          page.width / page.height,
      title:
          'Employee ID Card - ${employee.name}',
    );
  }

  Future<void> _savePng() async {
    await _runExport(() async {
      final employee =
          _selectedEmployee!;

      final path =
          await _exportService.savePng(
        bytes:
            await _capturePng(
          pixelRatio: 3,
        ),
        fileName:
            '${_baseFileName(employee)}_employee_card',
      );

      if (path != null) {
        _showSuccess(
          'Employee ID Card PNG saved successfully.',
        );
      }
    });
  }

  Future<void> _savePdf() async {
    await _runExport(() async {
      final employee =
          _selectedEmployee!;

      final path =
          await _exportService.savePdf(
        bytes: await _buildPdf(),
        fileName:
            '${_baseFileName(employee)}_employee_card',
      );

      if (path != null) {
        _showSuccess(
          'Employee ID Card PDF saved successfully.',
        );
      }
    });
  }

  Future<void> _printPdf() async {
    await _runExport(() async {
      final employee =
          _selectedEmployee!;

      await _exportService.printPdf(
        bytes: await _buildPdf(),
        name:
            'Employee ID Card - ${employee.name}',
      );
    });
  }

  Future<void> _sharePdf() async {
    await _runExport(() async {
      final employee =
          _selectedEmployee!;

      await _exportService.sharePdf(
        bytes: await _buildPdf(),
        fileName:
            '${_baseFileName(employee)}_employee_card.pdf',
      );
    });
  }

  Future<void> _sharePng() async {
    await _runExport(() async {
      final employee =
          _selectedEmployee!;

      await _exportService.sharePng(
        bytes:
            await _capturePng(
          pixelRatio: 3,
        ),
        fileName:
            '${_baseFileName(employee)}_employee_card.png',
        text:
            'Employee ID Card - ${employee.name}',
      );
    });
  }

  Future<void> _runExport(
    Future<void> Function() action,
  ) async {
    if (_exporting ||
        _selectedEmployee == null) {
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
            content: Text(
              'Export failed: $error',
            ),
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

  String _baseFileName(
    _EmployeeCardRecord employee,
  ) {
    return _exportService.safeFileName(
      employee.name,
      fallback: 'employee',
    );
  }

  void _showSuccess(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  void _reloadEmployees() {
    setState(() {
      _selectedEmployee = null;
      _employeesFuture =
          _loadEmployees();
    });
  }

  void _reloadSettings() {
    setState(() {
      _settingsFuture =
          sl<GetSchoolSettings>()();
    });
  }
}

class _EmployeeSelector
    extends StatelessWidget {
  const _EmployeeSelector({
    required this.employees,
    required this.selectedEmployee,
    required this.onChanged,
  });

  final List<_EmployeeCardRecord>
      employees;

  final _EmployeeCardRecord?
      selectedEmployee;

  final ValueChanged<
          _EmployeeCardRecord?>
      onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Select Employee',
              style:
                  Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<
                _EmployeeCardRecord>(
              initialValue:
                  selectedEmployee,
              isExpanded: true,
              decoration:
                  const InputDecoration(
                labelText:
                    'Teacher / Staff',
                border:
                    OutlineInputBorder(),
              ),
              items: employees
                  .map(
                    (employee) =>
                        DropdownMenuItem<
                            _EmployeeCardRecord>(
                      value: employee,
                      child: Text(
                        '${employee.name} • ${employee.employeeType}',
                        overflow:
                            TextOverflow
                                .ellipsis,
                      ),
                    ),
                  )
                  .toList(
                    growable: false,
                  ),
              onChanged: onChanged,
            ),
            if (selectedEmployee !=
                null) ...[
              const SizedBox(height: 16),
              _InfoRow(
                label: 'Employee ID',
                value:
                    selectedEmployee!
                        .employeeCode,
              ),
              _InfoRow(
                label: 'Designation',
                value:
                    selectedEmployee!
                        .designation,
              ),
              _InfoRow(
                label: 'Type',
                value:
                    selectedEmployee!
                        .employeeType,
              ),
            ],
          ],
        ),
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
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style:
                  const TextStyle(
                color:
                    _textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty
                  ? '-'
                  : value,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewHeader
    extends StatelessWidget {
  const _PreviewHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        24,
        18,
        24,
        18,
      ),
      decoration:
          const BoxDecoration(
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
                  'Employee ID Card',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        _textPrimary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Select a teacher or staff member and generate ID card.',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        _textSecondary,
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

class _ExportToolbar
    extends StatelessWidget {
  const _ExportToolbar({
    required this.busy,
    required this.onSavePng,
    required this.onSavePdf,
    required this.onPrint,
    required this.onSharePdf,
    required this.onSharePng,
  });

  final bool busy;
  final VoidCallback onSavePng;
  final VoidCallback onSavePdf;
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
      decoration:
          const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _borderColor,
          ),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment:
            WrapAlignment.end,
        children: [
          if (busy)
            const SizedBox(
              width: 20,
              height: 20,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          OutlinedButton.icon(
            onPressed:
                busy ? null : onSavePng,
            icon: const Icon(
              Icons.image_outlined,
            ),
            label:
                const Text('Save PNG'),
          ),
          OutlinedButton.icon(
            onPressed:
                busy ? null : onSavePdf,
            icon: const Icon(
              Icons
                  .picture_as_pdf_outlined,
            ),
            label:
                const Text('Save PDF'),
          ),
          OutlinedButton.icon(
            onPressed:
                busy ? null : onPrint,
            icon: const Icon(
              Icons.print_outlined,
            ),
            label:
                const Text('Print'),
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
            itemBuilder: (_) =>
                const [
              PopupMenuItem(
                value: 'pdf',
                child:
                    Text('Share PDF'),
              ),
              PopupMenuItem(
                value: 'png',
                child:
                    Text('Share PNG'),
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

class _EmptyPreview
    extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons.badge_outlined,
            size: 68,
            color: _textSecondary,
          ),
          SizedBox(height: 14),
          Text(
            'Select an employee to preview the ID card.',
            style: TextStyle(
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadFailure
    extends StatelessWidget {
  const _LoadFailure({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon:
                  const Icon(
                Icons.refresh,
              ),
              label:
                  const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeCardRecord {
  const _EmployeeCardRecord({
    required this.id,
    required this.employeeCode,
    required this.name,
    required this.designation,
    required this.employeeType,
    required this.phone,
    required this.cnic,
    required this.joiningDate,
    required this.photoUrl,
  });

  final String id;
  final String employeeCode;
  final String name;
  final String designation;
  final String employeeType;
  final String phone;
  final String cnic;
  final DateTime joiningDate;
  final String photoUrl;
}
