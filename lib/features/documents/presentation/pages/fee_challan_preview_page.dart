import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../fees/domain/entities/fee_document_request_entity.dart';
import '../../../fees/domain/entities/monthly_fee_due_entity.dart';
import '../../../settings/domain/entities/school_settings_entity.dart';
import '../../../settings/domain/usecases/manage_settings.dart';
import '../../domain/entities/document_branding_entity.dart';
import '../../domain/entities/document_data_entity.dart';
import '../../domain/entities/document_type.dart';
import '../../domain/services/default_document_placeholder_resolver.dart';
import '../../templates/fee_challan/fee_challan_template_v1.dart';
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

class FeeChallanPreviewPage extends StatefulWidget {
  const FeeChallanPreviewPage({
    super.key,
    required this.request,
  });

  final FeeChallanDocumentRequest request;

  @override
  State<FeeChallanPreviewPage> createState() =>
      _FeeChallanPreviewPageState();
}

class _FeeChallanPreviewPageState
    extends State<FeeChallanPreviewPage> {
  final GlobalKey _documentBoundaryKey = GlobalKey();

  final DocumentExportService _exportService =
      const DocumentExportService();

  late Future<SchoolSettingsEntity> _settingsFuture;

  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _settingsFuture = sl<GetSchoolSettings>()();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.request.dues.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No fee dues selected for challan.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _PreviewHeader(
              studentName:
                  widget.request.dues.first.studentName,
            ),
            Expanded(
              child: FutureBuilder<SchoolSettingsEntity>(
                future: _settingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
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
                      message:
                          'School Settings could not be loaded.',
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

  Widget _buildPreview(
    SchoolSettingsEntity settings,
  ) {
    final template = buildFeeChallanTemplateV1(
      copyCount: widget.request.copyCount,
    );

    final branding = _buildBranding(settings);
    final data = _buildDocumentData();

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
          onSavePng: _savePng,
          onSavePdf: _savePdf,
          onPrint: _printPdf,
          onSharePdf: _sharePdf,
          onSharePng: _sharePng,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              bottom: 32,
            ),
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
                          maxWidth: 1100,
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

  DocumentBrandingEntity _buildBranding(
    SchoolSettingsEntity settings,
  ) {
    return DocumentBrandingEntity(
      schoolName: settings.schoolName,
      schoolLogoUrl: settings.logoUrl,
      principalName: settings.principalName,
      principalDesignation:
          settings.principalDesignation,
      principalSignatureUrl:
          settings.principalSignatureUrl,
      schoolStampUrl: settings.schoolStampUrl,
    );
  }

  DocumentDataEntity _buildDocumentData() {
    final dues = widget.request.dues;
    final first = dues.first;

    final earliestDueDate = dues
        .map((item) => item.dueDate)
        .reduce(
          (a, b) => a.isBefore(b) ? a : b,
        );

    final tuitionFee =
        _sum(dues, (item) => item.tuitionFee);

    final transportFee =
        _sum(dues, (item) => item.transportFee);

    final otherCharges = _sum(
      dues,
      (item) => item.otherMonthlyCharges,
    );

    final previousArrears =
        _sum(dues, (item) => item.previousArrears);

    final totalDiscount = _sum(
      dues,
      (item) =>
          item.discountAmount +
          item.scholarshipAmount +
          item.siblingDiscountAmount,
    );

    final advanceAdjustment =
        _sum(dues, (item) => item.advanceAdjustment);

    final netPayable =
        _sum(dues, (item) => item.netPayable);

    final paidAmount =
        _sum(dues, (item) => item.paidAmount);

    final outstanding =
        _sum(dues, (item) => item.outstandingAmount);

    return DocumentDataEntity(
      documentType: DocumentType.feeChallan,
      referenceId: first.id,
      referenceType: 'monthly_fee_due',
      generatedAt: DateTime.now(),
      values: {
        'student': {
          'id': first.studentId,
          'name': first.studentName,
          'admissionNo': first.admissionNo,
          'classSection':
              _classSection(first),
        },
        'fee': {
          'challanNumber':
              _challanNumber(first),
          'academicSession':
              first.academicSession,
          'months': _monthsLabel(dues),
          'dueDate':
              _formatDate(earliestDueDate),
          'tuitionFee':
              _money(tuitionFee),
          'transportFee':
              _money(transportFee),
          'otherCharges':
              _money(otherCharges),
          'previousArrears':
              _money(previousArrears),
          'totalDiscount':
              _money(totalDiscount),
          'advanceAdjustment':
              _money(advanceAdjustment),
          'netPayable':
              _money(netPayable),
          'paidAmount':
              _money(paidAmount),
          'outstanding':
              _money(outstanding),
          'status':
              _statusLabel(dues),
        },
      },
    );
  }

  double _sum(
    List<MonthlyFeeDueEntity> dues,
    double Function(MonthlyFeeDueEntity) value,
  ) {
    return dues.fold<double>(
      0,
      (total, item) => total + value(item),
    );
  }

  String _classSection(
    MonthlyFeeDueEntity due,
  ) {
    final className = due.classId.trim();
    final sectionName = due.sectionId.trim();

    if (className.isNotEmpty &&
        sectionName.isNotEmpty) {
      return '$className - $sectionName';
    }

    if (className.isNotEmpty) {
      return className;
    }

    return sectionName;
  }

  String _challanNumber(
    MonthlyFeeDueEntity due,
  ) {
    final cleanId =
        due.id.trim().replaceAll(' ', '');

    if (cleanId.isNotEmpty) {
      return cleanId;
    }

    return 'FC-${due.year}-${due.month.toString().padLeft(2, '0')}-${due.studentId}';
  }

  String _monthsLabel(
    List<MonthlyFeeDueEntity> dues,
  ) {
    final sorted =
        List<MonthlyFeeDueEntity>.from(dues)
          ..sort((a, b) {
            final yearCompare =
                a.year.compareTo(b.year);

            if (yearCompare != 0) {
              return yearCompare;
            }

            return a.month.compareTo(b.month);
          });

    return sorted
        .map(
          (due) =>
              '${_monthName(due.month)} ${due.year}',
        )
        .join(', ');
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (month < 1 || month > 12) {
      return month.toString();
    }

    return months[month];
  }

  String _statusLabel(
    List<MonthlyFeeDueEntity> dues,
  ) {
    if (dues.every(
      (item) =>
          item.status == MonthlyFeeDueStatus.paid,
    )) {
      return 'PAID';
    }

    if (dues.any(
      (item) =>
          item.status ==
          MonthlyFeeDueStatus.partiallyPaid,
    )) {
      return 'PARTIALLY PAID';
    }

    if (dues.every(
      (item) =>
          item.status ==
          MonthlyFeeDueStatus.cancelled,
    )) {
      return 'CANCELLED';
    }

    return 'UNPAID';
  }

  String _money(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  String _formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
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
    final template = buildFeeChallanTemplateV1(
      copyCount: widget.request.copyCount,
    );

    if (template.orderedPages.isEmpty) {
      throw StateError(
        'Fee Challan template has no pages.',
      );
    }

    final page = template.orderedPages.first;

    final pngBytes = await _capturePng(
      pixelRatio: 1.5,
    );

    return _exportService.createPdfFromPng(
      pngBytes: pngBytes,
      aspectRatio: page.width / page.height,
      title:
          'Fee Challan - ${widget.request.dues.first.studentName}',
    );
  }

  Future<void> _savePng() async {
    await _runExport(() async {
      final path =
          await _exportService.savePng(
        bytes: await _capturePng(
          pixelRatio: 3,
        ),
        fileName:
            '${_baseFileName()}_fee_challan',
      );

      if (path != null) {
        _showSuccess(
          'Fee Challan PNG saved successfully.',
        );
      }
    });
  }

  Future<void> _savePdf() async {
    await _runExport(() async {
      final path =
          await _exportService.savePdf(
        bytes: await _buildPdf(),
        fileName:
            '${_baseFileName()}_fee_challan',
      );

      if (path != null) {
        _showSuccess(
          'Fee Challan PDF saved successfully.',
        );
      }
    });
  }

  Future<void> _printPdf() async {
    await _runExport(() async {
      await _exportService.printPdf(
        bytes: await _buildPdf(),
        name:
            'Fee Challan - ${widget.request.dues.first.studentName}',
      );
    });
  }

  Future<void> _sharePdf() async {
    await _runExport(() async {
      await _exportService.sharePdf(
        bytes: await _buildPdf(),
        fileName:
            '${_baseFileName()}_fee_challan.pdf',
      );
    });
  }

  Future<void> _sharePng() async {
    await _runExport(() async {
      await _exportService.sharePng(
        bytes: await _capturePng(
          pixelRatio: 3,
        ),
        fileName:
            '${_baseFileName()}_fee_challan.png',
        text:
            'Fee Challan - ${widget.request.dues.first.studentName}',
      );
    });
  }

  Future<void> _runExport(
    Future<void> Function() action,
  ) async {
    if (_exporting) return;

    setState(() {
      _exporting = true;
    });

    try {
      await action();
    } catch (error) {
      if (!mounted) return;

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

  String _baseFileName() {
    return _exportService.safeFileName(
      widget.request.dues.first.studentName,
      fallback: 'fee_challan',
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  void _reload() {
    setState(() {
      _settingsFuture =
          sl<GetSchoolSettings>()();
    });
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({
    required this.studentName,
  });

  final String studentName;

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
      child: Row(
        children: [
          const DashboardNavigationButton(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fee Challan Preview',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Fee Challan for $studentName',
                  style: const TextStyle(
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
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
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
        alignment: WrapAlignment.end,
        children: [
          if (busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          OutlinedButton.icon(
            onPressed: busy ? null : onSavePng,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Save PNG'),
          ),
          OutlinedButton.icon(
            onPressed: busy ? null : onSavePdf,
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
            ),
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
              PopupMenuItem(
                value: _ShareFormat.pdf,
                child: Text('Share PDF'),
              ),
              PopupMenuItem(
                value: _ShareFormat.png,
                child: Text('Share PNG'),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: busy
                    ? Colors.grey.shade300
                    : _brandBlue,
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.share_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
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

enum _ShareFormat {
  pdf,
  png,
}

class _LoadFailure extends StatelessWidget {
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
            const Text(
              'Unable to load Fee Challan',
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
              style: const TextStyle(
                color: _textSecondary,
              ),
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
