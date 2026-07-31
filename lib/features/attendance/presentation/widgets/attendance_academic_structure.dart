import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';

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

  List<String> get classNames => classes
      .where((item) => item.isActive)
      .map((item) => item.name.trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false);

  List<String> sectionNamesForClass(String className) {
    AcademicClassEntity? selectedClass;
    for (final item in classes) {
      if (item.isActive && item.name == className) {
        selectedClass = item;
        break;
      }
    }
    if (selectedClass == null) return const [];

    final values = sections
        .where((item) => item.isActive && item.classId == selectedClass!.id)
        .map((item) => item.name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    values.sort();
    return values;
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
      ..sort((first, second) => first.name.compareTo(second.name));
    return AttendanceAcademicStructure(
      classes: sortedClasses,
      sections: sections,
    );
  }
}
