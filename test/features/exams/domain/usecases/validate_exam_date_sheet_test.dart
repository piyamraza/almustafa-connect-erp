import 'package:almustafa_connect_erp/features/exams/domain/entities/exam_date_sheet_entity.dart';
import 'package:almustafa_connect_erp/features/exams/domain/entities/exam_date_sheet_validation_entity.dart';
import 'package:almustafa_connect_erp/features/exams/domain/entities/exam_entity.dart';
import 'package:almustafa_connect_erp/features/exams/domain/usecases/validate_exam_date_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validator = ValidateExamDateSheet();
  final date = DateTime(2026, 8, 10);

  test('multiple papers for one teacher are allowed with a warning', () {
    final result = validator(
      exam: ExamEntity(
        id: 'exam',
        name: 'Final',
        type: ExamType.finalExam,
        academicSession: '2026-2027',
        createdAt: date,
        startDate: date,
        endDate: date,
      ),
      papers: [
        _paper('p1', 'c1', 'English', date),
        _paper('p2', 'c2', 'Urdu', date),
      ],
    );

    expect(result.isValid, isTrue);
    expect(result.errors, isEmpty);
    expect(
      result.warnings.single.type,
      ExamDateSheetIssueType.teacherDailyLimit,
    );
  });
}

ExamDateSheetPaperEntity _paper(
  String id,
  String classId,
  String subject,
  DateTime date,
) => ExamDateSheetPaperEntity(
  id: id,
  classId: classId,
  className: 'Class $classId',
  sectionId: 'a',
  sectionName: 'A',
  subjectId: subject.toLowerCase(),
  subjectName: subject,
  teacherId: 'teacher',
  teacherName: 'Teacher',
  examDate: date,
  startMinutes: 540,
  endMinutes: 660,
  totalMarks: 100,
  passingMarks: 40,
  instructions: '',
);
