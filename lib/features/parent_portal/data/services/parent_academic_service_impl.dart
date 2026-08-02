import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../academic_structure/domain/services/academic_reference_resolver.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/parent_academic_dashboard_entity.dart';
import '../../domain/entities/parent_academic_item_entity.dart';
import '../../domain/services/parent_academic_service.dart';

class ParentAcademicServiceImpl implements ParentAcademicService {
  ParentAcademicServiceImpl(this._firestore, this._academicStructure);

  final FirebaseFirestore _firestore;
  final AcademicStructureRepository _academicStructure;
  AcademicReferenceResolver? _academicResolver;

  @override
  Future<ParentAcademicDashboardEntity> loadDashboard({
    required StudentEntity student,
    required String academicSession,
  }) async {
    _academicResolver = AcademicReferenceResolver(
      classes: await _academicStructure.getClasses(),
      sections: await _academicStructure.getSections(),
    );
    final values = await Future.wait([
      _safeCollection('attendance'),
      _safeCollection('timetable_entries'),
      _safeCollection('homework'),
      _safeCollection('homework_submissions'),
      _safeCollection('exam_date_sheets'),
      _safeResultsCollection('exam_results', student.id),
      _safeResultsCollection('results', student.id),
      _safeResultsCollection('result_sheets', student.id),
    ]);

    final attendanceDocs = values[0];
    final timetableDocs = values[1];
    final homeworkDocs = values[2];
    final submissionDocs = values[3];
    final dateSheetDocs = values[4];
    final resultDocs = [...values[5], ...values[6], ...values[7]];

    final attendanceItems = _attendanceItems(
      attendanceDocs,
      student,
      academicSession,
    );
    final timetableItems = _timetableItems(
      timetableDocs,
      student,
      academicSession,
    );
    final homeworkItems = _homeworkItems(
      homeworkDocs,
      submissionDocs,
      student,
      academicSession,
    );
    final dateSheetItems = _dateSheetItems(
      dateSheetDocs,
      student,
      academicSession,
    );
    final resultItems = _resultItems(resultDocs, student, academicSession);

    final present = attendanceItems
        .where((item) => item.status.toLowerCase() == 'present')
        .length;
    final absent = attendanceItems
        .where((item) => item.status.toLowerCase() == 'absent')
        .length;
    final late = attendanceItems
        .where((item) => item.status.toLowerCase() == 'late')
        .length;
    final leave = attendanceItems
        .where((item) => item.status.toLowerCase() == 'leave')
        .length;
    final totalAttendance = present + absent + late + leave;
    final percentage = totalAttendance == 0
        ? 0.0
        : ((present + late) / totalAttendance) * 100;

    final submittedHomework = homeworkItems
        .where((item) => item.status.toLowerCase() == 'submitted')
        .length;
    final pendingHomework = homeworkItems.length - submittedHomework;
    final upcomingExams = dateSheetItems
        .where(
          (item) =>
              item.date != null &&
              !item.date!.isBefore(_startOfDay(DateTime.now())),
        )
        .length;

    double? latestResultPercentage;
    for (final item in resultItems) {
      final value = double.tryParse(item.details['percentage'] ?? '');
      if (value != null) {
        latestResultPercentage = value;
        break;
      }
    }

    return ParentAcademicDashboardEntity(
      attendancePercentage: percentage,
      presentCount: present,
      absentCount: absent,
      lateCount: late,
      leaveCount: leave,
      pendingHomeworkCount: pendingHomework,
      submittedHomeworkCount: submittedHomework,
      upcomingExamCount: upcomingExams,
      latestResultPercentage: latestResultPercentage,
      attendanceItems: attendanceItems,
      timetableItems: timetableItems,
      homeworkItems: homeworkItems,
      dateSheetItems: dateSheetItems,
      resultItems: resultItems,
    );
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _safeCollection(
    String name,
  ) async {
    try {
      final snapshot = await _firestore.collection(name).get();
      return snapshot.docs;
    } catch (_) {
      return const [];
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _safeResultsCollection(String name, String studentId) async {
    try {
      final snapshot = await _firestore
          .collection(name)
          .where('studentId', isEqualTo: studentId)
          .where('status', whereIn: const ['published', 'locked'])
          .get();
      return snapshot.docs;
    } catch (_) {
      return const [];
    }
  }

  List<ParentAcademicItemEntity> _attendanceItems(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    StudentEntity student,
    String session,
  ) {
    final items = <ParentAcademicItemEntity>[];

    for (final doc in docs) {
      final map = doc.data();
      if (!_belongsToStudent(map, student)) continue;
      if (!_matchesSession(map, session)) continue;

      final status = _string(map, [
        'status',
        'attendanceStatus',
        'studentStatus',
      ], fallback: 'Unknown');
      final date = _date(map, ['date', 'attendanceDate', 'createdAt']);

      items.add(
        ParentAcademicItemEntity(
          id: doc.id,
          module: ParentAcademicModule.attendance,
          title: date == null
              ? 'Attendance'
              : 'Attendance - ${_formatDate(date)}',
          subtitle: status,
          date: date,
          status: status,
          details: {
            'remarks': _string(map, ['remarks', 'note', 'reason']),
          },
        ),
      );
    }

    items.sort(
      (a, b) => (b.date ?? DateTime(1970)).compareTo(a.date ?? DateTime(1970)),
    );
    return items.take(60).toList(growable: false);
  }

  List<ParentAcademicItemEntity> _timetableItems(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    StudentEntity student,
    String session,
  ) {
    final items = <ParentAcademicItemEntity>[];

    for (final doc in docs) {
      final map = doc.data();
      if (!_belongsToClass(map, student)) continue;
      if (!_matchesSession(map, session)) continue;

      final subject = _string(map, [
        'subjectName',
        'subject',
        'courseName',
      ], fallback: 'Subject');
      final teacher = _string(map, ['teacherName', 'teacher', 'staffName']);
      final day = _string(map, ['dayName', 'weekdayName', 'day']);
      final period = _string(map, ['periodName', 'period', 'slotName']);

      items.add(
        ParentAcademicItemEntity(
          id: doc.id,
          module: ParentAcademicModule.timetable,
          title: subject,
          subtitle: [
            day,
            period,
            teacher,
          ].where((value) => value.isNotEmpty).join(' • '),
          date: null,
          status: 'Scheduled',
          details: {'teacher': teacher, 'day': day, 'period': period},
        ),
      );
    }

    return items;
  }

  List<ParentAcademicItemEntity> _homeworkItems(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> homeworkDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> submissionDocs,
    StudentEntity student,
    String session,
  ) {
    final submissions = <String, Map<String, dynamic>>{};

    for (final doc in submissionDocs) {
      final map = doc.data();
      if (!_belongsToStudent(map, student)) continue;
      final homeworkId = _string(map, ['homeworkId']);
      if (homeworkId.isNotEmpty) submissions[homeworkId] = map;
    }

    final items = <ParentAcademicItemEntity>[];

    for (final doc in homeworkDocs) {
      final map = doc.data();
      if (!_belongsToClass(map, student)) continue;
      if (!_matchesSession(map, session)) continue;

      final submission = submissions[doc.id];
      final status = submission == null
          ? 'Pending'
          : _string(submission, ['status'], fallback: 'Submitted');

      final title = _string(map, [
        'title',
        'homeworkTitle',
      ], fallback: 'Homework');
      final subject = _string(map, ['subjectName', 'subject']);
      final dueDate = _date(map, ['dueDate', 'deadline']);

      items.add(
        ParentAcademicItemEntity(
          id: doc.id,
          module: ParentAcademicModule.homework,
          title: title,
          subtitle: [
            subject,
            dueDate == null ? '' : 'Due ${_formatDate(dueDate)}',
          ].where((value) => value.isNotEmpty).join(' • '),
          date: dueDate,
          status: status,
          details: {
            'description': _string(map, ['description', 'instructions']),
            'teacher': _string(map, ['teacherName', 'teacher']),
          },
        ),
      );
    }

    items.sort(
      (a, b) => (a.date ?? DateTime(2100)).compareTo(b.date ?? DateTime(2100)),
    );
    return items;
  }

  List<ParentAcademicItemEntity> _dateSheetItems(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    StudentEntity student,
    String session,
  ) {
    final items = <ParentAcademicItemEntity>[];

    for (final doc in docs) {
      final map = doc.data();
      if (!_belongsToClass(map, student)) continue;
      if (!_matchesSession(map, session)) continue;

      final papers = map['papers'];
      if (papers is List) {
        for (var index = 0; index < papers.length; index++) {
          final paper = papers[index];
          if (paper is! Map) continue;
          final normalized = Map<String, dynamic>.from(paper);
          final date = _date(normalized, ['date', 'paperDate', 'examDate']);

          items.add(
            ParentAcademicItemEntity(
              id: '${doc.id}_$index',
              module: ParentAcademicModule.dateSheet,
              title: _string(normalized, [
                'subjectName',
                'subject',
              ], fallback: 'Exam Paper'),
              subtitle: _string(normalized, ['time', 'startTime', 'paperTime']),
              date: date,
              status: 'Scheduled',
              details: {
                'room': _string(normalized, ['room', 'venue']),
              },
            ),
          );
        }
      } else {
        final date = _date(map, ['date', 'paperDate', 'examDate']);

        items.add(
          ParentAcademicItemEntity(
            id: doc.id,
            module: ParentAcademicModule.dateSheet,
            title: _string(map, [
              'subjectName',
              'subject',
              'title',
            ], fallback: 'Exam Paper'),
            subtitle: _string(map, ['time', 'startTime', 'paperTime']),
            date: date,
            status: 'Scheduled',
            details: const {},
          ),
        );
      }
    }

    items.sort(
      (a, b) => (a.date ?? DateTime(2100)).compareTo(b.date ?? DateTime(2100)),
    );
    return items;
  }

  List<ParentAcademicItemEntity> _resultItems(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    StudentEntity student,
    String session,
  ) {
    final items = <ParentAcademicItemEntity>[];

    for (final doc in docs) {
      final map = doc.data();
      if (!_belongsToStudent(map, student)) continue;
      if (!_matchesSession(map, session)) continue;
      final status = _string(map, ['status', 'resultStatus']).toLowerCase();
      if (status != 'published' && status != 'locked') continue;

      final percentage = _number(map, ['percentage', 'overallPercentage']);
      final obtained = _number(map, [
        'grandObtainedMarks',
        'obtainedMarks',
        'totalObtained',
      ]);
      final total = _number(map, [
        'grandTotalMarks',
        'totalMarks',
        'maximumMarks',
      ]);

      items.add(
        ParentAcademicItemEntity(
          id: doc.id,
          module: ParentAcademicModule.results,
          title: _string(map, [
            'examName',
            'title',
            'resultName',
          ], fallback: 'Exam Result'),
          subtitle: percentage == null
              ? 'Result Published'
              : '${percentage.toStringAsFixed(1)}%',
          date: _date(map, ['publishedAt', 'updatedAt', 'createdAt']),
          status: status == 'locked' ? 'Locked' : 'Published',
          details: {
            'percentage': percentage?.toStringAsFixed(2) ?? '',
            'marks': obtained == null || total == null
                ? ''
                : '${obtained.toStringAsFixed(0)}/${total.toStringAsFixed(0)}',
            'grade': _string(map, ['grade', 'gpa']),
          },
        ),
      );
    }

    items.sort(
      (a, b) => (b.date ?? DateTime(1970)).compareTo(a.date ?? DateTime(1970)),
    );
    return items;
  }

  bool _belongsToStudent(Map<String, dynamic> map, StudentEntity student) {
    final studentId = _string(map, ['studentId', 'studentID', 'student_id']);
    final admissionNo = _string(map, ['admissionNo', 'admissionNumber']);

    return studentId == student.id ||
        (admissionNo.isNotEmpty && admissionNo == student.admissionNo);
  }

  bool _belongsToClass(Map<String, dynamic> map, StudentEntity student) {
    if (_belongsToStudent(map, student)) return true;

    final classId = _string(map, ['classId', 'classID', 'className']);
    final sectionId = _string(map, ['sectionId', 'sectionID', 'sectionName']);

    final resolver = _academicResolver;
    final classMatches = classId.isEmpty ||
        (resolver?.sameClass(classId, student.classId) ??
            classId == student.classId);
    final sectionMatches = sectionId.isEmpty ||
        (resolver?.sameSection(sectionId, student.sectionId) ??
            sectionId == student.sectionId);

    return classMatches && sectionMatches;
  }

  bool _matchesSession(Map<String, dynamic> map, String session) {
    final value = _string(map, ['academicSession', 'session', 'academicYear']);
    return value.isEmpty || value == session;
  }

  String _string(
    Map<String, dynamic> map,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  double? _number(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  DateTime? _date(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static DateTime _startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
