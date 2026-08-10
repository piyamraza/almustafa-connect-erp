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
import '../../templates/student_id_card/student_id_card_template_v1.dart';
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

class StudentIdCardPreviewPage extends StatefulWidget {
  const StudentIdCardPreviewPage({
    super.key,
    required this.student,
    this.className = '',
    this.sectionName = '',
  });

  final StudentEntity student;
  final String className;
  final String sectionName;

  @override
  State<StudentIdCardPreviewPage> createState() =>
      _StudentIdCardPreviewPageState();
}

class _StudentIdCardPreviewPageState extends State<StudentIdCardPreviewPage> {
  final GlobalKey _documentBoundaryKey = GlobalKey();

  final DocumentExportService _exportService = const DocumentExportService();

  late Future<SchoolSettingsEntity> _settingsFuture;

  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _settingsFuture = sl<GetSchoolSettings>()();
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

                  return _buildPreview(settings);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(SchoolSettingsEntity settings) {
    final template = buildStudentIdCardTemplateV1();

    final branding = _buildBranding(settings);

    final data = _buildDocumentData();

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
                          maxWidth: 420,
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

  DocumentDataEntity _buildDocumentData() {
    final student = widget.student;

    return DocumentDataEntity(
      documentType: DocumentType.idCard,
      referenceId: student.id,
      referenceType: 'student',
      generatedAt: DateTime.now(),
      values: {
        'student': {
          'id': student.id,
          'name': student.fullName,
          'firstName': student.firstName,
          'lastName': student.lastName,
          'admissionNo': student.admissionNo,
          'rollNumber': student.rollNumber,
          'gender': student.gender,
          'classId': student.classId,
          'sectionId': student.sectionId,
          'class': widget.className,
          'section': widget.sectionName,
          'classSection': _buildClassSectionLabel(),
          'dateOfBirth': _formatDate(student.dateOfBirth),
          'photo': student.profileImageUrl,
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
    final template = buildStudentIdCardTemplateV1();

    final pages = template.orderedPages;

    if (pages.isEmpty) {
      throw StateError('Student ID Card template has no pages.');
    }

    final firstPage = pages.first;

    final pngBytes = await _capturePng(pixelRatio: 3);

    final aspectRatio = firstPage.width / firstPage.height;

    return _exportService.createPdfFromPng(
      pngBytes: pngBytes,
      aspectRatio: aspectRatio,
      title: 'Student ID Card - ${widget.student.fullName}',
    );
  }

  Future<void> _savePng() async {
    await _runExport(() async {
      final bytes = await _capturePng(pixelRatio: 3);

      final path = await _exportService.savePng(
        bytes: bytes,
        fileName: '${_baseFileName()}_student_id_card',
      );

      if (path != null) {
        _showSuccess('Student ID Card PNG saved successfully.');
      }
    });
  }

  Future<void> _savePdf() async {
    await _runExport(() async {
      final bytes = await _buildPdf();

      final path = await _exportService.savePdf(
        bytes: bytes,
        fileName: '${_baseFileName()}_student_id_card',
      );

      if (path != null) {
        _showSuccess('Student ID Card PDF saved successfully.');
      }
    });
  }

  Future<void> _printPdf() async {
    await _runExport(() async {
      final bytes = await _buildPdf();

      await _exportService.printPdf(
        bytes: bytes,
        name: 'Student ID Card - ${widget.student.fullName}',
      );
    });
  }

  Future<void> _sharePdf() async {
    await _runExport(() async {
      final bytes = await _buildPdf();

      await _exportService.sharePdf(
        bytes: bytes,
        fileName: '${_baseFileName()}_student_id_card.pdf',
      );
    });
  }

  Future<void> _sharePng() async {
    await _runExport(() async {
      final bytes = await _capturePng(pixelRatio: 3);

      await _exportService.sharePng(
        bytes: bytes,
        fileName: '${_baseFileName()}_student_id_card.png',
        text: 'Student ID Card - ${widget.student.fullName}',
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
      fallback: 'student_id_card',
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
                  'Student ID Card Preview',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  studentName.trim().isEmpty
                      ? 'Student ID Card'
                      : 'ID Card for $studentName',
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
            onSelected: (value) {
              switch (value) {
                case _ShareFormat.pdf:
                  onSharePdf();
                case _ShareFormat.png:
                  onSharePng();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: _ShareFormat.pdf, child: Text('Share PDF')),
              PopupMenuItem(value: _ShareFormat.png, child: Text('Share PNG')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: busy ? Colors.grey.shade300 : _brandBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.share_outlined, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Share',
                    style: TextStyle(
                      color: Colors.white,
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
              'Unable to load Student ID Card',
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

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Student ID Card template has no pages.'));
  }
}
