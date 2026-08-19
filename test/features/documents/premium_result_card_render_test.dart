import 'package:almustafa_connect_erp/features/documents/domain/entities/document_branding_entity.dart';
import 'package:almustafa_connect_erp/features/documents/domain/entities/document_data_entity.dart';
import 'package:almustafa_connect_erp/features/documents/domain/entities/document_type.dart';
import 'package:almustafa_connect_erp/features/documents/domain/services/default_document_placeholder_resolver.dart';
import 'package:almustafa_connect_erp/features/documents/presentation/renderer/document_element_visibility_resolver.dart';
import 'package:almustafa_connect_erp/features/documents/presentation/renderer/document_render_context.dart';
import 'package:almustafa_connect_erp/features/documents/presentation/renderer/document_renderer_registry_factory.dart';
import 'package:almustafa_connect_erp/features/documents/presentation/renderer/flutter_document_renderer.dart';
import 'package:almustafa_connect_erp/features/documents/templates/result_card/result_card_template_v1.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('premium result card renders at A4 size without layout errors', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final template = buildResultCardTemplateV1();
    final data = DocumentDataEntity(
      documentType: DocumentType.resultCard,
      referenceId: 'result-1',
      referenceType: 'exam_result',
      generatedAt: DateTime(2026),
      values: const {},
    );
    final values = <String, dynamic>{
      'branding': {
        'schoolName': 'ALMUSTAFA MODEL SCHOOL',
        'schoolAddress': 'Vip Colony, Suraj Miani, Multan',
        'schoolContact': '0301-7545566 • school@example.com',
        'schoolLogo': '',
        'schoolStamp': '',
        'principalSignature': '',
      },
      'student': {
        'name': 'SHEHZAD',
        'fatherName': 'Mr. Muhammad Raza',
        'admissionNo': 'ADM1785498598323',
        'classSection': '1 - A',
        'rollNumber': '12',
        'dateOfBirth': '01 Jan 2017',
        'photo': '',
      },
      'result': {
        'examName': 'Final Terms',
        'academicSession': '2026-2027',
        'attendance': '92 / 96 Days',
        'status': 'PASS',
        'profileDetails': {
          'name': 'SHEHZAD',
          'fatherName': 'Mr. Muhammad Raza',
          'admissionNo': 'ADM1785498598323',
          'classSection': '1 - A',
          'rollNumber': '12',
          'attendance': '92 / 96 Days',
          'dateOfBirth': '01 Jan 2017',
          'status': 'PASS',
        },
        'scoreBadge': {'percentage': '78.0', 'grade': 'B'},
        'subjectRows': List.generate(
          6,
          (index) => {
            'subject': [
              'English',
              'Islamiat',
              'Mathematics',
              'Pak Studies',
              'Science',
              'Urdu',
            ][index],
            'components': index == 0 ? 'A: 33/50 · B: 21/50' : '—',
            'total': '100',
            'obtained': '${54 + index * 6}',
            'percentage': '${54 + index * 6}.0%',
            'grade': 'B',
            'remarks': 'Very Good',
          },
        ),
        'obtainedMarks': '468',
        'totalMarks': '600',
        'percentage': '78.00',
        'grade': 'B',
        'classPosition': '1',
        'sectionPosition': '1',
        'summaryData': {
          'obtained': '468',
          'total': '600',
          'percentage': '78.00',
          'grade': 'B',
          'classPosition': '1 / 25',
          'sectionPosition': '1 / 3',
        },
        'developmentRatings': const [
          {'label': 'Discipline', 'rating': 4},
          {'label': 'Punctuality', 'rating': 4},
          {'label': 'Communication', 'rating': 4},
          {'label': 'Class Participation', 'rating': 4},
          {'label': 'Homework', 'rating': 4},
          {'label': 'Personal Hygiene', 'rating': 5},
        ],
        'showComparison': true,
        'comparisonData': const {
          'student': '78',
          'classAverage': '68.5',
          'highest': '94.5',
        },
        'showTermProgress': true,
        'termProgressData': const [
          {'label': '1st Term', 'value': '62'},
          {'label': 'Mid Term', 'value': '71'},
          {'label': 'Final Term', 'value': '78'},
        ],
        'teacherRemarks':
            'Shehzad has shown very good overall progress and consistent effort.',
        'generalRemarks':
            '• Shows interest in learning new concepts.\n• Regular revision will lead to excellence.',
        'verificationPayload': 'AMS-RESULT:result-1',
      },
    };
    const resolver = DefaultDocumentPlaceholderResolver();
    final renderer = FlutterDocumentRenderer(
      registry: DocumentRendererRegistryFactory.create(
        placeholderResolver: resolver,
      ),
      visibilityResolver: const DocumentElementVisibilityResolver(resolver),
    );
    final context = DocumentRenderContext(
      template: template,
      data: data,
      branding: const DocumentBrandingEntity(
        schoolName: 'ALMUSTAFA MODEL SCHOOL',
        schoolLogoUrl: '',
        principalName: '',
        principalDesignation: 'Principal',
        principalSignatureUrl: '',
        schoolStampUrl: '',
      ),
      values: values,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: renderer.renderPage(
            page: template.orderedPages.single,
            renderContext: context,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ALMUSTAFA MODEL SCHOOL'), findsOneWidget);
    expect(find.text('SHEHZAD'), findsOneWidget);
    expect(find.text('ACADEMIC PERFORMANCE'), findsOneWidget);
    final exception = tester.takeException();
    if (exception case FlutterError error) {
      fail(error.toStringDeep());
    }
    expect(exception, isNull);
  });
}
