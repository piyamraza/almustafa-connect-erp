import '../../domain/entities/document_element_type.dart';
import '../../domain/entities/document_page_entity.dart';
import '../../domain/entities/document_template_entity.dart';
import 'birthday_card_template_boy_v2.dart';

/// Girls birthday card using the same dynamic branding and student layout as
/// the approved boys card. Only the artwork and school-name color differ.
DocumentTemplateEntity buildBirthdayCardTemplateV1() {
  final boysTemplate = buildBirthdayCardBoyV2();
  final boysPage = boysTemplate.pages.first;

  final girlElements = boysPage.elements
      .map((element) {
        if (element.id == 'approved_clean_artwork' &&
            element.type == DocumentElementType.image) {
          return element.copyWith(
            id: 'approved_girls_artwork',
            staticValue: 'assets/images/birthday_card_girl_pink_final.png',
          );
        }

        if (element.id == 'school_name') {
          return element.copyWith(
            style: element.style.copyWith(textColor: '#A50F5B'),
          );
        }

        return element;
      })
      .toList(growable: false);

  return boysTemplate.copyWith(
    id: 'birthday_girl_pink_final_v1',
    name: 'Birthday Girl Pink Final',
    version: 1,
    layoutKey: 'birthday_girl_pink_final',
    description:
        'Girls birthday artwork with the approved boys-card branding, student details and principal signature layout.',
    metadata: const <String, dynamic>{
      'theme': 'girl_pink_final',
      'documentPurpose': 'birthday',
      'gender': 'female',
      'backgroundAsset': 'assets/images/birthday_card_girl_pink_final.png',
    },
    pages: [
      boysPage.copyWith(
        id: 'birthday_girl_page_1',
        width: 1160,
        height: 1356,
        orientation: DocumentPageOrientation.portrait,
        backgroundColor: '#FFF0F5',
        elements: girlElements,
      ),
    ],
  );
}
