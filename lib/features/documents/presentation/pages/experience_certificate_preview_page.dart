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
import '../../templates/experience_certificate/experience_certificate_template_v1.dart';

import '../export/document_export_service.dart';
import '../renderer/document_element_visibility_resolver.dart';
import '../renderer/document_render_context.dart';
import '../renderer/document_renderer_registry_factory.dart';
import '../renderer/flutter_document_renderer.dart';
import '../renderer/widgets/document_canvas.dart';

const _pageBackground = Color(0xFFF5F7FA);
const _textPrimary = Color(0xFF182230);
const _textSecondary = Color(0xFF667085);
const _brandBlue = Color(0xFF0B63CE);
const _borderColor = Color(0xFFE1E6ED);

enum _EmployeeType {
  teacher,
  staff,
}

class ExperienceCertificatePreviewPage
    extends StatefulWidget {
  const ExperienceCertificatePreviewPage({
    super.key,
  });

  @override
  State<ExperienceCertificatePreviewPage>
      createState() =>
          _ExperienceCertificatePreviewPageState();
}

class _ExperienceCertificatePreviewPageState
    extends State<ExperienceCertificatePreviewPage> {
  final GlobalKey _documentBoundaryKey =
      GlobalKey();

  final _formKey =
      GlobalKey<FormState>();

  final _nameController =
      TextEditingController();

  final _designationController =
      TextEditingController();

  final _joiningDateController =
      TextEditingController();

  final _leavingDateController =
      TextEditingController();

  final _remarksController =
      TextEditingController(
    text:
        'The conduct and performance during the period of service remained satisfactory.',
  );

  final DocumentExportService _exportService =
      const DocumentExportService();

  late Future<SchoolSettingsEntity>
      _settingsFuture;

  late Future<List<TeacherEntity>>
      _teachersFuture;

  late Future<List<StaffEntity>>
      _staffFuture;

  _EmployeeType _employeeType =
      _EmployeeType.teacher;

  String? _selectedEmployeeId;

  bool _exporting = false;
  bool _previewReady = false;

  @override
  void initState() {
    super.initState();

    _settingsFuture =
        sl<GetSchoolSettings>()();

    _teachersFuture =
        sl<TeacherRepository>()
            .getTeachers();

    _staffFuture =
        sl<StaffRepository>()
            .getStaff();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _designationController.dispose();
    _joiningDateController.dispose();
    _leavingDateController.dispose();
    _remarksController.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const _PreviewHeader(),

            Expanded(
              child:
                  FutureBuilder<SchoolSettingsEntity>(
                future:
                    _settingsFuture,
                builder: (
                  context,
                  snapshot,
                ) {
                  if (snapshot
                          .connectionState ==
                      ConnectionState
                          .waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return _LoadFailure(
                      message:
                          snapshot.error
                              .toString(),
                      onRetry: _reload,
                    );
                  }

                  final settings =
                      snapshot.data;

                  if (settings ==
                      null) {
                    return _LoadFailure(
                      message:
                          'School Settings could not be loaded.',
                      onRetry: _reload,
                    );
                  }

                  return _buildContent(
                    settings,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    SchoolSettingsEntity settings,
  ) {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final desktop =
            constraints.maxWidth >=
                950;

        if (!desktop) {
          return SingleChildScrollView(
            padding:
                const EdgeInsets.all(
              20,
            ),
            child: Column(
              children: [
                _buildFormCard(),

                const SizedBox(
                  height: 20,
                ),

                if (_previewReady)
                  _buildPreview(
                    settings,
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
              width: 420,
              child:
                  SingleChildScrollView(
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                child:
                    _buildFormCard(),
              ),
            ),

            Expanded(
              child: _previewReady
                  ? _buildPreview(
                      settings,
                    )
                  : const _PreviewEmptyState(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFormCard() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Certificate Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w700,
                  color: _textPrimary,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              const Text(
                'Employee Type',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      _textSecondary,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              SegmentedButton<
                  _EmployeeType>(
                segments: const [
                  ButtonSegment<
                      _EmployeeType>(
                    value:
                        _EmployeeType
                            .teacher,
                    icon: Icon(
                      Icons
                          .school_outlined,
                    ),
                    label: Text(
                      'Teacher',
                    ),
                  ),
                  ButtonSegment<
                      _EmployeeType>(
                    value:
                        _EmployeeType
                            .staff,
                    icon: Icon(
                      Icons
                          .badge_outlined,
                    ),
                    label: Text(
                      'Staff',
                    ),
                  ),
                ],
                selected: {
                  _employeeType,
                },
                onSelectionChanged:
                    (selection) {
                  if (selection
                      .isEmpty) {
                    return;
                  }

                  _changeEmployeeType(
                    selection.first,
                  );
                },
              ),

              const SizedBox(
                height: 16,
              ),

              InkWell(
                borderRadius:
                    BorderRadius
                        .circular(4),
                onTap:
                    _openEmployeePicker,
                child:
                    InputDecorator(
                  decoration:
                      InputDecoration(
                    labelText:
                        _employeeType ==
                                _EmployeeType
                                    .teacher
                            ? 'Select Teacher'
                            : 'Select Staff',
                    prefixIcon:
                        const Icon(
                      Icons
                          .person_search_outlined,
                    ),
                    suffixIcon:
                        const Icon(
                      Icons
                          .arrow_drop_down,
                    ),
                    border:
                        const OutlineInputBorder(),
                  ),
                  child: Text(
                    _nameController
                            .text
                            .trim()
                            .isEmpty
                        ? _employeeType ==
                                _EmployeeType
                                    .teacher
                            ? 'Choose teacher'
                            : 'Choose staff member'
                        : _nameController
                            .text
                            .trim(),
                    style: TextStyle(
                      color:
                          _nameController
                                  .text
                                  .trim()
                                  .isEmpty
                              ? _textSecondary
                              : _textPrimary,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              TextFormField(
                controller:
                    _designationController,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Designation',
                  prefixIcon: Icon(
                    Icons
                        .badge_outlined,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
                validator:
                    _required,
              ),

              const SizedBox(
                height: 14,
              ),

              TextFormField(
                controller:
                    _joiningDateController,
                readOnly: false,
                decoration:
                    InputDecoration(
                  labelText:
                      'Joining Date',
                  hintText:
                      'DD/MM/YYYY',
                  prefixIcon:
                      const Icon(
                    Icons
                        .calendar_month_outlined,
                  ),
                  suffixIcon:
                      IconButton(
                    tooltip:
                        'Choose date',
                    onPressed:
                        _pickJoiningDate,
                    icon:
                        const Icon(
                      Icons
                          .event_outlined,
                    ),
                  ),
                  border:
                      const OutlineInputBorder(),
                ),
                validator:
                    _required,
              ),

              const SizedBox(
                height: 14,
              ),

              TextFormField(
                controller:
                    _leavingDateController,
                readOnly: false,
                decoration:
                    InputDecoration(
                  labelText:
                      'Leaving Date',
                  hintText:
                      'DD/MM/YYYY or Present',
                  prefixIcon:
                      const Icon(
                    Icons
                        .event_busy_outlined,
                  ),
                  suffixIcon:
                      IconButton(
                    tooltip:
                        'Choose date',
                    onPressed:
                        _pickLeavingDate,
                    icon:
                        const Icon(
                      Icons
                          .event_outlined,
                    ),
                  ),
                  border:
                      const OutlineInputBorder(),
                ),
                validator:
                    _required,
              ),

              const SizedBox(
                height: 14,
              ),

              TextFormField(
                controller:
                    _remarksController,
                maxLines: 4,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Conduct / Remarks',
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    FilledButton.icon(
                  onPressed:
                      _generatePreview,
                  icon: const Icon(
                    Icons
                        .visibility_outlined,
                  ),
                  label: const Text(
                    'Generate Preview',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _changeEmployeeType(
    _EmployeeType type,
  ) {
    setState(() {
      _employeeType = type;

      _selectedEmployeeId =
          null;

      _nameController.clear();

      _designationController
          .clear();

      _joiningDateController
          .clear();

      _previewReady =
          false;
    });
  }

  Future<void>
      _openEmployeePicker() async {
    if (_employeeType ==
        _EmployeeType.teacher) {
      await _openTeacherPicker();
    } else {
      await _openStaffPicker();
    }
  }

  Future<void>
      _openTeacherPicker() async {
    List<TeacherEntity> teachers;

    try {
      teachers =
          await _teachersFuture;
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        'Unable to load teachers: $e',
      );

      return;
    }

    if (!mounted) {
      return;
    }

    final activeTeachers =
        teachers
            .where(
              (teacher) =>
                  teacher.isActive,
            )
            .toList()
          ..sort(
            (a, b) =>
                a.fullName
                    .toLowerCase()
                    .compareTo(
                      b.fullName
                          .toLowerCase(),
                    ),
          );

    final selected =
        await showDialog<
            TeacherEntity>(
      context: context,
      builder: (_) =>
          _TeacherPickerDialog(
        teachers:
            activeTeachers,
      ),
    );

    if (selected ==
        null) {
      return;
    }

    _selectTeacher(
      selected,
    );
  }

  Future<void>
      _openStaffPicker() async {
    List<StaffEntity> staff;

    try {
      staff =
          await _staffFuture;
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        'Unable to load staff: $e',
      );

      return;
    }

    if (!mounted) {
      return;
    }

    final activeStaff =
        staff
            .where(
              (item) =>
                  item.isActive,
            )
            .toList()
          ..sort(
            (a, b) =>
                a.fullName
                    .toLowerCase()
                    .compareTo(
                      b.fullName
                          .toLowerCase(),
                    ),
          );

    final selected =
        await showDialog<
            StaffEntity>(
      context: context,
      builder: (_) =>
          _StaffPickerDialog(
        staff:
            activeStaff,
      ),
    );

    if (selected ==
        null) {
      return;
    }

    _selectStaff(
      selected,
    );
  }

  void _selectTeacher(
    TeacherEntity teacher,
  ) {
    setState(() {
      _selectedEmployeeId =
          teacher.id;

      _nameController.text =
          teacher.fullName;

      _designationController
              .text =
          teacher.designation;

      _joiningDateController
              .text =
          _formatDate(
        teacher.joiningDate,
      );

      _previewReady =
          false;
    });
  }

  void _selectStaff(
    StaffEntity staff,
  ) {
    setState(() {
      _selectedEmployeeId =
          staff.id;

      _nameController.text =
          staff.fullName;

      _designationController
              .text =
          staff.designation;

      _joiningDateController
              .text =
          _formatDate(
        staff.joiningDate,
      );

      _previewReady =
          false;
    });
  }

  Future<void>
      _pickJoiningDate() async {
    final current =
        _parseDate(
          _joiningDateController
              .text,
        ) ??
        DateTime.now();

    final selected =
        await showDatePicker(
      context: context,
      initialDate: current,
      firstDate:
          DateTime(1950),
      lastDate:
          DateTime(2100),
    );

    if (selected ==
        null) {
      return;
    }

    setState(() {
      _joiningDateController
              .text =
          _formatDate(
        selected,
      );

      _previewReady =
          false;
    });
  }

  Future<void>
      _pickLeavingDate() async {
    final current =
        _parseDate(
          _leavingDateController
              .text,
        ) ??
        DateTime.now();

    final selected =
        await showDatePicker(
      context: context,
      initialDate: current,
      firstDate:
          DateTime(1950),
      lastDate:
          DateTime(2100),
    );

    if (selected ==
        null) {
      return;
    }

    setState(() {
      _leavingDateController
              .text =
          _formatDate(
        selected,
      );

      _previewReady =
          false;
    });
  }

  DateTime? _parseDate(
    String value,
  ) {
    final parts =
        value
            .trim()
            .split('/');

    if (parts.length !=
        3) {
      return null;
    }

    final day =
        int.tryParse(
      parts[0],
    );

    final month =
        int.tryParse(
      parts[1],
    );

    final year =
        int.tryParse(
      parts[2],
    );

    if (day == null ||
        month == null ||
        year == null) {
      return null;
    }

    try {
      return DateTime(
        year,
        month,
        day,
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildPreview(
    SchoolSettingsEntity settings,
  ) {
    final template =
        buildExperienceCertificateTemplateV1();

    final branding =
        DocumentBrandingEntity(
      schoolName:
          settings.schoolName,
      schoolLogoUrl:
          settings.logoUrl,
      principalName:
          settings.principalName,
      principalDesignation:
          settings
              .principalDesignation,
      principalSignatureUrl:
          settings
              .principalSignatureUrl,
      schoolStampUrl:
          settings.schoolStampUrl,
    );

    final data =
        _buildDocumentData();

    final values = {
      ...data.values,
      'branding': {
        'schoolName':
            branding.schoolName,
        'schoolLogo':
            branding.schoolLogoUrl,
        'principalName':
            branding
                .principalName,
        'principalDesignation':
            branding
                .principalDesignation,
        'principalSignature':
            branding
                .principalSignatureUrl,
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
          onSharePdf:
              _sharePdf,
          onSharePng:
              _sharePng,
        ),

        Expanded(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets
                    .fromLTRB(
              20,
              20,
              20,
              32,
            ),
            child: Center(
              child:
                  RepaintBoundary(
                key:
                    _documentBoundaryKey,
                child:
                    ColoredBox(
                  color:
                      Colors.white,
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      for (final page
                          in template
                              .orderedPages)
                        DocumentCanvas(
                          page: page,
                          renderContext:
                              renderContext,
                          renderer:
                              renderer,
                          maxWidth:
                              760,
                          padding:
                              EdgeInsets.zero,
                          showShadow:
                              false,
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

  DocumentDataEntity
      _buildDocumentData() {
    final name =
        _nameController
            .text
            .trim();

    return DocumentDataEntity(
      documentType:
          DocumentType
              .experienceCertificate,
      referenceId:
          _selectedEmployeeId ??
          'experience_${DateTime.now().millisecondsSinceEpoch}',
      referenceType:
          _employeeType ==
                  _EmployeeType
                      .teacher
              ? 'teacher'
              : 'staff',
      generatedAt:
          DateTime.now(),
      values: {
        'experience': {
          'employeeName':
              name,

          'designation':
              _designationController
                  .text
                  .trim(),

          'joiningDate':
              _joiningDateController
                  .text
                  .trim(),

          'leavingDate':
              _leavingDateController
                  .text
                  .trim(),

          'remarks':
              _remarksController
                      .text
                      .trim()
                      .isEmpty
                  ? 'The conduct and performance during the period of service remained satisfactory.'
                  : _remarksController
                      .text
                      .trim(),

          'issueDate':
              _formatDate(
            DateTime.now(),
          ),
        },
      },
    );
  }

  String? _required(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Required';
    }

    return null;
  }

  void _generatePreview() {
    if (_selectedEmployeeId ==
        null) {
      _showError(
        _employeeType ==
                _EmployeeType
                    .teacher
            ? 'Please select a teacher.'
            : 'Please select a staff member.',
      );

      return;
    }

    if (!(_formKey
            .currentState
            ?.validate() ??
        false)) {
      return;
    }

    setState(() {
      _previewReady =
          true;
    });
  }

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final month =
        date.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$day/$month/${date.year}';
  }

  Future<Uint8List>
      _capturePng({
    required double pixelRatio,
  }) {
    return _exportService
        .capturePng(
      boundaryKey:
          _documentBoundaryKey,
      pixelRatio:
          pixelRatio,
    );
  }

  Future<Uint8List>
      _buildPdf() async {
    final template =
        buildExperienceCertificateTemplateV1();

    final page =
        template
            .orderedPages
            .first;

    final pngBytes =
        await _capturePng(
      pixelRatio: 1.5,
    );

    return _exportService
        .createPdfFromPng(
      pngBytes:
          pngBytes,
      aspectRatio:
          page.width /
              page.height,
      title:
          'Experience Certificate - ${_nameController.text.trim()}',
    );
  }

  Future<void>
      _savePng() async {
    await _runExport(
      () async {
        final path =
            await _exportService
                .savePng(
          bytes:
              await _capturePng(
            pixelRatio: 3,
          ),
          fileName:
              '${_baseFileName()}_experience_certificate',
        );

        if (path != null) {
          _showSuccess(
            'Experience Certificate PNG saved successfully.',
          );
        }
      },
    );
  }

  Future<void>
      _savePdf() async {
    await _runExport(
      () async {
        final path =
            await _exportService
                .savePdf(
          bytes:
              await _buildPdf(),
          fileName:
              '${_baseFileName()}_experience_certificate',
        );

        if (path != null) {
          _showSuccess(
            'Experience Certificate PDF saved successfully.',
          );
        }
      },
    );
  }

  Future<void>
      _printPdf() async {
    await _runExport(
      () async {
        await _exportService
            .printPdf(
          bytes:
              await _buildPdf(),
          name:
              'Experience Certificate - ${_nameController.text.trim()}',
        );
      },
    );
  }

  Future<void>
      _sharePdf() async {
    await _runExport(
      () async {
        await _exportService
            .sharePdf(
          bytes:
              await _buildPdf(),
          fileName:
              '${_baseFileName()}_experience_certificate.pdf',
        );
      },
    );
  }

  Future<void>
      _sharePng() async {
    await _runExport(
      () async {
        await _exportService
            .sharePng(
          bytes:
              await _capturePng(
            pixelRatio: 3,
          ),
          fileName:
              '${_baseFileName()}_experience_certificate.png',
          text:
              'Experience Certificate - ${_nameController.text.trim()}',
        );
      },
    );
  }

  Future<void> _runExport(
    Future<void> Function()
        action,
  ) async {
    if (_exporting) {
      return;
    }

    setState(() {
      _exporting =
          true;
    });

    try {
      await action();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      )
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
          _exporting =
              false;
        });
      }
    }
  }

  String _baseFileName() {
    return _exportService
        .safeFileName(
      _nameController
          .text
          .trim(),
      fallback:
          'experience_certificate',
    );
  }

  void _showSuccess(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
        ),
      );
  }

  void _showError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
        ),
      );
  }

  void _reload() {
    setState(() {
      _settingsFuture =
          sl<GetSchoolSettings>()();

      _teachersFuture =
          sl<TeacherRepository>()
              .getTeachers();

      _staffFuture =
          sl<StaffRepository>()
              .getStaff();
    });
  }
}

class _TeacherPickerDialog
    extends StatefulWidget {
  const _TeacherPickerDialog({
    required this.teachers,
  });

  final List<TeacherEntity>
      teachers;

  @override
  State<_TeacherPickerDialog>
      createState() =>
          _TeacherPickerDialogState();
}

class _TeacherPickerDialogState
    extends State<_TeacherPickerDialog> {
  final _searchController =
      TextEditingController();

  @override
  void dispose() {
    _searchController
        .dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final query =
        _searchController
            .text
            .trim()
            .toLowerCase();

    final results =
        widget.teachers
            .where(
              (teacher) {
                if (query
                    .isEmpty) {
                  return true;
                }

                return teacher
                        .fullName
                        .toLowerCase()
                        .contains(
                          query,
                        ) ||
                    teacher
                        .employeeId
                        .toLowerCase()
                        .contains(
                          query,
                        ) ||
                    teacher
                        .designation
                        .toLowerCase()
                        .contains(
                          query,
                        );
              },
            )
            .toList();

    return AlertDialog(
      title:
          const Text(
        'Select Teacher',
      ),
      content: SizedBox(
        width: 560,
        height: 520,
        child: Column(
          children: [
            TextField(
              controller:
                  _searchController,
              autofocus:
                  true,
              onChanged: (_) {
                setState(
                    () {});
              },
              decoration:
                  const InputDecoration(
                labelText:
                    'Search Teacher',
                hintText:
                    'Name, Employee ID or Designation',
                prefixIcon:
                    Icon(
                  Icons.search,
                ),
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            Expanded(
              child: results
                      .isEmpty
                  ? const Center(
                      child: Text(
                        'No matching teacher found.',
                      ),
                    )
                  : ListView
                      .separated(
                      itemCount:
                          results
                              .length,
                      separatorBuilder:
                          (_, __) =>
                              const Divider(
                        height: 1,
                      ),
                      itemBuilder:
                          (
                        context,
                        index,
                      ) {
                        final teacher =
                            results[
                                index];

                        return ListTile(
                          leading:
                              const CircleAvatar(
                            child:
                                Icon(
                              Icons
                                  .school_outlined,
                            ),
                          ),
                          title:
                              Text(
                            teacher
                                .fullName,
                          ),
                          subtitle:
                              Text(
                            '${teacher.designation} • ${teacher.employeeId}',
                          ),
                          onTap:
                              () {
                            Navigator.of(
                              context,
                            ).pop(
                              teacher,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop();
          },
          child:
              const Text(
            'Cancel',
          ),
        ),
      ],
    );
  }
}

class _StaffPickerDialog
    extends StatefulWidget {
  const _StaffPickerDialog({
    required this.staff,
  });

  final List<StaffEntity>
      staff;

  @override
  State<_StaffPickerDialog>
      createState() =>
          _StaffPickerDialogState();
}

class _StaffPickerDialogState
    extends State<_StaffPickerDialog> {
  final _searchController =
      TextEditingController();

  @override
  void dispose() {
    _searchController
        .dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final query =
        _searchController
            .text
            .trim()
            .toLowerCase();

    final results =
        widget.staff
            .where(
              (staff) {
                if (query
                    .isEmpty) {
                  return true;
                }

                return staff
                        .fullName
                        .toLowerCase()
                        .contains(
                          query,
                        ) ||
                    staff
                        .staffId
                        .toLowerCase()
                        .contains(
                          query,
                        ) ||
                    staff
                        .designation
                        .toLowerCase()
                        .contains(
                          query,
                        );
              },
            )
            .toList();

    return AlertDialog(
      title:
          const Text(
        'Select Staff',
      ),
      content: SizedBox(
        width: 560,
        height: 520,
        child: Column(
          children: [
            TextField(
              controller:
                  _searchController,
              autofocus:
                  true,
              onChanged: (_) {
                setState(
                    () {});
              },
              decoration:
                  const InputDecoration(
                labelText:
                    'Search Staff',
                hintText:
                    'Name, Staff ID or Designation',
                prefixIcon:
                    Icon(
                  Icons.search,
                ),
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            Expanded(
              child: results
                      .isEmpty
                  ? const Center(
                      child: Text(
                        'No matching staff member found.',
                      ),
                    )
                  : ListView
                      .separated(
                      itemCount:
                          results
                              .length,
                      separatorBuilder:
                          (_, __) =>
                              const Divider(
                        height: 1,
                      ),
                      itemBuilder:
                          (
                        context,
                        index,
                      ) {
                        final staff =
                            results[
                                index];

                        return ListTile(
                          leading:
                              const CircleAvatar(
                            child:
                                Icon(
                              Icons
                                  .badge_outlined,
                            ),
                          ),
                          title:
                              Text(
                            staff
                                .fullName,
                          ),
                          subtitle:
                              Text(
                            '${staff.designation} • ${staff.staffId}',
                          ),
                          onTap:
                              () {
                            Navigator.of(
                              context,
                            ).pop(
                              staff,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop();
          },
          child:
              const Text(
            'Cancel',
          ),
        ),
      ],
    );
  }
}

class _PreviewHeader
    extends StatelessWidget {
  const _PreviewHeader();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,
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
          bottom:
              BorderSide(
            color:
                _borderColor,
          ),
        ),
      ),
      child: const Row(
        children: [
          DashboardNavigationButton(),

          SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  'Experience Certificate',
                  style:
                      TextStyle(
                    fontSize:
                        24,
                    fontWeight:
                        FontWeight
                            .w700,
                    color:
                        _textPrimary,
                  ),
                ),
                SizedBox(
                  height: 3,
                ),
                Text(
                  'Select a teacher or staff member and generate certificate.',
                  style:
                      TextStyle(
                    fontSize:
                        13,
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

  final VoidCallback
      onSavePng;

  final VoidCallback
      onSavePdf;

  final VoidCallback
      onPrint;

  final VoidCallback
      onSharePdf;

  final VoidCallback
      onSharePng;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      decoration:
          const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom:
              BorderSide(
            color:
                _borderColor,
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
                strokeWidth:
                    2,
              ),
            ),

          OutlinedButton.icon(
            onPressed:
                busy
                    ? null
                    : onSavePng,
            icon:
                const Icon(
              Icons
                  .image_outlined,
            ),
            label:
                const Text(
              'Save PNG',
            ),
          ),

          OutlinedButton.icon(
            onPressed:
                busy
                    ? null
                    : onSavePdf,
            icon:
                const Icon(
              Icons
                  .picture_as_pdf_outlined,
            ),
            label:
                const Text(
              'Save PDF',
            ),
          ),

          OutlinedButton.icon(
            onPressed:
                busy
                    ? null
                    : onPrint,
            icon:
                const Icon(
              Icons
                  .print_outlined,
            ),
            label:
                const Text(
              'Print',
            ),
          ),

          PopupMenuButton<
              _ShareFormat>(
            enabled:
                !busy,
            onSelected:
                (value) {
              switch (value) {
                case _ShareFormat
                      .pdf:
                  onSharePdf();

                case _ShareFormat
                      .png:
                  onSharePng();
              }
            },
            itemBuilder:
                (_) =>
                    const [
              PopupMenuItem(
                value:
                    _ShareFormat
                        .pdf,
                child:
                    Text(
                  'Share PDF',
                ),
              ),
              PopupMenuItem(
                value:
                    _ShareFormat
                        .png,
                child:
                    Text(
                  'Share PNG',
                ),
              ),
            ],
            child: Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal:
                    18,
                vertical: 10,
              ),
              decoration:
                  BoxDecoration(
                color: busy
                    ? Colors
                        .grey
                        .shade300
                    : _brandBlue,
                borderRadius:
                    BorderRadius
                        .circular(
                  20,
                ),
              ),
              child:
                  const Text(
                'Share',
                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontWeight:
                      FontWeight
                          .w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ShareFormat {
  pdf,
  png,
}

class _PreviewEmptyState
    extends StatelessWidget {
  const _PreviewEmptyState();

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons
                .history_edu_outlined,
            size: 64,
            color:
                _textSecondary,
          ),

          SizedBox(
            height: 14,
          ),

          Text(
            'Select employee details and click Generate Preview.',
            style:
                TextStyle(
              color:
                  _textSecondary,
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

  final VoidCallback
      onRetry;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .error_outline,
              size: 48,
              color:
                  Colors.red,
            ),

            const SizedBox(
              height: 12,
            ),

            const Text(
              'Unable to load Experience Certificate',
              style:
                  TextStyle(
                color:
                    _textPrimary,
                fontSize:
                    17,
                fontWeight:
                    FontWeight
                        .w700,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              message,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    _textSecondary,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            FilledButton.icon(
              onPressed:
                  onRetry,
              icon:
                  const Icon(
                Icons.refresh,
              ),
              label:
                  const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }
}