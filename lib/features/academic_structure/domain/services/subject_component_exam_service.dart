import 'dart:convert';

import '../../../exams/domain/entities/exam_subject_setup_entity.dart';
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

    final subjectsById = {for (final subject in subjects) subject.id: subject};

    final activeComponentsByParent = <String, List<SubjectComponentEntity>>{};
    for (final component in components.where((item) => item.isActive)) {
      activeComponentsByParent
          .putIfAbsent(component.parentSubjectId, () => [])
          .add(component);
    }

    for (final values in activeComponentsByParent.values) {
      values.sort(
        (first, second) => first.displayOrder.compareTo(second.displayOrder),
      );
    }

    final output = <ExamSubjectSetupEntity>[];

    for (final setup in setups) {
      final parent = _resolveParentSubject(
        setup: setup,
        subjects: subjects,
        subjectsById: subjectsById,
        activeComponentsByParent: activeComponentsByParent,
      );

      final activeComponents = parent == null
          ? const <SubjectComponentEntity>[]
          : activeComponentsByParent[parent.id] ??
                const <SubjectComponentEntity>[];

      if (parent == null ||
          !parent.useComponentsInExamination ||
          activeComponents.isEmpty) {
        output.add(setup);
        continue;
      }

      final totalMarks = setup.totalMarks / activeComponents.length;
      final passingMarks = setup.passingMarks / activeComponents.length;

      for (final component in activeComponents) {
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
            totalMarks: totalMarks,
            passingMarks: passingMarks,
          ),
        );
      }
    }

    return List.unmodifiable(output);
  }

  dynamic _resolveParentSubject({
    required ExamSubjectSetupEntity setup,
    required List<dynamic> subjects,
    required Map<String, dynamic> subjectsById,
    required Map<String, List<SubjectComponentEntity>> activeComponentsByParent,
  }) {
    final exact = subjectsById[setup.subjectId];

    if (exact != null &&
        exact.useComponentsInExamination &&
        (activeComponentsByParent[exact.id]?.isNotEmpty ?? false)) {
      return exact;
    }

    final setupName = _normalize(setup.subjectName);

    for (final subject in subjects) {
      if (_normalize(subject.name) == setupName &&
          subject.useComponentsInExamination &&
          (activeComponentsByParent[subject.id]?.isNotEmpty ?? false)) {
        return subject;
      }
    }

    return exact;
  }

  static String _componentDisplayName(String parentName, String componentName) {
    final cleanParent = parentName.trim();
    final cleanComponent = componentName.trim();

    if (cleanParent.isEmpty) return cleanComponent;
    if (cleanComponent.isEmpty) return cleanParent;

    final normalizedParent = _normalize(cleanParent);
    final normalizedComponent = _normalize(cleanComponent);

    if (normalizedComponent == normalizedParent ||
        normalizedComponent.startsWith('$normalizedParent ')) {
      return cleanComponent;
    }

    return '$cleanParent $cleanComponent';
  }

  static String _normalize(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

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
