import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../../exams/domain/services/result_subject_grouping_service.dart';
import '../../../results/domain/entities/student_development_profile_entity.dart';
import '../../../results/domain/services/result_card_insight_service.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../settings/domain/entities/school_settings_entity.dart';
import '../../../settings/domain/usecases/manage_settings.dart';
import '../../domain/entities/document_branding_entity.dart';
import '../../domain/entities/document_data_entity.dart';
import '../../domain/entities/document_type.dart';
import '../../domain/services/default_document_placeholder_resolver.dart';
import '../../templates/result_card/result_card_template_v1.dart';
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

class ResultCardPreviewPage extends StatefulWidget {
  const ResultCardPreviewPage({
    super.key,
    required this.result,
    this.student,
    this.attendancePercentage,
    this.attendanceDays = 0,
    this.attendedDays = 0,
    this.punctualityRating = 0,
    this.developmentProfile,
    this.classAverage,
    this.highestPercentage,
    this.termProgress = const [],
  });

  final ExamResultEntity result;
  final StudentEntity? student;
  final double? attendancePercentage;
  final int attendanceDays;
  final int attendedDays;
  final int punctualityRating;
  final StudentDevelopmentProfileEntity? developmentProfile;
  final double? classAverage;
  final double? highestPercentage;
  final List<String> termProgress;

  @override
  State<ResultCardPreviewPage> createState() => _ResultCardPreviewPageState();
}

class _ResultCardPreviewPageState extends State<ResultCardPreviewPage> {
  final GlobalKey _documentBoundaryKey = GlobalKey();

  final DocumentExportService _exportService = const DocumentExportService();

