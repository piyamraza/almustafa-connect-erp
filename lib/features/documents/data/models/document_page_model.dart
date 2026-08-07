import '../../domain/entities/document_element_entity.dart';
import '../../domain/entities/document_page_entity.dart';
import 'document_element_model.dart';

class DocumentPageModel {
  const DocumentPageModel();

  static Map<String, dynamic> toMap(
    DocumentPageEntity page,
  ) {
    return {
      'id': page.id,
      'width': page.width,
      'height': page.height,
      'orientation': page.orientation.name,
      'backgroundColor': page.backgroundColor,
      'backgroundImageUrl': page.backgroundImageUrl,
      'pageNumber': page.pageNumber,
      'elements': page.elements
          .map(
            DocumentElementModel.toMap,
          )
          .toList(),
    };
  }

  static DocumentPageEntity fromMap(
    Map<String, dynamic> map,
  ) {
    final rawElements = map['elements'];

    final List<DocumentElementEntity> elements =
        rawElements is Iterable
            ? rawElements
                .whereType<Map>()
                .map<DocumentElementEntity>(
                  (item) => DocumentElementModel.fromMap(
                    item.map(
                      (key, value) => MapEntry(
                        key.toString(),
                        value,
                      ),
                    ),
                  ),
                )
                .toList()
            : <DocumentElementEntity>[];

    return DocumentPageEntity(
      id: map['id'] as String? ?? '',
      width: _double(
        map['width'],
        fallback: 595,
      ),
      height: _double(
        map['height'],
        fallback: 842,
      ),
      orientation: _orientation(
        map['orientation'],
      ),
      backgroundColor:
          map['backgroundColor'] as String? ?? '#FFFFFF',
      backgroundImageUrl:
          map['backgroundImageUrl'] as String?,
      pageNumber: _int(
        map['pageNumber'],
        fallback: 1,
      ),
      elements: elements,
    );
  }

  static DocumentPageOrientation _orientation(
    dynamic raw,
  ) {
    final name = raw?.toString();

    for (final value in DocumentPageOrientation.values) {
      if (value.name == name) {
        return value;
      }
    }

    return DocumentPageOrientation.portrait;
  }

  static double _double(
    dynamic value, {
    double fallback = 0,
  }) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  static int _int(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }
}