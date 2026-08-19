import '../../domain/entities/document_element_type.dart';
import '../../domain/services/document_placeholder_resolver.dart';
import 'document_element_value_resolver.dart';
import 'document_renderer_registry.dart';
import 'renderers/image_renderer.dart';
import 'renderers/principal_signature_renderer.dart';
import 'renderers/school_logo_renderer.dart';
import 'renderers/school_stamp_renderer.dart';
import 'renderers/shape_renderer.dart';
import 'renderers/student_photo_renderer.dart';
import 'renderers/text_renderer.dart';
import 'renderers/qr_code_renderer.dart';
import 'renderers/result_subjects_table_renderer.dart';
import 'renderers/result_card_premium_renderers.dart';

class DocumentRendererRegistryFactory {
  const DocumentRendererRegistryFactory._();

  static DocumentRendererRegistry create({
    required DocumentPlaceholderResolver placeholderResolver,
  }) {
    final valueResolver = DocumentElementValueResolver(placeholderResolver);

    final registry = DocumentRendererRegistry();

    final imageRenderer = ImageRenderer(valueResolver);

    registry.registerAll({
      DocumentElementType.text: TextRenderer(valueResolver),

      DocumentElementType.shape: const ShapeRenderer(),

      DocumentElementType.image: imageRenderer,

      DocumentElementType.dynamicImage: imageRenderer,

      DocumentElementType.schoolLogo: SchoolLogoRenderer(valueResolver),

      DocumentElementType.personPhoto: StudentPhotoRenderer(valueResolver),

      DocumentElementType.principalSignature: PrincipalSignatureRenderer(
        valueResolver,
      ),

      DocumentElementType.schoolStamp: SchoolStampRenderer(valueResolver),

      DocumentElementType.background: imageRenderer,
      DocumentElementType.qrCode: QrCodeRenderer(valueResolver),
      DocumentElementType.resultSubjectsTable: ResultSubjectsTableRenderer(
        valueResolver,
      ),
      DocumentElementType.resultScoreBadge: ResultScoreBadgeRenderer(
        valueResolver,
      ),
      DocumentElementType.developmentRatings: DevelopmentRatingsRenderer(
        valueResolver,
      ),
      DocumentElementType.performanceChart: PerformanceChartRenderer(
        valueResolver,
      ),
      DocumentElementType.termProgressChart: TermProgressChartRenderer(
        valueResolver,
      ),
      DocumentElementType.resultProfileDetails: ResultProfileDetailsRenderer(
        valueResolver,
      ),
      DocumentElementType.resultSummaryStrip: ResultSummaryStripRenderer(
        valueResolver,
      ),
      DocumentElementType.resultRemarksPanel: ResultRemarksPanelRenderer(
        valueResolver,
      ),
      DocumentElementType.schoolMottoBadge: const SchoolMottoBadgeRenderer(),
    });

    return registry;
  }
}
