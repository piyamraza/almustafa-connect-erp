import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../school_engagement/domain/entities/engagement_person_entity.dart';
import '../../../settings/domain/entities/school_settings_entity.dart';
import '../../../settings/domain/usecases/manage_settings.dart';
import '../../domain/entities/document_branding_entity.dart';
import '../../domain/entities/document_data_entity.dart';
import '../../domain/entities/document_type.dart';
import '../../domain/services/default_document_placeholder_resolver.dart';
import '../../templates/birthday/birthday_card_template_v1.dart';
import '../renderer/document_element_visibility_resolver.dart';
import '../renderer/document_render_context.dart';
import '../renderer/document_renderer_registry_factory.dart';
import '../renderer/flutter_document_renderer.dart';
import '../renderer/widgets/document_canvas.dart';

const _pageBackground = Color(0xFFF5F7FA);
const _textPrimary = Color(0xFF182230);
const _textSecondary = Color(0xFF667085);

class BirthdayDocumentPreviewPage extends StatefulWidget {
  const BirthdayDocumentPreviewPage({
    super.key,
    required this.person,
  });

  final EngagementPersonEntity person;

  @override
  State<BirthdayDocumentPreviewPage> createState() =>
      _BirthdayDocumentPreviewPageState();
}

class _BirthdayDocumentPreviewPageState
    extends State<BirthdayDocumentPreviewPage> {
late Future<SchoolSettingsEntity> _settingsFuture;
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
            _PreviewHeader(
              personName: widget.person.displayName,
            ),
            Expanded(
              child: FutureBuilder<SchoolSettingsEntity>(
                future: _settingsFuture,
                builder: (
                  context,
                  snapshot,
                ) {
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

                  return _buildPreview(
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

  Widget _buildPreview(
    SchoolSettingsEntity settings,
  ) {
    final template =
        buildBirthdayCardTemplateV1();

    final branding =
        _buildBranding(settings);

    final data =
        _buildBirthdayData(
      widget.person,
    );

    final values =
        _buildRenderValues(
      branding: branding,
      data: data,
    );

    final placeholderResolver =
        const DefaultDocumentPlaceholderResolver();

    final registry =
        DocumentRendererRegistryFactory.create(
      placeholderResolver:
          placeholderResolver,
    );

    final visibilityResolver =
        DocumentElementVisibilityResolver(
      placeholderResolver,
    );

    final renderer =
        FlutterDocumentRenderer(
      registry: registry,
      visibilityResolver:
          visibilityResolver,
    );

    final renderContext =
        DocumentRenderContext(
      template: template,
      data: data,
      branding: branding,
      values: values,
    );

    final pages =
        template.orderedPages;

    if (pages.isEmpty) {
      return const _EmptyPreview();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        bottom: 32,
      ),
      child: Column(
        children: [
          for (final page in pages)
            DocumentCanvas(
              page: page,
              renderContext:
                  renderContext,
              renderer: renderer,
              maxWidth: 760,
              padding:
                  const EdgeInsets.all(24),
            ),
        ],
      ),
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

  DocumentDataEntity _buildBirthdayData(
    EngagementPersonEntity person,
  ) {
    final age = _calculateAge(
      person.dateOfBirth,
      DateTime.now(),
    );

    return DocumentDataEntity(
      documentType:
          DocumentType.birthdayCard,
      referenceId: person.id,
      referenceType:
          person.personType.name,
      generatedAt: DateTime.now(),
      values: {
        'student': {
          'id': person.id,
          'name':
              person.displayName,
          'gender':
              person.gender,
          'class':
              person.className ?? '',
          'section':
              person.sectionName ?? '',
          'classSection':
              person.classSectionLabel,
          'photo':
              person.profileImageUrl,
          'dateOfBirth':
              person.dateOfBirth
                  .toIso8601String(),
        },
        'birthday': {
          'age': age,
          'message':
              _birthdayMessage(
            person,
          ),
        },
      },
    );
  }

  Map<String, dynamic> _buildRenderValues({
    required DocumentBrandingEntity
        branding,
    required DocumentDataEntity data,
  }) {
    return {
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
  }

  int _calculateAge(
    DateTime dateOfBirth,
    DateTime today,
  ) {
    var age =
        today.year - dateOfBirth.year;

    final birthdayHasPassed =
        today.month > dateOfBirth.month ||
            (today.month ==
                    dateOfBirth.month &&
                today.day >=
                    dateOfBirth.day);

    if (!birthdayHasPassed) {
      age--;
    }

    return age < 0 ? 0 : age;
  }

  String _birthdayMessage(
    EngagementPersonEntity person,
  ) {
    final name =
        person.displayName.trim();

    if (name.isEmpty) {
      return 'Wishing you a wonderful birthday filled with happiness, success and beautiful memories.';
    }

    return 'Dear $name, wishing you a wonderful birthday filled with happiness, success and beautiful memories.';
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
    required this.personName,
  });

  final String personName;

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
            color: Color(
              0xFFE1E6ED,
            ),
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
                  'Birthday Card Preview',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  personName.trim().isEmpty
                      ? 'Birthday document preview'
                      : 'Birthday card for $personName',
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
            const Text(
              'Unable to load Birthday Card',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 17,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color:
                    _textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
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

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons.description_outlined,
            size: 48,
            color: _textSecondary,
          ),
          SizedBox(height: 12),
          Text(
            'Template has no pages.',
            style: TextStyle(
              color: _textPrimary,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}