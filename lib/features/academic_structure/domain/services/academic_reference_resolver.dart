import '../entities/academic_class_entity.dart';
import '../entities/section_entity.dart';

class AcademicScopeReference {
  const AcademicScopeReference({
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    required this.classAliases,
    required this.sectionAliases,
  });

  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;
  final Set<String> classAliases;
  final Set<String> sectionAliases;

  bool matchesClass(String id, [String name = '']) =>
      classAliases.contains(AcademicReferenceResolver.normalize(id)) ||
      classAliases.contains(AcademicReferenceResolver.normalize(name));

  bool matchesSection(String id, [String name = '']) =>
      sectionAliases.contains(AcademicReferenceResolver.normalize(id)) ||
      sectionAliases.contains(AcademicReferenceResolver.normalize(name));

  bool matches({
    required String classId,
    String className = '',
    required String sectionId,
    String sectionName = '',
  }) =>
      matchesClass(classId, className) &&
      matchesSection(sectionId, sectionName);
}

class AcademicReferenceResolver {
  AcademicReferenceResolver({
    required List<AcademicClassEntity> classes,
    required List<SectionEntity> sections,
  }) : _classes = List.unmodifiable(classes),
       _sections = List.unmodifiable(sections);

  final List<AcademicClassEntity> _classes;
  final List<SectionEntity> _sections;

  AcademicScopeReference resolve({
    required String classReference,
    required String sectionReference,
    String className = '',
    String sectionName = '',
  }) {
    final classTokens = {normalize(classReference), normalize(className)}
      ..remove('');
    final matchingClasses = _classes
        .where(
          (item) =>
              classTokens.contains(normalize(item.id)) ||
              classTokens.contains(normalize(item.name)),
        )
        .toList(growable: false);
    if (matchingClasses.isEmpty) {
      throw StateError(
        'Class reference mismatch: the selected class is not linked to the academic structure.',
      );
    }
    final academicClass = _preferExactClass(matchingClasses, classReference);
    final classAliases = {
      ...classTokens,
      normalize(academicClass.id),
      normalize(academicClass.name),
    };

    final sectionTokens = {normalize(sectionReference), normalize(sectionName)}
      ..remove('');
    final matchingSections = _sections
        .where(
          (item) =>
              classAliases.contains(normalize(item.classId)) &&
              (sectionTokens.contains(normalize(item.id)) ||
                  sectionTokens.contains(normalize(item.name))),
        )
        .toList(growable: false);
    if (matchingSections.isEmpty) {
      throw StateError(
        'Section reference mismatch: the selected section is not linked to the selected class.',
      );
    }
    final section = _preferExactSection(matchingSections, sectionReference);
    final sectionAliases = {
      ...sectionTokens,
      normalize(section.id),
      normalize(section.name),
    };

    return AcademicScopeReference(
      classId: academicClass.id,
      className: academicClass.name,
      sectionId: section.id,
      sectionName: section.name,
      classAliases: Set.unmodifiable(classAliases),
      sectionAliases: Set.unmodifiable(sectionAliases),
    );
  }

  AcademicClassEntity _preferExactClass(
    List<AcademicClassEntity> values,
    String reference,
  ) {
    final normalized = normalize(reference);
    return values.firstWhere(
      (item) => normalize(item.id) == normalized,
      orElse: () => values.firstWhere(
        (item) => item.isActive,
        orElse: () => values.first,
      ),
    );
  }

  SectionEntity _preferExactSection(
    List<SectionEntity> values,
    String reference,
  ) {
    final normalized = normalize(reference);
    return values.firstWhere(
      (item) => normalize(item.id) == normalized,
      orElse: () => values.firstWhere(
        (item) => item.isActive,
        orElse: () => values.first,
      ),
    );
  }

  static String normalize(String value) => value
      .trim()
      .replaceAll(RegExp(r'[\s\u200B-\u200D\uFEFF]+'), ' ')
      .toLowerCase();
}
