import 'dart:convert';

import '../../../exams/domain/entities/exam_subject_setup_entity.dart';
import '../entities/academic_subject_entity.dart';
import '../entities/subject_component_entity.dart';
import '../repositories/academic_structure_repository.dart';
import '../repositories/subject_component_repository.dart';

class SubjectComponentExamService {
  const SubjectComponentExamService(
    this._academicRepository,
    this._componentRepository,
  );

  final AcademicStructureRepository _academicRepository;
  final SubjectComponentRepository _componentRepository;

  Future<List<ExamSubjectSetupEntity>> expandSetups(
    List<ExamSubjectSetupEntity> setups,
  ) async {
    final subjects = await _academicRepository.getSubjects();
    final components = await _componentRepository.getComponents();
    final subjectsById = {for (final item in subjects) item.id: item};
    final output = <ExamSubjectSetupEntity>[];

    for (final setup in setups) {
      final parent = _resolveParent(setup, subjects, subjectsById, components);

      final active = parent == null
          ? const <SubjectComponentEntity>[]
          : (components
                .where(
                  (item) => item.parentSubjectId == parent.id && item.isActive,
                )
                .toList()
              ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder)));

      if (parent == null ||
          !parent.useComponentsInExamination ||
          active.isEmpty) {
        output.add(setup);
        continue;
      }

      final useManualTotals = setup.componentTotalMarks.isNotEmpty;
      final useComponentPassing = setup.componentPassingMarks.isNotEmpty;

      for (final component in active) {
        final total = useManualTotals
            ? setup.componentTotalMarks[component.id]
            : setup.totalMarks / active.length;
        final passing = useComponentPassing
            ? setup.componentPassingMarks[component.id]
            : setup.passingMarks;

        if (total == null || total <= 0 || passing == null) {
          throw StateError(
            'Component marks are incomplete for '
            '${setup.subjectName} (${setup.className}-${setup.sectionName}).',
          );
        }

        final encodedParent = base64Url
            .encode(utf8.encode(parent.name))
            .replaceAll('=', '');
        final reportFlag = parent.useComponentsInReportCard ? '1' : '0';

        output.add(
          setup.copyWith(
            id: '${setup.id}::${component.id}',
            subjectId:
                'cmp::${parent.id}::$encodedParent::$reportFlag::${component.id}',
            subjectName: _componentDisplayName(
              parent.name,
              component.componentName,
            ),
            totalMarks: total,
            passingMarks: passing,
            componentTotalMarks: const {},
            componentPassingMarks: useComponentPassing
                ? {component.id: passing}
                : const {},
          ),
        );
      }
    }

    return List.unmodifiable(output);
  }

  AcademicSubjectEntity? _resolveParent(
    ExamSubjectSetupEntity setup,
    List<AcademicSubjectEntity> subjects,
    Map<String, AcademicSubjectEntity> subjectsById,
    List<SubjectComponentEntity> components,
  ) {
    final exact = subjectsById[setup.subjectId];
    if (exact != null &&
        exact.useComponentsInExamination &&
        components.any(
          (item) => item.parentSubjectId == exact.id && item.isActive,
        )) {
      return exact;
    }

    final name = _normalize(setup.subjectName);
    for (final subject in subjects) {
      if (_normalize(subject.name) == name &&
          subject.useComponentsInExamination &&
          components.any(
            (item) => item.parentSubjectId == subject.id && item.isActive,
          )) {
        return subject;
      }
    }
    return exact;
  }

  static String _componentDisplayName(String parentName, String componentName) {
    final parent = parentName.trim();
    final component = componentName.trim();
    if (parent.isEmpty) return component;
    if (component.isEmpty) return parent;

    final normalizedParent = _normalize(parent);
    final normalizedComponent = _normalize(component);
    if (normalizedComponent == normalizedParent ||
        normalizedComponent.startsWith('$normalizedParent ')) {
      return component;
    }
    return '$parent $component';
  }

  static String _normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static bool isComponentId(String value) =>
      value.startsWith('cmp::') && value.split('::').length == 5;

  static String? parentId(String value) =>
      isComponentId(value) ? value.split('::')[1] : null;

  static String? parentName(String value) {
    if (!isComponentId(value)) return null;
    try {
      final raw = value.split('::')[2];
      return utf8.decode(base64Url.decode(base64Url.normalize(raw)));
    } catch (_) {
      return null;
    }
  }

  static bool useInReportCard(String value) =>
      isComponentId(value) && value.split('::')[3] == '1';
}
