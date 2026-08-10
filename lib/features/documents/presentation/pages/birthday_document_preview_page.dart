import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../school_engagement/domain/entities/engagement_person_entity.dart';
import '../../../settings/domain/entities/school_settings_entity.dart';
import '../../../settings/domain/usecases/manage_settings.dart';
import '../../domain/entities/document_branding_entity.dart';
import '../../domain/entities/document_data_entity.dart';
import '../../domain/entities/document_template_entity.dart';
import '../../domain/entities/document_type.dart';
import '../../domain/services/default_document_placeholder_resolver.dart';
import '../../templates/birthday/birthday_card_template_v1.dart';
import '../../templates/birthday/birthday_card_template_boy_v2.dart';
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

class BirthdayDocumentPreviewPage extends StatefulWidget {
  const BirthdayDocumentPreviewPage({super.key, required this.person});

  final EngagementPersonEntity person;

  @override
  State<BirthdayDocumentPreviewPage> createState() =>
      _BirthdayDocumentPreviewPageState();
}

class _BirthdayDocumentPreviewPageState
    extends State<BirthdayDocumentPreviewPage> {
  final GlobalKey _documentBoundaryKey = GlobalKey();

  final DocumentExportService _exportService = const DocumentExportService();

  late Future<_BirthdayPreviewAssets> _settingsFuture;

  bool _exporting = false;

  late final TextEditingController _birthdayMessageController;

  @override
  void initState() {
    super.initState();

    _birthdayMessageController = TextEditingController(
      text:
          'Wishing you a day filled with happiness, success and wonderful memories.',
    );

    _settingsFuture = _loadPreviewAssets();
  }

  @override
  void dispose() {
    _birthdayMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _PreviewHeader(personName: widget.person.displayName),
            Expanded(
              child: FutureBuilder<_BirthdayPreviewAssets>(
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

                  final assets = snapshot.data;

                  if (assets == null) {
                    return _LoadFailure(
                      message: 'School Settings could not be loaded.',
                      onRetry: _reload,
                    );
                  }

                  return _buildPreview(assets);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(_BirthdayPreviewAssets assets) {
    final settings = assets.settings;
    final template = _birthdayTemplateFor(widget.person);

    final branding = _buildBranding(settings);

    final data = _buildBirthdayData(
      widget.person,
      classSectionLabel: assets.classSectionLabel,
    );

    final values = _buildRenderValues(
      branding: branding,
      data: data,
      schoolLogo: assets.schoolLogo,
      principalSignature: assets.principalSignature,
    );

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
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: TextField(
            controller: _birthdayMessageController,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Edit Birthday Wish',
              hintText: 'Write birthday wish message',
              prefixIcon: Icon(Icons.edit_note_outlined),
              border: OutlineInputBorder(),
            ),
          ),
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

  Future<Uint8List> _capturePng({required double pixelRatio}) {
    return _exportService.capturePng(
      boundaryKey: _documentBoundaryKey,
      pixelRatio: pixelRatio,
    );
  }

  Future<Uint8List> _buildPdf() async {
    final template = _birthdayTemplateFor(widget.person);

    final pages = template.orderedPages;

    if (pages.isEmpty) {
      throw StateError('Birthday template has no pages.');
    }

    final firstPage = pages.first;

    if (firstPage.width <= 0 || firstPage.height <= 0) {
      throw StateError('Birthday template has invalid page dimensions.');
    }

    // PDF does not need the same very-high raster
    // resolution used for standalone PNG export.
    final pngBytes = await _capturePng(pixelRatio: 1.35);

    final aspectRatio = firstPage.width / firstPage.height;

    return _exportService.createPdfFromPng(
      pngBytes: pngBytes,
      aspectRatio: aspectRatio,
      title: 'Birthday Card - ${widget.person.displayName}',
    );
  }

  Future<void> _savePng() async {
    await _runExport(() async {
      final bytes = await _capturePng(pixelRatio: 1.8);

      final path = await _exportService.savePng(
        bytes: bytes,
        fileName: '${_baseFileName()}_birthday_card',
      );

      if (path != null) {
        _showSuccess('Birthday Card PNG saved successfully.');
      }
    });
  }

  Future<void> _savePdf() async {
    await _runExport(() async {
      final bytes = await _buildPdf();

      final path = await _exportService.savePdf(
        bytes: bytes,
        fileName: '${_baseFileName()}_birthday_card',
      );

      if (path != null) {
        _showSuccess('Birthday Card PDF saved successfully.');
      }
    });
  }

  Future<void> _printPdf() async {
    await _runExport(() async {
      final bytes = await _buildPdf();

      await _exportService.printPdf(
        bytes: bytes,
        name: 'Birthday Card - ${widget.person.displayName}',
      );
    });
  }

  Future<void> _sharePdf() async {
    await _runExport(() async {
      final bytes = await _buildPdf();

      await _exportService.sharePdf(
        bytes: bytes,
        fileName: '${_baseFileName()}_birthday_card.pdf',
      );
    });
  }

  Future<void> _sharePng() async {
    await _runExport(() async {
      final bytes = await _capturePng(pixelRatio: 1.8);

      await _exportService.sharePng(
        bytes: bytes,
        fileName: '${_baseFileName()}_birthday_card.png',
        text: 'Birthday Card - ${widget.person.displayName}',
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
      widget.person.displayName,
      fallback: 'birthday_card',
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

  DocumentTemplateEntity _birthdayTemplateFor(EngagementPersonEntity person) {
    if (person.isMale) {
      return buildBirthdayCardBoyV2();
    }

    // Dedicated girls template will be added after its design is approved.
    return buildBirthdayCardTemplateV1();
  }

  DocumentBrandingEntity _buildBranding(SchoolSettingsEntity settings) {
    return DocumentBrandingEntity(
      schoolName: settings.schoolName,
      schoolLogoUrl: settings.logoUrl,
      principalName: settings.principalName,
      principalDesignation: settings.principalDesignation,
      principalSignatureUrl: settings.principalSignatureUrl,
      schoolStampUrl: settings.schoolStampUrl,
    );
  }

  DocumentDataEntity _buildBirthdayData(
    EngagementPersonEntity person, {
    required String classSectionLabel,
  }) {
    final age = _calculateAge(person.dateOfBirth, DateTime.now());

    return DocumentDataEntity(
      documentType: DocumentType.birthdayCard,
      referenceId: person.id,
      referenceType: person.personType.name,
      generatedAt: DateTime.now(),
      values: {
        'student': {
          'id': person.id,
          'name': person.displayName,
          'gender': person.gender,
          'class': person.className ?? '',
          'section': person.sectionName ?? '',
          'classSection': classSectionLabel,
          'photo': person.profileImageUrl,
          'dateOfBirth': person.dateOfBirth.toIso8601String(),
        },
        'birthday': {
          'age': age,
          'message': _birthdayMessageController.text.trim().isEmpty
              ? _birthdayMessage(person)
              : _birthdayMessageController.text.trim(),
        },
      },
    );
  }

  Map<String, dynamic> _buildRenderValues({
    required DocumentBrandingEntity branding,
    required DocumentDataEntity data,
    required dynamic schoolLogo,
    required dynamic principalSignature,
  }) {
    return {
      ...data.values,
      'branding': {
        'schoolName': branding.schoolName,
        'schoolLogo': schoolLogo ?? branding.schoolLogoUrl,
        'principalName': branding.principalName,
        'principalDesignation': branding.principalDesignation,
        'principalSignature':
            principalSignature ?? branding.principalSignatureUrl,
        'schoolStamp': branding.schoolStampUrl,
      },
    };
  }

  Future<_BirthdayPreviewAssets> _loadPreviewAssets() async {
    final settings = await sl<GetSchoolSettings>()();
    final academicRepository = sl<AcademicStructureRepository>();
    final classes = await academicRepository.getClasses();
    final sections = await academicRepository.getSections();

    var className = widget.person.className?.trim() ?? '';
    var sectionName = widget.person.sectionName?.trim() ?? '';

    if (className.isEmpty) {
      for (final item in classes) {
        if (item.id == widget.person.classId ||
            item.name == widget.person.classId) {
          className = item.name;
          break;
        }
      }
    }
    if (sectionName.isEmpty) {
      for (final item in sections) {
        if (item.id == widget.person.sectionId ||
            item.name == widget.person.sectionId) {
          sectionName = item.name;
          break;
        }
      }
    }
    final classSectionLabel = [
      className,
      sectionName,
    ].where((value) => value.isNotEmpty).join(' - ');

    final images = await Future.wait<dynamic>([
      _loadStorageImage(
        settings.logoUrl,
        fallbackAsset: 'assets/images/logo.jpeg',
        fallbackStoragePaths: const [
          'school/branding/school_logo.png',
          'school/branding/school_logo.jpg',
          'school/branding/school_logo.jpeg',
        ],
      ),
      _loadStorageImage(
        settings.principalSignatureUrl,
        embeddedBase64: settings.principalSignatureData,
        fallbackStoragePaths: const [
          'school/branding/principal_signature.png',
          'school/branding/principal_signature.jpg',
          'school/branding/principal_signature.jpeg',
        ],
      ),
    ]);

    return _BirthdayPreviewAssets(
      settings: settings,
      schoolLogo: images[0],
      principalSignature: images[1],
      classSectionLabel: classSectionLabel,
    );
  }

  Future<dynamic> _loadStorageImage(
    String url, {
    String? fallbackAsset,
    String embeddedBase64 = '',
    List<String> fallbackStoragePaths = const [],
  }) async {
    if (embeddedBase64.trim().isNotEmpty) {
      try {
        return base64Decode(embeddedBase64.trim());
      } catch (_) {
        // Fall through to legacy URL loading.
      }
    }

    final source = url.trim();

    if (source.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(source));
        if (response.statusCode >= 200 &&
            response.statusCode < 300 &&
            response.bodyBytes.isNotEmpty) {
          return response.bodyBytes;
        }
      } catch (_) {
        // Try authenticated Firebase Storage loading next.
      }

      try {
        final bytes = await FirebaseStorage.instance
            .refFromURL(source)
            .getData(10 * 1024 * 1024);
        if (bytes != null && bytes.isNotEmpty) return bytes;
      } catch (_) {
        // Try stable branding storage paths below.
      }
    }

    for (final path in fallbackStoragePaths) {
      try {
        final bytes = await FirebaseStorage.instance
            .ref(path)
            .getData(10 * 1024 * 1024);
        if (bytes != null && bytes.isNotEmpty) return bytes;
      } catch (_) {
        // The uploaded file may use another supported extension.
      }
    }

    if (fallbackAsset != null) {
      final data = await rootBundle.load(fallbackAsset);
      return data.buffer.asUint8List();
    }

    return source.isEmpty ? null : source;
  }

  int _calculateAge(DateTime dateOfBirth, DateTime today) {
    var age = today.year - dateOfBirth.year;

    final birthdayHasPassed =
        today.month > dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day >= dateOfBirth.day);

    if (!birthdayHasPassed) {
      age--;
    }

    return age < 0 ? 0 : age;
  }

  String _birthdayMessage(EngagementPersonEntity person) {
    final name = person.displayName.trim();

    if (name.isEmpty) {
      return 'Wishing you a wonderful birthday filled with happiness, success and beautiful memories.';
    }

    return 'Dear $name, wishing you a wonderful birthday filled with happiness, success and beautiful memories.';
  }

  void _reload() {
    setState(() {
      _settingsFuture = _loadPreviewAssets();
    });
  }
}

class _BirthdayPreviewAssets {
  const _BirthdayPreviewAssets({
    required this.settings,
    this.schoolLogo,
    this.principalSignature,
    required this.classSectionLabel,
  });

  final SchoolSettingsEntity settings;
  final dynamic schoolLogo;
  final dynamic principalSignature;
  final String classSectionLabel;
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({required this.personName});

  final String personName;

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
                  'Birthday Card Preview',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  personName.trim().isEmpty
                      ? 'Birthday document preview'
                      : 'Birthday card for $personName',
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
              'Unable to load Birthday Card',
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
