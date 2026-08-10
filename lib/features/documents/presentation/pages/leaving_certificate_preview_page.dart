import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../settings/domain/entities/school_settings_entity.dart';
import '../../../settings/domain/usecases/manage_settings.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/document_branding_entity.dart';
import '../../domain/entities/document_data_entity.dart';
import '../../domain/entities/document_type.dart';
import '../../domain/services/default_document_placeholder_resolver.dart';
import '../../templates/leaving_certificate/leaving_certificate_template_v1.dart';
import '../export/document_export_service.dart';
import '../renderer/document_element_visibility_resolver.dart';
import '../renderer/document_branding_image_values.dart';
import '../renderer/document_render_context.dart';
import '../renderer/document_renderer_registry_factory.dart';
import '../renderer/flutter_document_renderer.dart';
import '../renderer/widgets/document_canvas.dart';

const _pageBackground = Color(0xFFF5F7FA);
const _textPrimary = Color(0xFF182230);
const _textSecondary = Color(0xFF667085);
const _brandBlue = Color(0xFF0B63CE);
const _borderColor = Color(0xFFE1E6ED);

class LeavingCertificatePreviewPage extends StatefulWidget {
  const LeavingCertificatePreviewPage({
    super.key,
    required this.student,
    this.className = '',
    this.sectionName = '',
    this.certificateNumber,
    this.dateOfAdmission,
    this.dateOfLeaving,
    this.reasonForLeaving = 'On parent / guardian request',
    this.conduct = 'Good',
  });

  final StudentEntity student;
  final String className;
  final String sectionName;
  final String? certificateNumber;
  final DateTime? dateOfAdmission;
  final DateTime? dateOfLeaving;
  final String reasonForLeaving;
  final String conduct;

  @override
  State<LeavingCertificatePreviewPage> createState() =>
      _LeavingCertificatePreviewPageState();
}

