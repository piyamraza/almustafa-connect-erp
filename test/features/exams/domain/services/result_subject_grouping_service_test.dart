import 'dart:convert';

import 'package:almustafa_connect_erp/features/exams/domain/entities/exam_result_entity.dart';
import 'package:almustafa_connect_erp/features/exams/domain/services/result_subject_grouping_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('groups components and calculates the combined result', () {
    final parentName = base64Url
        .encode(utf8.encode('English'))
        .replaceAll('=', '');
    final subjects = [
      _subject(
        id: 'cmp::english::$parentName::1::a',
        name: 'English A',
        total: 50,
        obtained: 33,
      ),
      _subject(
        id: 'cmp::english::$parentName::1::b',
        name: 'English B',
        total: 50,
        obtained: 26,
      ),
      _subject(id: 'math', name: 'Mathematics', total: 100, obtained: 80),
    ];

    final groups = ResultSubjectGroupingService.group(subjects);

    expect(groups, hasLength(2));
    expect(groups.first.subjectName, 'English');
    expect(groups.first.components.map((item) => item.label), ['A', 'B']);
    expect(groups.first.totalMarks, 100);
    expect(groups.first.obtainedMarks, 59);
    expect(groups.first.percentage, 59);
    expect(groups.first.grade, 'C');
    expect(groups.first.isPassed, isTrue);
    expect(groups.last.subjectName, 'Mathematics');
    expect(groups.last.components.single.label, 'Main paper');
  });
}

SubjectResultEntity _subject({
  required String id,
  required String name,
  required double total,
  required double obtained,
}) => SubjectResultEntity(
  subjectId: id,
  subjectName: name,
  totalMarks: total,
  obtainedMarks: obtained,
  isAbsent: false,
  isPassed: obtained >= total * 0.4,
  remarks: '',
);
