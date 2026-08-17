import 'package:almustafa_connect_erp/features/exam_seating/domain/entities/exam_seating_entities.dart';
import 'package:almustafa_connect_erp/features/exam_seating/domain/services/exam_plan_generator.dart';
import 'package:almustafa_connect_erp/features/exams/domain/entities/exam_date_sheet_entity.dart';
import 'package:almustafa_connect_erp/features/students/domain/entities/student_entity.dart';
import 'package:almustafa_connect_erp/features/teachers/domain/entities/teacher_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const generator = ExamPlanGenerator();
  final date = DateTime(2026, 8, 20);
  const rooms = [
    ExamRoomEntity(id: 'r1', name: 'Room 1', capacity: 4),
    ExamRoomEntity(id: 'r2', name: 'Room 2', capacity: 4),
  ];

  test('avoids each student previous room and keeps Paper Support off', () {
    final students = [
      _student('s1', '1', 'c1'),
      _student('s2', '2', 'c1'),
      _student('s3', '3', 'c2'),
      _student('s4', '4', 'c2'),
    ];
    final history = [
      _history(date.subtract(const Duration(days: 1)), students),
    ];
    final plan = generator.generate(
      planId: 'new',
      examId: 'exam',
      examName: 'Final',
      dateSheetId: 'sheet',
      examDate: date,
      startMinutes: 540,
      endMinutes: 720,
      sessionPapers: [_paper('c1', date), _paper('c2', date)],
      examDates: [date],
      rooms: rooms,
      students: students,
      teachers: List.generate(3, _teacher),
      history: history,
      paperSupportEnabled: false,
    );
    for (final assignment in plan.studentAssignments) {
      final previous = history.first.studentAssignments.firstWhere(
        (old) => old.studentId == assignment.studentId,
      );
      expect(assignment.roomId, isNot(previous.roomId));
    }
    expect(plan.teacherAssignments.where((item) => item.isRest), hasLength(1));
    expect(
      plan.teacherAssignments.where((item) => item.isPaperSupport),
      isEmpty,
    );
  });

  test('Paper Support is created only when enabled', () {
    final plan = generator.generate(
      planId: 'new',
      examId: 'exam',
      examName: 'Final',
      dateSheetId: 'sheet',
      examDate: date,
      startMinutes: 540,
      endMinutes: 720,
      sessionPapers: [_paper('c1', date, teacherId: 't0')],
      examDates: [date],
      rooms: rooms,
      students: [_student('s1', '1', 'c1')],
      teachers: List.generate(4, _teacher),
      history: const [],
      paperSupportEnabled: true,
    );
    expect(
      plan.teacherAssignments
          .where((item) => item.isPaperSupport)
          .single
          .teacherId,
      't0',
    );
  });

  test('rejects insufficient room capacity', () {
    expect(
      () => generator.generate(
        planId: 'new',
        examId: 'exam',
        examName: 'Final',
        dateSheetId: 'sheet',
        examDate: date,
        startMinutes: 540,
        endMinutes: 720,
        sessionPapers: [_paper('c1', date)],
        examDates: [date],
        rooms: const [ExamRoomEntity(id: 'r', name: 'Room', capacity: 1)],
        students: [_student('s1', '1', 'c1'), _student('s2', '2', 'c1')],
        teachers: List.generate(2, _teacher),
        history: const [],
        paperSupportEnabled: false,
      ),
      throwsA(isA<ExamPlanGenerationException>()),
    );
  });

  test('rotates rest teacher and student rooms by date without history', () {
    final dates = [date, date.add(const Duration(days: 1))];
    final students = [
      _student('s1', '1', 'c1'),
      _student('s2', '2', 'c1'),
      _student('s3', '3', 'c2'),
      _student('s4', '4', 'c2'),
    ];

    DailyExamPlanEntity generateFor(DateTime examDate) => generator.generate(
      planId: 'plan_${examDate.day}',
      examId: 'exam',
      examName: 'Final',
      dateSheetId: 'sheet',
      examDate: examDate,
      startMinutes: 540,
      endMinutes: 720,
      sessionPapers: [_paper('c1', examDate), _paper('c2', examDate)],
      examDates: dates,
      rooms: rooms,
      students: students,
      teachers: List.generate(4, _teacher),
      history: const [],
      paperSupportEnabled: false,
    );

    final first = generateFor(dates.first);
    final second = generateFor(dates.last);
    expect(
      first.teacherAssignments.singleWhere((item) => item.isRest).teacherId,
      isNot(
        second.teacherAssignments.singleWhere((item) => item.isRest).teacherId,
      ),
    );
    for (final assignment in first.studentAssignments) {
      final next = second.studentAssignments.firstWhere(
        (item) => item.studentId == assignment.studentId,
      );
      expect(next.roomId, isNot(assignment.roomId));
    }
  });
}

StudentEntity _student(String id, String roll, String classId) => StudentEntity(
  id: id,
  admissionNo: id,
  rollNumber: roll,
  firstName: 'Student',
  lastName: id,
  gender: 'Male',
  dateOfBirth: DateTime(2015),
  classId: classId,
  sectionId: 'a',
  fatherName: '',
  motherName: '',
  guardianPhone: '',
  guardianEmail: '',
  address: '',
  profileImageUrl: '',
  isActive: true,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
TeacherEntity _teacher(int index) => TeacherEntity(
  id: 't$index',
  employeeId: 'E$index',
  firstName: 'Teacher',
  lastName: '$index',
  gender: 'Male',
  cnic: '',
  dateOfBirth: DateTime(1990),
  phone: '',
  email: '',
  address: '',
  designation: 'Teacher',
  qualification: '',
  specialization: index == 0 ? 'English' : 'Science',
  experienceYears: 1,
  joiningDate: DateTime(2020),
  isActive: true,
  createdAt: DateTime(2020),
  updatedAt: DateTime(2020),
);
ExamDateSheetPaperEntity _paper(
  String classId,
  DateTime date, {
  String teacherId = '',
}) => ExamDateSheetPaperEntity(
  id: classId,
  classId: classId,
  className: classId,
  sectionId: 'a',
  sectionName: 'A',
  subjectId: 'sub',
  subjectName: 'Subject',
  teacherId: teacherId,
  teacherName: '',
  examDate: date,
  startMinutes: 540,
  endMinutes: 720,
  totalMarks: 100,
  passingMarks: 40,
  instructions: '',
);
DailyExamPlanEntity _history(DateTime date, List<StudentEntity> students) =>
    DailyExamPlanEntity(
      id: 'old',
      examId: 'exam',
      examName: 'Final',
      dateSheetId: 'sheet',
      examDate: date,
      startMinutes: 540,
      endMinutes: 720,
      rooms: const [
        ExamRoomEntity(id: 'r1', name: 'Room 1', capacity: 4),
        ExamRoomEntity(id: 'r2', name: 'Room 2', capacity: 4),
      ],
      studentAssignments: [
        for (var i = 0; i < students.length; i++)
          StudentSeatAssignmentEntity(
            studentId: students[i].id,
            studentName: students[i].fullName,
            rollNumber: students[i].rollNumber,
            classId: students[i].classId,
            sectionId: 'a',
            className: students[i].classId,
            roomId: i.isEven ? 'r1' : 'r2',
            roomName: i.isEven ? 'Room 1' : 'Room 2',
            seatNumber: i + 1,
          ),
      ],
      teacherAssignments: const [],
      status: ExamPlanStatus.finalized,
      paperSupportEnabled: false,
      createdAt: date,
      updatedAt: date,
    );