class _LeavingCertificatePreviewPageState
    extends State<LeavingCertificatePreviewPage> {
  final GlobalKey _documentBoundaryKey = GlobalKey();
  final _formKey = GlobalKey<FormState>();

  final _leavingDateController = TextEditingController();
  final _reasonController = TextEditingController();
  final _conductController = TextEditingController();

  final DocumentExportService _exportService = const DocumentExportService();

  late Future<SchoolSettingsEntity> _settingsFuture;

  bool _exporting = false;
  bool _previewReady = false;

  @override
  void initState() {
    super.initState();

    _settingsFuture = sl<GetSchoolSettings>()();

    if (widget.dateOfLeaving != null) {
      _leavingDateController.text = _formatDate(widget.dateOfLeaving!);
    }

    _reasonController.text = widget.reasonForLeaving.trim();

    _conductController.text = widget.conduct.trim();
  }

  @override
  void dispose() {
    _leavingDateController.dispose();
    _reasonController.dispose();
    _conductController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _PreviewHeader(studentName: widget.student.fullName),
            Expanded(
              child: FutureBuilder<SchoolSettingsEntity>(
                future: _settingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _LoadFailure(
                      message: snapshot.error.toString(),
                      onRetry: _reload,
                    );
                  }

                  final settings = snapshot.data;

                  if (settings == null) {
                    return _LoadFailure(
                      message: 'School Settings could not be loaded.',
                      onRetry: _reload,
                    );
                  }

                  return _buildContent(settings);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SchoolSettingsEntity settings) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 950;

        if (!desktop) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildFormCard(),
                const SizedBox(height: 20),
                if (_previewReady)
                  SizedBox(height: 900, child: _buildPreview(settings)),
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 420,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildFormCard(),
              ),
            ),
            Expanded(
              child: _previewReady
                  ? _buildPreview(settings)
                  : const _PreviewNotGenerated(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFormCard() {
    final admissionDate = widget.dateOfAdmission ?? widget.student.createdAt;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Leaving Certificate Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.student.fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Admission No. ${widget.student.admissionNo}  •  Admission Date ${_formatDate(admissionDate)}',
                style: const TextStyle(fontSize: 12, color: _textSecondary),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _leavingDateController,
                decoration: InputDecoration(
                  labelText: 'Date of Leaving',
                  hintText: 'DD/MM/YYYY',
                  prefixIcon: const Icon(Icons.event_busy_outlined),
                  suffixIcon: IconButton(
                    tooltip: 'Choose date',
                    onPressed: _pickLeavingDate,
                    icon: const Icon(Icons.calendar_month_outlined),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: _required,
                onChanged: (_) {
                  if (_previewReady) {
                    setState(() {
                      _previewReady = false;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason for Leaving',
                  hintText: 'Enter reason for leaving',
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: _required,
                onChanged: (_) {
                  if (_previewReady) {
                    setState(() {
                      _previewReady = false;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _conductController,
                decoration: const InputDecoration(
                  labelText: 'Conduct',
                  hintText: 'e.g. Good, Very Good',
                  prefixIcon: Icon(Icons.verified_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: _required,
                onChanged: (_) {
                  if (_previewReady) {
                    setState(() {
                      _previewReady = false;
                    });
                  }
                },
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _generatePreview,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Generate Preview'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    return null;
  }

  Future<void> _pickLeavingDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _tryParseDate(_leavingDateController.text) ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _leavingDateController.text = _formatDate(selected);
      _previewReady = false;
    });
  }

  DateTime? _tryParseDate(String value) {
    final parts = value.trim().split('/');

    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) {
      return null;
    }

    final result = DateTime(year, month, day);

    if (result.year != year || result.month != month || result.day != day) {
      return null;
    }

    return result;
  }

  void _generatePreview() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_tryParseDate(_leavingDateController.text) == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Please enter Date of Leaving in DD/MM/YYYY format.'),
          ),
        );
      return;
    }

    setState(() {
      _previewReady = true;
    });
  }

  Widget _buildPreview(SchoolSettingsEntity settings) {
    final template = buildLeavingCertificateTemplateV1();

    final branding = _buildBranding(settings);

    final data = _buildCertificateData();

    final values = _buildRenderValues(branding: branding, data: data);

    final placeholderResolver = const DefaultDocumentPlaceholderResolver();

    final registry = DocumentRendererRegistryFactory.create(
      placeholderResolver: placeholderResolver,
    );

    final visibilityResolver = DocumentElementVisibilityResolver(
      placeholderResolver,
    );

    final renderer = FlutterDocumentRenderer(
      registry: registry,
      visibilityResolver: visibilityResolver,
    );

    final renderContext = DocumentRenderContext(
      template: template,
      data: data,
      branding: branding,
      values: values,
    );

    final pages = template.orderedPages;

    if (pages.isEmpty) {
      return const _EmptyPreview();
    }

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
            padding: const EdgeInsets.only(bottom: 32),
            child: Center(
              child: RepaintBoundary(
                key: _documentBoundaryKey,
                child: ColoredBox(
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final page in pages)
                        DocumentCanvas(
                          page: page,
                          renderContext: renderContext,
                          renderer: renderer,
                          maxWidth: 760,
                          padding: EdgeInsets.zero,
                          showShadow: false,
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

  DocumentBrandingEntity _buildBranding(SchoolSettingsEntity settings) {
    return DocumentBrandingEntity(
      schoolName: settings.schoolName,
      schoolLogoUrl: settings.logoUrl,
      principalName: settings.principalName,
      principalDesignation: settings.principalDesignation,
      principalSignatureUrl: settings.principalSignatureUrl,
      principalSignatureData: settings.principalSignatureData,
      schoolStampUrl: settings.schoolStampUrl,
      schoolStampData: settings.schoolStampData,
    );
  }

  DocumentDataEntity _buildCertificateData() {
    final student = widget.student;

    final admissionDate = widget.dateOfAdmission ?? student.createdAt;

    final leavingDate = _leavingDateController.text.trim();

    return DocumentDataEntity(
      documentType: DocumentType.leavingCertificate,
      referenceId: student.id,
      referenceType: 'student',
      generatedAt: DateTime.now(),
      values: {
        'student': {
          'id': student.id,
          'name': student.fullName,
          'firstName': student.firstName,
          'lastName': student.lastName,
          'fatherName': student.fatherName,
          'admissionNo': student.admissionNo,
          'rollNumber': student.rollNumber,
          'gender': student.gender,
          'classId': student.classId,
          'sectionId': student.sectionId,
          'class': widget.className,
          'section': widget.sectionName,
          'classSection': _buildClassSectionLabel(),
          'photo': student.profileImageUrl,
          'dateOfBirth': _formatDate(student.dateOfBirth),
        },
        'leaving': {
          'dateOfAdmission': _formatDate(admissionDate),
          'dateOfLeaving': leavingDate,
          'reason': _reasonController.text.trim(),
          'conduct': _conductController.text.trim(),
        },
        'certificate': {
          'number': _certificateNumber(),
          'issueDate': _formatDate(DateTime.now()),
        },
      },
    );
  }

  Map<String, dynamic> _buildRenderValues({
    required DocumentBrandingEntity branding,
    required DocumentDataEntity data,
  }) {
    return {
      ...data.values,
      'branding': {
        'schoolName': branding.schoolName,
        'schoolLogo': branding.schoolLogoUrl,
        'principalName': branding.principalName,
        'principalDesignation': branding.principalDesignation,
        'principalSignature': principalSignatureImageValue(branding),
        'schoolStamp': schoolStampImageValue(branding),
      },
    };
  }

  String _buildClassSectionLabel() {
    final className = widget.className.trim();

    final sectionName = widget.sectionName.trim();

    if (className.isNotEmpty && sectionName.isNotEmpty) {
      return '$className - $sectionName';
    }

    if (className.isNotEmpty) {
      return className;
    }

    if (sectionName.isNotEmpty) {
      return sectionName;
    }

    return '';
  }

  String _certificateNumber() {
    final supplied = widget.certificateNumber?.trim();

    if (supplied != null && supplied.isNotEmpty) {
      return supplied;
    }

    final admissionNo = widget.student.admissionNo.trim().replaceAll(
      RegExp(r'\s+'),
      '',
    );

    final suffix = admissionNo.isEmpty ? widget.student.id : admissionNo;

    return 'LC-${DateTime.now().year}-$suffix';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Future<Uint8List> _capturePng({required double pixelRatio}) {
    return _exportService.capturePng(
      boundaryKey: _documentBoundaryKey,
      pixelRatio: pixelRatio,
    );
  }

  Future<Uint8List> _buildPdf() async {
    final template = buildLeavingCertificateTemplateV1();

    final pages = template.orderedPages;

    if (pages.isEmpty) {
      throw StateError('Leaving Certificate template has no pages.');
    }

    final firstPage = pages.first;

    if (firstPage.width <= 0 || firstPage.height <= 0) {
      throw StateError(
        'Leaving Certificate template has invalid page dimensions.',
      );
    }

    final pngBytes = await _capturePng(pixelRatio: 1.5);

    final aspectRatio = firstPage.width / firstPage.height;

    return _exportService.createPdfFromPng(
      pngBytes: pngBytes,
      aspectRatio: aspectRatio,
      title: 'Leaving Certificate - ${widget.student.fullName}',
    );
  }

  Future<void> _savePng() async {
    await _runExport(() async {
      final bytes = await _capturePng(pixelRatio: 3);

      final path = await _exportService.savePng(
        bytes: bytes,
        fileName: '${_baseFileName()}_leaving_certificate',
      );

      if (path != null) {
        _showSuccess('Leaving Certificate PNG saved successfully.');
      }
    });
  }

  Future<void> _savePdf() async {
    await _runExport(() async {
      final bytes = await _buildPdf();

      final path = await _exportService.savePdf(
        bytes: bytes,
        fileName: '${_baseFileName()}_leaving_certificate',
      );

      if (path != null) {
        _showSuccess('Leaving Certificate PDF saved successfully.');
      }
    });
  }

  Future<void> _printPdf() async {
    await _runExport(() async {
      final bytes = await _buildPdf();

      await _exportService.printPdf(
        bytes: bytes,
        name: 'Leaving Certificate - ${widget.student.fullName}',
      );
    });
  }

  Future<void> _sharePdf() async {
    await _runExport(() async {
      final bytes = await _buildPdf();

      await _exportService.sharePdf(
        bytes: bytes,
        fileName: '${_baseFileName()}_leaving_certificate.pdf',
      );
    });
  }

  Future<void> _sharePng() async {
    await _runExport(() async {
      final bytes = await _capturePng(pixelRatio: 3);

      await _exportService.sharePng(
        bytes: bytes,
        fileName: '${_baseFileName()}_leaving_certificate.png',
        text: 'Leaving Certificate - ${widget.student.fullName}',
      );
    });
  }

  Future<void> _runExport(Future<void> Function() action) async {
    if (_exporting) {
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
        ..showSnackBar(SnackBar(content: Text('Export failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }

  String _baseFileName() {
    return _exportService.safeFileName(
      widget.student.fullName,
      fallback: 'leaving_certificate',
    );
  }

  void _showSuccess(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _reload() {
    setState(() {
      _settingsFuture = sl<GetSchoolSettings>()();
    });
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({required this.studentName});

  final String studentName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          const DashboardNavigationButton(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Leaving Certificate Preview',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  studentName.trim().isEmpty
                      ? 'Leaving Certificate'
                      : 'Certificate for $studentName',
                  style: const TextStyle(fontSize: 13, color: _textSecondary),
                ),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (busy) ...[
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const Text(
              'Processing document...',
              style: TextStyle(color: _textSecondary, fontSize: 13),
            ),
            const SizedBox(width: 8),
          ],
          OutlinedButton.icon(
            onPressed: busy ? null : onSavePng,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Save PNG'),
          ),
          OutlinedButton.icon(
            onPressed: busy ? null : onSavePdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Save PDF'),
          ),
          OutlinedButton.icon(
            onPressed: busy ? null : onPrint,
            icon: const Icon(Icons.print_outlined),
            label: const Text('Print'),
          ),
          PopupMenuButton<_ShareFormat>(
            enabled: !busy,
            tooltip: 'Share document',
            onSelected: (value) {
              switch (value) {
                case _ShareFormat.pdf:
                  onSharePdf();
                case _ShareFormat.png:
                  onSharePng();
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: _ShareFormat.pdf,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.picture_as_pdf_outlined),
                    title: Text('Share PDF'),
                  ),
                ),
                PopupMenuItem(
                  value: _ShareFormat.png,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.image_outlined),
                    title: Text('Share PNG'),
                  ),
                ),
              ];
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: busy ? Colors.grey.shade300 : _brandBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.share_outlined,
                    size: 18,
                    color: busy ? Colors.grey.shade600 : Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Share',
                    style: TextStyle(
                      color: busy ? Colors.grey.shade600 : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ShareFormat { pdf, png }

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.message, required this.onRetry});

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
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'Unable to load Leaving Certificate',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textSecondary),
            ),
            const SizedBox(height: 18),
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

class _PreviewNotGenerated extends StatelessWidget {
  const _PreviewNotGenerated();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, size: 60, color: _textSecondary),
          SizedBox(height: 14),
          Text(
            'Enter leaving details and click Generate Preview.',
            style: TextStyle(color: _textSecondary),
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
          Icon(Icons.description_outlined, size: 48, color: _textSecondary),
          SizedBox(height: 12),
          Text(
            'Template has no pages.',
            style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
