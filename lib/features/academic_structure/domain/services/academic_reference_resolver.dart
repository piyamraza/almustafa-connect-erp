import '../entities/academic_class_entity.dart';
import '../entities/section_entity.dart';

/// Resolves academic references stored either as document IDs or legacy names.
class AcademicReferenceResolver {
  const AcademicReferenceResolver({
    required this.classes,
    required this.sections,
  });

  final List<AcademicClassEntity> classes;
  final List<SectionEntity> sections;

  String className(String reference) {
    for (final item in classes) {
      if (_same(item.id, reference) || _same(item.name, reference)) {
        return item.name.trim();
      }
    }
    return reference.trim();
  }

  String sectionName(String reference) {
    for (final item in sections) {
      if (_same(item.id, reference) || _same(item.name, reference)) {
        return item.name.trim();
      }
    }
    return reference.trim();
  }

  bool sameClass(String first, String second) {
    if (_same(first, second)) return true;
    return _same(className(first), className(second));
  }

  bool sameSection(String first, String second) {
    if (_same(first, second)) return true;
    return _same(sectionName(first), sectionName(second));
  }

  static String normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static bool _same(String first, String second) =>
      normalize(first) == normalize(second);
}
