import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../academic_structure/domain/services/academic_class_order.dart';

/// Read-only class and section data used by attendance screens.
///
/// The Classes module remains the source of truth. Student and attendance
/// records retain the selected class/section names as their historical values.
class AttendanceAcademicStructure {
  const AttendanceAcademicStructure({
    required this.classes,
    required this.sections,
  });

  final List<AcademicClassEntity> classes;
  final List<SectionEntity> sections;

  List<AcademicClassEntity> get activeClasses => classes
      .where((item) => item.isActive && item.name.trim().isNotEmpty)
      .toList(growable: false);

  List<String> get classNames => activeClasses
      .map((item) => item.name.trim())
      .toList(growable: false);

  List<SectionEntity> sectionsForClass(String classId) {
    final values = sections
        .where((item) => item.isActive && item.classId == classId)
        .toList();
    values.sort((first, second) => first.name.compareTo(second.name));
    return values;
  }

  List<String> sectionNamesForClass(String className) {
    for (final item in activeClasses) {
      if (item.name == className || item.id == className) {
        return sectionsForClass(item.id)
            .map((section) => section.name.trim())
            .where((name) => name.isNotEmpty)
            .toList(growable: false);
      }
    }
    return const [];
  }

  String className(String reference) {
    for (final item in classes) {
      if (item.id == reference || item.name == reference) return item.name;
    }
    return reference;
  }

  String sectionName(String reference) {
    for (final item in sections) {
      if (item.id == reference || item.name == reference) return item.name;
    }
    return reference;
  }

  static Future<AttendanceAcademicStructure> load(
    AcademicStructureRepository repository,
  ) async {
    final values = await Future.wait([
      repository.getClasses(),
      repository.getSections(),
    ]);
    final classes = values[0] as List<AcademicClassEntity>;
    final sections = values[1] as List<SectionEntity>;
    final sortedClasses = [...classes]
      ..sort(compareAcademicClasses);
    return AttendanceAcademicStructure(
      classes: sortedClasses,
      sections: sections,
    );
  }
}