  late Future<_ResultCardResources> _resourcesFuture;

  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _resourcesFuture = _loadResources();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _PreviewHeader(studentName: widget.result.studentName),
            Expanded(
              child: FutureBuilder<_ResultCardResources>(
                future: _resourcesFuture,
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

                  final resources = snapshot.data;

                  if (resources == null) {
                    return _LoadFailure(
                      message: 'School Settings could not be loaded.',
                      onRetry: _reload,
                    );
                  }

                  return _buildPreview(
                    resources.settings,
                    resources.studentPhotoBytes,
                  );
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
    Uint8List? studentPhotoBytes,
  ) {
    final template = buildResultCardTemplateV1();
    final branding = _buildBranding(settings);
    final data = _buildDocumentData(settings, studentPhotoBytes);

    final values = {
      ...data.values,
      'branding': {
        'schoolName': branding.schoolName,
        'schoolAddress': settings.address,
        'schoolContact': [
          settings.phone.trim(),
          settings.email.trim(),
        ].where((value) => value.isNotEmpty).join('  •  '),
        'schoolLogo': branding.schoolLogoUrl,
        'principalName': branding.principalName,
        'principalDesignation': branding.principalDesignation,
        'principalSignature': principalSignatureImageValue(branding),
        'schoolStamp': schoolStampImageValue(branding),
      },
    };

    final placeholderResolver = const DefaultDocumentPlaceholderResolver();

    final registry = DocumentRendererRegistryFactory.create(
      placeholderResolver: placeholderResolver,
    );

    final renderer = FlutterDocumentRenderer(
      registry: registry,
      visibilityResolver: DocumentElementVisibilityResolver(
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
            padding: const EdgeInsets.only(bottom: 32),
            child: Center(
              child: SizedBox(
                width: 760,
                child: RepaintBoundary(
                  key: _documentBoundaryKey,
                  child: ColoredBox(
                    color: Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final page in template.orderedPages)
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

  DocumentDataEntity _buildDocumentData(
    SchoolSettingsEntity settings,
    Uint8List? studentPhotoBytes,
  ) {
    final result = widget.result;

    return DocumentDataEntity(
      documentType: DocumentType.resultCard,
      referenceId: result.id,
      referenceType: 'exam_result',
      generatedAt: DateTime.now(),
      values: {
        'student': {
          'id': result.studentId,
          'name': result.studentName,
          'admissionNo': result.admissionNo,
          'rollNumber': result.rollNumber,
          'classSection': '${result.className} - ${result.sectionName}',
          'fatherName': widget.student?.fatherName.trim() ?? '',
          'dateOfBirth': widget.student == null
              ? ''
              : _date(widget.student!.dateOfBirth),
          'photo': _studentPhotoSource(studentPhotoBytes),
        },
        'result': {
          'examName': result.examName,
          'academicSession': result.academicSession,
          'subjectRows': _subjectRows(result),
          'totalMarks': _number(result.grandTotalMarks),
          'obtainedMarks': _number(result.grandObtainedMarks),
          'percentage': result.percentage.toStringAsFixed(2),
          'grade': result.grade,
          'status': result.isPassed ? 'PASS' : 'FAIL',
          'classPosition': _position(result.classPosition),
          'sectionPosition': _position(result.sectionPosition),
          'overallRank': _position(result.overallRank),
          'principalRemarks': result.principalRemarks.trim(),
          'teacherRemarks': const ResultCardInsightService().teacherRemark(
            result,
          ),
          'attendance': widget.attendanceDays <= 0
              ? ''
              : '${widget.attendedDays} / ${widget.attendanceDays} Days',
          'developmentProfile': _developmentProfileLines(),
          'developmentRatings': _developmentRatings(),
          'scoreBadge': {
            'percentage': result.percentage.toStringAsFixed(1),
            'grade': result.grade,
          },
          'profileDetails': {
            'name': result.studentName,
            'fatherName': widget.student?.fatherName.trim() ?? '',
            'admissionNo': result.admissionNo,
            'classSection': '${result.className} - ${result.sectionName}',
            'rollNumber': result.rollNumber,
            'attendance': widget.attendanceDays <= 0
                ? ''
                : '${widget.attendedDays} / ${widget.attendanceDays} Days',
            'dateOfBirth': widget.student == null
                ? ''
                : _date(widget.student!.dateOfBirth),
            'status': result.isPassed ? 'PASS' : 'FAIL',
          },
          'summaryData': {
            'obtained': _number(result.grandObtainedMarks),
            'total': _number(result.grandTotalMarks),
            'percentage': result.percentage.toStringAsFixed(2),
            'grade': result.grade,
            'classPosition': _position(result.classPosition),
            'sectionPosition': _position(result.sectionPosition),
          },
          'comparisonData': {
            'student': result.percentage.toStringAsFixed(1),
            'classAverage': (widget.classAverage ?? result.percentage)
                .toStringAsFixed(1),
            'highest': (widget.highestPercentage ?? result.percentage)
                .toStringAsFixed(1),
          },
          'termProgressData': _termProgressRows(),
          'showTermProgress': widget.termProgress.isNotEmpty,
          'generalRemarks': _generalRemarks(result),
          'comparison': _comparisonLine(),
          'showComparison': true,
          'verificationPayload': _verificationPayload(settings.website),
        },
      },
    );
  }

  Object _studentPhotoSource(Uint8List? photoBytes) {
    if (photoBytes != null && photoBytes.isNotEmpty) return photoBytes;
    final stored = widget.student?.profileImageUrl.trim() ?? '';
    final studentId = (widget.student?.id ?? widget.result.studentId).trim();
    if (studentId.isNotEmpty) {
      return <String, String>{'studentId': studentId, 'storedUrl': stored};
    }
    return stored;
  }

  String _developmentProfileLines() {
    final profile = widget.developmentProfile;
    String stars(int value) =>
        value <= 0 ? 'Not rated' : '${'★' * value}${'☆' * (5 - value)}';
    return [
      'Discipline             ${stars(profile?.discipline ?? 0)}',
      'Punctuality            ${stars(widget.punctualityRating)}',
      'Communication          ${stars(profile?.communication ?? 0)}',
      'Class Participation    ${stars(profile?.classParticipation ?? 0)}',
      'Homework               ${stars(profile?.homework ?? 0)}',
      'Personal Hygiene       ${stars(profile?.personalHygiene ?? 0)}',
    ].join('\n');
  }

  List<Map<String, Object>> _developmentRatings() {
    final profile = widget.developmentProfile;
    return [
      {'label': 'Discipline', 'rating': profile?.discipline ?? 0},
      {'label': 'Punctuality', 'rating': widget.punctualityRating},
      {'label': 'Communication', 'rating': profile?.communication ?? 0},
      {
        'label': 'Class Participation',
        'rating': profile?.classParticipation ?? 0,
      },
      {'label': 'Homework', 'rating': profile?.homework ?? 0},
      {'label': 'Personal Hygiene', 'rating': profile?.personalHygiene ?? 0},
    ];
  }

  List<Map<String, String>> _termProgressRows() {
    return widget.termProgress
        .map((entry) {
          final match = RegExp(
            r'^(.*?):\s*([0-9]+(?:\.[0-9]+)?)%?\s*$',
          ).firstMatch(entry.trim());
          return {
            'label': match?.group(1)?.trim() ?? entry.trim(),
            'value': match?.group(2) ?? '',
          };
        })
        .where((entry) => entry['value']!.isNotEmpty)
        .toList(growable: false);
  }

  String _generalRemarks(ExamResultEntity result) {
    final lines = <String>[];
    if (result.percentage >= 80) {
      lines.add('Demonstrates strong understanding of key concepts.');
    } else if (result.percentage >= 60) {
      lines.add('Shows steady progress and interest in learning.');
    } else {
      lines.add('Needs structured support and regular guided practice.');
    }
    if (widget.punctualityRating >= 4) {
      lines.add('Maintains good attendance and punctuality.');
    } else if (widget.punctualityRating > 0) {
      lines.add('Improved punctuality will support better learning.');
    }
    lines.add('Regular revision and practice will lead to excellence.');
    return lines.map((line) => '•  $line').join('\n');
  }

  String _comparisonLine() {
    final parts = <String>[
      'Student: ${widget.result.percentage.toStringAsFixed(1)}%',
      if (widget.classAverage != null)
        'Class Average: ${widget.classAverage!.toStringAsFixed(1)}%',
      if (widget.highestPercentage != null)
        'Highest: ${widget.highestPercentage!.toStringAsFixed(1)}%',
    ];
    final progress = widget.termProgress.isEmpty
        ? ''
        : '\nTerm Progress: ${widget.termProgress.join('  →  ')}';
    return '${parts.join('     ')}$progress';
  }

  String _verificationPayload(String website) {
    final base = website.trim().replaceFirst(RegExp(r'/$'), '');
    if (base.isNotEmpty) return '$base/verify/result/${widget.result.id}';
    return 'AMS-RESULT:${widget.result.id}:${widget.result.studentId}:${widget.result.percentage.toStringAsFixed(2)}';
  }

  List<Map<String, String>> _subjectRows(ExamResultEntity result) {
    final insights = const ResultCardInsightService();
    return ResultSubjectGroupingService.group(result.subjectResults)
        .map((subject) {
          final components = subject.components
              .map((component) {
                final label = component.label
                    .replaceAll(RegExp('main paper', caseSensitive: false), '')
                    .trim();
                final marks = component.isAbsent
                    ? 'Absent'
                    : '${_number(component.obtainedMarks)}/${_number(component.totalMarks)}';
                return label.isEmpty ? marks : '$label: $marks';
              })
              .join('  ·  ');
          return <String, String>{
            'subject': subject.subjectName,
            'components': components,
            'total': _number(subject.totalMarks),
            'obtained': _number(subject.obtainedMarks),
            'percentage': '${subject.percentage.toStringAsFixed(1)}%',
            'grade': insights.subjectGrade(subject.percentage),
            'remarks': subject.remarks.trim().isEmpty
                ? insights.subjectRemark(subject.percentage)
                : subject.remarks.trim(),
          };
        })
        .toList(growable: false);
  }

  String _number(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  String _position(int value) {
    return value <= 0 ? '-' : value.toString();
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  Future<Uint8List> _capturePng({required double pixelRatio}) {
    return _exportService.capturePng(
      boundaryKey: _documentBoundaryKey,
      pixelRatio: pixelRatio,
    );
  }

  Future<Uint8List> _buildPdf() async {
    final template = buildResultCardTemplateV1();

    if (template.orderedPages.isEmpty) {
      throw StateError('Result Card template has no pages.');
    }

    final page = template.orderedPages.first;

    final pngBytes = await _capturePng(pixelRatio: 1.5);

    return _exportService.createPdfFromPng(
      pngBytes: pngBytes,
      aspectRatio: page.width / page.height,
      title: 'Result Card - ${widget.result.studentName}',
    );
  }

  Future<void> _savePng() async {
    await _runExport(() async {
      final bytes = await _capturePng(pixelRatio: 3);

      final path = await _exportService.savePng(
        bytes: bytes,
        fileName: '${_baseFileName()}_result_card',
      );

      if (path != null) {
        _showSuccess('Result Card PNG saved successfully.');
      }
    });
  }

  Future<void> _savePdf() async {
    await _runExport(() async {
      final path = await _exportService.savePdf(
        bytes: await _buildPdf(),
        fileName: '${_baseFileName()}_result_card',
      );

      if (path != null) {
        _showSuccess('Result Card PDF saved successfully.');
      }
    });
  }

  Future<void> _printPdf() async {
    await _runExport(() async {
      await _exportService.printPdf(
        bytes: await _buildPdf(),
        name: 'Result Card - ${widget.result.studentName}',
      );
    });
  }

  Future<void> _sharePdf() async {
    await _runExport(() async {
      await _exportService.sharePdf(
        bytes: await _buildPdf(),
        fileName: '${_baseFileName()}_result_card.pdf',
      );
    });
  }

  Future<void> _sharePng() async {
    await _runExport(() async {
      await _exportService.sharePng(
        bytes: await _capturePng(pixelRatio: 3),
        fileName: '${_baseFileName()}_result_card.png',
        text: 'Result Card - ${widget.result.studentName}',
      );
    });
  }

  Future<void> _runExport(Future<void> Function() action) async {
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
      widget.result.studentName,
      fallback: 'result_card',
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _reload() {
    setState(() {
      _resourcesFuture = _loadResources();
    });
  }

  Future<_ResultCardResources> _loadResources() async {
    final settingsFuture = sl<GetSchoolSettings>()();
    final photoFuture = _loadStudentPhotoBytes();
    return _ResultCardResources(
      settings: await settingsFuture,
      studentPhotoBytes: await photoFuture,
    );
  }

  Future<Uint8List?> _loadStudentPhotoBytes() async {
    final studentId = (widget.student?.id ?? widget.result.studentId).trim();
    if (studentId.isEmpty) return null;

    try {
      final response = await sl<FirebaseFunctions>()
          .httpsCallable('getStudentPhotoForExport')
          .call(<String, Object>{'studentId': studentId});
      final data = Map<String, dynamic>.from(response.data as Map);
      final encoded = (data['base64'] ?? '').toString();
      return encoded.isEmpty ? null : base64Decode(encoded);
    } catch (error, stackTrace) {
      debugPrint('Could not preload student photo for export: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }
}

class _ResultCardResources {
  const _ResultCardResources({
    required this.settings,
    required this.studentPhotoBytes,
  });

  final SchoolSettingsEntity settings;
  final Uint8List? studentPhotoBytes;
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
                  'Result Card Preview',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Result Card for $studentName',
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
        children: [
          if (busy) const CircularProgressIndicator(strokeWidth: 2),
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
              child: const Text(
                'Share',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
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
              'Unable to load Result Card',
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
