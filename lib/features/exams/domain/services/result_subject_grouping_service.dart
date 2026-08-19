import '../../../academic_structure/domain/services/subject_component_exam_service.dart';
import '../entities/exam_result_entity.dart';

class GroupedSubjectResult {
  const GroupedSubjectResult({
    required this.subjectId,
    required this.subjectName,
    required this.components,
    required this.totalMarks,
    required this.obtainedMarks,
    required this.isAbsent,
    required this.isPassed,
    required this.remarks,
  });

  final String subjectId;
  final String subjectName;
  final List<GroupedSubjectComponent> components;
  final double totalMarks;
  final double obtainedMarks;
  final bool isAbsent;
  final bool isPassed;
  final String remarks;

  double get percentage =>
      totalMarks <= 0 ? 0 : (obtainedMarks / totalMarks) * 100;

  String get grade {
    final value = percentage;
    if (value >= 80) return 'A+';
    if (value >= 70) return 'A';
    if (value >= 60) return 'B';
    if (value >= 50) return 'C';
    if (value >= 40) return 'D';
    return 'F';
  }

  SubjectResultEntity get combined => SubjectResultEntity(
    subjectId: subjectId,
    subjectName: subjectName,
    totalMarks: totalMarks,
    obtainedMarks: obtainedMarks,
    isAbsent: isAbsent,
    isPassed: isPassed,
    remarks: remarks,
  );
}

class GroupedSubjectComponent {
  const GroupedSubjectComponent({
    required this.label,
    required this.totalMarks,
    required this.obtainedMarks,
    required this.isAbsent,
  });

  final String label;
  final double totalMarks;
  final double obtainedMarks;
  final bool isAbsent;
}

class ResultSubjectGroupingService {
  const ResultSubjectGroupingService._();

  static List<GroupedSubjectResult> group(List<SubjectResultEntity> subjects) {
    final groupedComponents = <String, List<SubjectResultEntity>>{};
    final orderedKeys = <String>[];

    for (final subject in subjects) {
      final parentId = SubjectComponentExamService.parentId(subject.subjectId);
      final nameParent = parentId == null
          ? _parentFromLegacyName(subject.subjectName)
          : null;
      final key = parentId == null && nameParent == null
          ? 'subject::${subject.subjectId}'
          : parentId == null
          ? 'legacy::${nameParent!.toLowerCase()}'
          : 'parent::$parentId';
      if (!groupedComponents.containsKey(key)) orderedKeys.add(key);
      (groupedComponents[key] ??= []).add(subject);
    }

    return List.unmodifiable(
      orderedKeys.map((key) => _buildGroup(groupedComponents[key]!)),
    );
  }

  static GroupedSubjectResult _buildGroup(List<SubjectResultEntity> items) {
    final first = items.first;
    final parentName = SubjectComponentExamService.parentName(first.subjectId);
    final legacyParent = items.length > 1
        ? _parentFromLegacyName(first.subjectName)
        : null;
    final subjectName = parentName?.trim().isNotEmpty == true
        ? parentName!.trim()
        : legacyParent ?? first.subjectName.trim();
    final totalMarks = items.fold<double>(
      0,
      (sum, item) => sum + item.totalMarks,
    );
    final obtainedMarks = items.fold<double>(
      0,
      (sum, item) => sum + item.obtainedMarks,
    );
    final remarks = items
        .where((item) => item.remarks.trim().isNotEmpty)
        .map((item) {
          final label = _componentLabel(item.subjectName, subjectName);
          return items.length == 1
              ? item.remarks.trim()
              : '$label: ${item.remarks.trim()}';
        })
        .join(' · ');

    return GroupedSubjectResult(
      subjectId: parentName == null
          ? first.subjectId
          : SubjectComponentExamService.parentId(first.subjectId)!,
      subjectName: subjectName,
      components: List.unmodifiable(
        items.map(
          (item) => GroupedSubjectComponent(
            label: items.length == 1
                ? 'Main paper'
                : _componentLabel(item.subjectName, subjectName),
            totalMarks: item.totalMarks,
            obtainedMarks: item.obtainedMarks,
            isAbsent: item.isAbsent,
          ),
        ),
      ),
      totalMarks: totalMarks,
      obtainedMarks: obtainedMarks,
      isAbsent: items.every((item) => item.isAbsent),
      isPassed: items.every((item) => item.isPassed),
      remarks: remarks,
    );
  }

  static String _componentLabel(String value, String parentName) {
    final name = value.trim();
    final parent = parentName.trim();
    if (parent.isNotEmpty &&
        name.toLowerCase().startsWith(parent.toLowerCase())) {
      final remainder = name.substring(parent.length).trim();
      if (remainder.isNotEmpty) return remainder;
    }
    return name.isEmpty ? 'Component' : name;
  }

  static String? _parentFromLegacyName(String value) {
    final match = RegExp(
      r'^(.+?)\s+(?:paper\s*)?([a-z]|part\s*[a-z]|i{1,3}|[1-3])$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    final parent = match?.group(1)?.trim();
    return parent == null || parent.isEmpty ? null : parent;
  }
}
