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
  const AcademicReferenceResolver({
    required this.classes,
    required this.sections,
  });

  final List<AcademicClassEntity> classes;
  final List<SectionEntity> sections;

  String className(String reference) {
    final token = normalize(reference);
    for (final item in classes) {
      if (normalize(item.id) == token || normalize(item.name) == token) {
        return item.name;
      }
    }
    return reference;
  }

  String sectionName(String reference) {
    final token = normalize(reference);
    for (final item in sections) {
      if (normalize(item.id) == token || normalize(item.name) == token) {
        return item.name;
      }
    }
    return reference;
  }

  bool sameClass(String first, String second) {
    final firstId = _classIdentity(first);
    final secondId = _classIdentity(second);
    return firstId.isNotEmpty && firstId == secondId;
  }

  bool sameSection(String first, String second) {
    final firstId = _sectionIdentity(first);
    final secondId = _sectionIdentity(second);
    return firstId.isNotEmpty && firstId == secondId;
  }

  String _classIdentity(String reference) {
    final token = normalize(reference);
    for (final item in classes) {
      if (normalize(item.id) == token || normalize(item.name) == token) {
        return normalize(item.id);
      }
    }
    return token;
  }

  String _sectionIdentity(String reference) {
    final token = normalize(reference);
    for (final item in sections) {
      if (normalize(item.id) == token || normalize(item.name) == token) {
        return normalize(item.id);
      }
    }
    return token;
  }

  AcademicScopeReference resolve({
    required String classReference,
    required String sectionReference,
    String className = '',
    String sectionName = '',
  }) {
    final classTokens = {normalize(classReference), normalize(className)}
      ..remove('');
    final matchingClasses = <AcademicClassEntity>[];
    for (final item in classes) {
      if (classTokens.contains(normalize(item.id)) ||
          classTokens.contains(normalize(item.name))) {
        matchingClasses.add(item);
      }
    }
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
    final matchingSections = <SectionEntity>[];
    for (final item in sections) {
      if (classAliases.contains(normalize(item.classId)) &&
          (sectionTokens.contains(normalize(item.id)) ||
              sectionTokens.contains(normalize(item.name)))) {
        matchingSections.add(item);
      }
    }
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
      .replaceAll(RegExp(r'[\s\u200B-\u200D\uFEFF]+'), ' ')
      .trim()
      .toLowerCase();
}
