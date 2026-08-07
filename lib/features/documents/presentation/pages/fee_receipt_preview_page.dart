import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../fees/domain/entities/fee_document_request_entity.dart';
import '../../../fees/domain/entities/fee_payment_entity.dart';
import '../../../settings/domain/entities/school_settings_entity.dart';
import '../../../settings/domain/usecases/manage_settings.dart';
import '../../domain/entities/document_branding_entity.dart';
import '../../domain/entities/document_data_entity.dart';
import '../../domain/entities/document_type.dart';
import '../../domain/services/default_document_placeholder_resolver.dart';
import '../../templates/fee_receipt/fee_receipt_template_v1.dart';
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

class FeeReceiptPreviewPage extends StatefulWidget {
  const FeeReceiptPreviewPage({
    super.key,
    required this.request,
    this.className = '',
    this.sectionName = '',
  });

  final FeeReceiptDocumentRequest request;
  final String className;
  final String sectionName;

  @override
  State<FeeReceiptPreviewPage> createState() =>
      _FeeReceiptPreviewPageState();
}

class _FeeReceiptPreviewPageState
    extends State<FeeReceiptPreviewPage> {
  final GlobalKey _documentBoundaryKey = GlobalKey();

  final DocumentExportService _exportService =
      const DocumentExportService();

  late Future<SchoolSettingsEntity> _settingsFuture;

  bool _exporting = false;

  FeePaymentEntity get payment =>
      widget.request.payment;

  @override
  void initState() {
    super.initState();

    _settingsFuture =
        sl<GetSchoolSettings>()();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _PreviewHeader(
              studentName: payment.studentName,
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
    final template =
        buildFeeReceiptTemplateV1();

    final branding =
        _buildBranding(settings);

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
          DocumentRendererRegistryFactory.create(
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
                const EdgeInsets.only(
              bottom: 32,
            ),
            child: Center(
              child: RepaintBoundary(
                key: _documentBoundaryKey,
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
                          maxWidth: 560,
                          padding:
                              EdgeInsets.zero,
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
      schoolName:
          settings.schoolName,
      schoolLogoUrl:
          settings.logoUrl,
      principalName:
          settings.principalName,
      principalDesignation:
          settings.principalDesignation,
      principalSignatureUrl:
          settings.principalSignatureUrl,
      schoolStampUrl:
          settings.schoolStampUrl,
    );
  }

  DocumentDataEntity _buildDocumentData() {
    return DocumentDataEntity(
      documentType:
          DocumentType.feeReceipt,
      referenceId:
          payment.id,
      referenceType:
          'fee_payment',
      generatedAt:
          DateTime.now(),
      values: {
        'student': {
          'id':
              payment.studentId,
          'name':
              payment.studentName,
          'admissionNo':
              payment.admissionNo,
          'classSection':
              _classSection(),
        },
        'receipt': {
          'number':
              payment.receiptNumber,
          'paymentDate':
              _formatDate(
            payment.paymentDate,
          ),
          'academicSession':
              payment.academicSession,
          'allocationLines':
              _allocationLines(),
          'paymentMethod':
              _paymentMethodLabel(
            payment.method,
          ),
          'referenceNumber':
              payment.referenceNumber.trim().isEmpty
                  ? '-'
                  : payment.referenceNumber.trim(),
          'totalPaid':
              _money(payment.totalPaid),
          'advanceAmount':
              _money(payment.advanceAmount),
          'advanceUsed':
              _money(payment.advanceUsed),
          'totalApplied':
              _money(payment.totalApplied),
          'amountInWords':
              _amountInWords(
            payment.totalPaid,
          ),
          'status':
              payment.status ==
                      FeePaymentStatus.completed
                  ? 'COMPLETED'
                  : 'CANCELLED',
          'notes':
              payment.notes.trim().isEmpty
                  ? '-'
                  : payment.notes.trim(),
        },
      },
    );
  }

  String _classSection() {
    final className =
        widget.className.trim();

    final sectionName =
        widget.sectionName.trim();

    if (className.isNotEmpty &&
        sectionName.isNotEmpty) {
      return '$className - $sectionName';
    }

    if (className.isNotEmpty) {
      return className;
    }

    if (sectionName.isNotEmpty) {
      return sectionName;
    }

    return '-';
  }

  String _allocationLines() {
    if (payment.allocations.isEmpty) {
      if (payment.isAdvanceOnlyAdjustment) {
        return 'Advance Adjustment                         Rs. ${_money(payment.advanceUsed)}';
      }

      return 'Payment                                      Rs. ${_money(payment.totalPaid)}';
    }

    return payment.allocations.map((allocation) {
      final title =
          allocation.dueType ==
                  FeeDueType.additionalCharge
              ? 'Additional Charge'
              : '${_monthName(allocation.month)} ${allocation.year}';

      return '${title.padRight(34)}Rs. ${_money(allocation.amount)}';
    }).join('\n');
  }

  String _paymentMethodLabel(
    FeePaymentMethod method,
  ) {
    return switch (method) {
      FeePaymentMethod.cash =>
        'Cash',
      FeePaymentMethod.bankTransfer =>
        'Bank Transfer',
      FeePaymentMethod.easypaisa =>
        'Easypaisa',
      FeePaymentMethod.jazzCash =>
        'JazzCash',
    };
  }

  String _monthName(int month) {
    const months = [
      '',
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

    if (month < 1 ||
        month > 12) {
      return 'Month $month';
    }

    return months[month];
  }

  String _money(double value) {
    if (value ==
        value.roundToDouble()) {
      return value
          .toInt()
          .toString();
    }

    return value.toStringAsFixed(2);
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

  String _amountInWords(double amount) {
    final whole =
        amount.floor();

    final paisa =
        ((amount - whole) * 100)
            .round();

    var result =
        '${_numberToWords(whole)} Rupees';

    if (paisa > 0) {
      result =
          '$result and ${_numberToWords(paisa)} Paisa';
    }

    return '$result Only';
  }

  String _numberToWords(int number) {
    if (number == 0) {
      return 'Zero';
    }

    if (number < 0) {
      return 'Minus ${_numberToWords(number.abs())}';
    }

    const units = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];

    const tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    if (number < 20) {
      return units[number];
    }

    if (number < 100) {
      final remainder =
          number % 10;

      return remainder == 0
          ? tens[number ~/ 10]
          : '${tens[number ~/ 10]} ${units[remainder]}';
    }

    if (number < 1000) {
      final remainder =
          number % 100;

      final prefix =
          '${units[number ~/ 100]} Hundred';

      return remainder == 0
          ? prefix
          : '$prefix ${_numberToWords(remainder)}';
    }

    if (number < 100000) {
      final remainder =
          number % 1000;

      final prefix =
          '${_numberToWords(number ~/ 1000)} Thousand';

      return remainder == 0
          ? prefix
          : '$prefix ${_numberToWords(remainder)}';
    }

    if (number < 10000000) {
      final remainder =
          number % 100000;

      final prefix =
          '${_numberToWords(number ~/ 100000)} Lakh';

      return remainder == 0
          ? prefix
          : '$prefix ${_numberToWords(remainder)}';
    }

    final remainder =
        number % 10000000;

    final prefix =
        '${_numberToWords(number ~/ 10000000)} Crore';

    return remainder == 0
        ? prefix
        : '$prefix ${_numberToWords(remainder)}';
  }

  Future<Uint8List> _capturePng({
    required double pixelRatio,
  }) {
    return _exportService.capturePng(
      boundaryKey:
          _documentBoundaryKey,
      pixelRatio:
          pixelRatio,
    );
  }

  Future<Uint8List> _buildPdf() async {
    final template =
        buildFeeReceiptTemplateV1();

    if (template.orderedPages.isEmpty) {
      throw StateError(
        'Fee Receipt template has no pages.',
      );
    }

    final page =
        template.orderedPages.first;

    final pngBytes =
        await _capturePng(
      pixelRatio: 2,
    );

    return _exportService
        .createPdfFromPng(
      pngBytes: pngBytes,
      aspectRatio:
          page.width / page.height,
      title:
          'Fee Receipt - ${payment.studentName}',
    );
  }

  Future<void> _savePng() async {
    await _runExport(() async {
      final path =
          await _exportService.savePng(
        bytes:
            await _capturePng(
          pixelRatio: 3,
        ),
        fileName:
            '${_baseFileName()}_fee_receipt',
      );

      if (path != null) {
        _showSuccess(
          'Fee Receipt PNG saved successfully.',
        );
      }
    });
  }

  Future<void> _savePdf() async {
    await _runExport(() async {
      final path =
          await _exportService.savePdf(
        bytes:
            await _buildPdf(),
        fileName:
            '${_baseFileName()}_fee_receipt',
      );

      if (path != null) {
        _showSuccess(
          'Fee Receipt PDF saved successfully.',
        );
      }
    });
  }

  Future<void> _printPdf() async {
    await _runExport(() async {
      await _exportService.printPdf(
        bytes:
            await _buildPdf(),
        name:
            'Fee Receipt - ${payment.studentName}',
      );
    });
  }

  Future<void> _sharePdf() async {
    await _runExport(() async {
      await _exportService.sharePdf(
        bytes:
            await _buildPdf(),
        fileName:
            '${_baseFileName()}_fee_receipt.pdf',
      );
    });
  }

  Future<void> _sharePng() async {
    await _runExport(() async {
      await _exportService.sharePng(
        bytes:
            await _capturePng(
          pixelRatio: 3,
        ),
        fileName:
            '${_baseFileName()}_fee_receipt.png',
        text:
            'Fee Receipt - ${payment.studentName}',
      );
    });
  }

  Future<void> _runExport(
    Future<void> Function() action,
  ) async {
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
      '${payment.studentName}_${payment.receiptNumber}',
      fallback:
          'fee_receipt',
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
          content:
              Text(message),
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

class _PreviewHeader
    extends StatelessWidget {
  const _PreviewHeader({
    required this.studentName,
  });

  final String studentName;

  @override
  Widget build(
    BuildContext context,
  ) {
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
      child: Row(
        children: [
          const DashboardNavigationButton(),
          const SizedBox(
            width: 14,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fee Receipt Preview',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        _textPrimary,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  'Receipt for $studentName',
                  style:
                      const TextStyle(
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
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 24,
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
        alignment: WrapAlignment.end,
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
            itemBuilder: (_) =>
                const [
              PopupMenuItem(
                value:
                    _ShareFormat.pdf,
                child:
                    Text('Share PDF'),
              ),
              PopupMenuItem(
                value:
                    _ShareFormat.png,
                child:
                    Text('Share PNG'),
              ),
            ],
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              decoration:
                  BoxDecoration(
                color: busy
                    ? Colors
                        .grey.shade300
                    : _brandBlue,
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              child: const Row(
                mainAxisSize:
                    MainAxisSize.min,
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
                      fontWeight:
                          FontWeight.w600,
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

class _LoadFailure
    extends StatelessWidget {
  const _LoadFailure({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

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
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              'Unable to load Fee Receipt',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 17,
                fontWeight:
                    FontWeight.w700,
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
              icon: const Icon(
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
