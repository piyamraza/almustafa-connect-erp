import '../../../exams/domain/entities/exam_date_sheet_entity.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../teachers/domain/entities/teacher_entity.dart';
import '../entities/exam_seating_entities.dart';

class ExamPlanGenerationException implements Exception {
  const ExamPlanGenerationException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ExamPlanGenerator {
  const ExamPlanGenerator();

  DailyExamPlanEntity generate({
    required String planId,
    required String examId,
    required String examName,
    required String dateSheetId,
    required DateTime examDate,
    required int startMinutes,
    required int endMinutes,
    required List<ExamDateSheetPaperEntity> sessionPapers,
    required List<DateTime> examDates,
    required List<ExamRoomEntity> rooms,
    required List<StudentEntity> students,
    required List<TeacherEntity> teachers,
    required List<DailyExamPlanEntity> history,
    required bool paperSupportEnabled,
  }) {
    if (rooms.isEmpty)
      throw const ExamPlanGenerationException('Add at least one exam room.');
    if (rooms.any((room) => room.capacity <= 0))
      throw const ExamPlanGenerationException(
        'Every room must have a valid capacity.',
      );
    if (sessionPapers.isEmpty)
      throw const ExamPlanGenerationException(
        'No papers were found for the selected date and session.',
      );
    if (students.isEmpty)
      throw const ExamPlanGenerationException(
        'No active students were found for the selected classes.',
      );
    final capacity = rooms.fold<int>(0, (sum, room) => sum + room.capacity);
    if (capacity < students.length) {
      throw ExamPlanGenerationException(
        '${students.length} students require ${students.length - capacity} more seats.',
      );
    }

    final activeTeachers =
        teachers.where((teacher) => teacher.isActive).toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));
    final requiredTeachers = rooms.length + 1 + (paperSupportEnabled ? 1 : 0);
    if (activeTeachers.length < requiredTeachers) {
      throw ExamPlanGenerationException(
        'At least $requiredTeachers active teachers are required for ${rooms.length} rooms, daily rest${paperSupportEnabled ? ' and Paper Support' : ''}.',
      );
    }

    final now = DateTime.now();
    final studentAssignments = _seatStudents(
      rooms: rooms,
      students: students,
      papers: sessionPapers,
      examDate: examDate,
      examDates: examDates,
      history: history,
    );
    final teacherAssignments = _assignTeachers(
      rooms: rooms,
      teachers: activeTeachers,
      papers: sessionPapers,
      examDate: examDate,
      examDates: examDates,
      history: history,
      paperSupportEnabled: paperSupportEnabled,
    );
    return DailyExamPlanEntity(
      id: planId,
      examId: examId,
      examName: examName,
      dateSheetId: dateSheetId,
      examDate: examDate,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      rooms: List.unmodifiable(rooms),
      studentAssignments: studentAssignments,
      teacherAssignments: teacherAssignments,
      status: ExamPlanStatus.draft,
      paperSupportEnabled: paperSupportEnabled,
      createdAt: now,
      updatedAt: now,
    );
  }

  List<StudentSeatAssignmentEntity> _seatStudents({
    required List<ExamRoomEntity> rooms,
    required List<StudentEntity> students,
    required List<ExamDateSheetPaperEntity> papers,
    required DateTime examDate,
    required List<DateTime> examDates,
    required List<DailyExamPlanEntity> history,
  }) {
    final labels = <String, String>{
      for (final paper in papers)
        '${paper.classId}|${paper.sectionId}':
            '${paper.className} ${paper.sectionName}'.trim(),
    };
    final groups = <String, List<StudentEntity>>{};
    for (final student in students.where((value) => value.isActive)) {
      groups
          .putIfAbsent('${student.classId}|${student.sectionId}', () => [])
          .add(student);
    }
    for (final group in groups.values) {
      group.sort((a, b) => _rollCompare(a.rollNumber, b.rollNumber));
    }

    final queue = <StudentEntity>[];
    while (groups.values.any((group) => group.isNotEmpty)) {
      final keys = groups.keys.toList()
        ..sort((a, b) => groups[b]!.length.compareTo(groups[a]!.length));
      for (final key in keys) {
        if (groups[key]!.isNotEmpty) queue.add(groups[key]!.removeAt(0));
      }
    }

    final previous = <String, StudentSeatAssignmentEntity>{};
    final latestFirst = history.toList()
      ..sort((a, b) => b.examDate.compareTo(a.examDate));
    for (final plan in latestFirst) {
      for (final assignment in plan.studentAssignments)
        previous.putIfAbsent(assignment.studentId, () => assignment);
    }
    final occupied = {for (final room in rooms) room.id: 0};
    final classCounts = {for (final room in rooms) room.id: <String, int>{}};
    final roomRotation = _rotationIndex(
      examDate: examDate,
      examDates: examDates,
      itemCount: rooms.length,
    );
    final roomRanks = <String, int>{
      for (var index = 0; index < rooms.length; index++)
        rooms[index].id: (index - roomRotation) % rooms.length,
    };
    final result = <StudentSeatAssignmentEntity>[];
    for (final student in queue) {
      final classKey = '${student.classId}|${student.sectionId}';
      final candidates = rooms
          .where((room) => occupied[room.id]! < room.capacity)
          .toList();
      candidates.sort((a, b) {
        int score(ExamRoomEntity room) {
          final repeatedRoom = previous[student.id]?.roomId == room.id
              ? 10000
              : 0;
          final sameClass = (classCounts[room.id]![classKey] ?? 0) * 100;
          final fillRatio = (occupied[room.id]! * 1000) ~/ room.capacity;
          return repeatedRoom + sameClass + fillRatio;
        }

        final compared = score(a).compareTo(score(b));
        if (compared != 0) return compared;
        final rotationCompared = roomRanks[a.id]!.compareTo(roomRanks[b.id]!);
        return rotationCompared != 0
            ? rotationCompared
            : a.name.compareTo(b.name);
      });
      final room = candidates.first;
      occupied[room.id] = occupied[room.id]! + 1;
      classCounts[room.id]![classKey] =
          (classCounts[room.id]![classKey] ?? 0) + 1;
      result.add(
        StudentSeatAssignmentEntity(
          studentId: student.id,
          studentName: student.fullName,
          fatherName: student.fatherName,
          rollNumber: student.rollNumber,
          classId: student.classId,
          sectionId: student.sectionId,
          className: labels[classKey] ?? classKey,
          roomId: room.id,
          roomName: room.name,
          seatNumber: occupied[room.id]!,
        ),
      );
    }
    return List.unmodifiable(result);
  }

  List<TeacherDutyAssignmentEntity> _assignTeachers({
    required List<ExamRoomEntity> rooms,
    required List<TeacherEntity> teachers,
    required List<ExamDateSheetPaperEntity> papers,
    required DateTime examDate,
    required List<DateTime> examDates,
    required List<DailyExamPlanEntity> history,
    required bool paperSupportEnabled,
  }) {
    final dutyCounts = <String, int>{};
    final restCounts = <String, int>{};
    for (final plan in history) {
      for (final assignment in plan.teacherAssignments) {
        final target = assignment.isRest ? restCounts : dutyCounts;
        target[assignment.teacherId] = (target[assignment.teacherId] ?? 0) + 1;
      }
    }
    final normalizedDates = examDates.map(_day).toSet().toList()..sort();
    final dayIndex = normalizedDates.indexOf(_day(examDate));
    final isLastPapers =
        dayIndex >= 0 && dayIndex >= normalizedDates.length - 2;
    bool languageTeacher(TeacherEntity teacher) {
      final value = '${teacher.specialization} ${teacher.designation}'
          .toLowerCase();
      return value.contains('english') || value.contains('urdu');
    }

    final available = teachers.toList();
    TeacherEntity? support;
    if (paperSupportEnabled) {
      final paperTeacherIds = papers
          .map((paper) => paper.teacherId)
          .where((id) => id.isNotEmpty)
          .toSet();
      final matches = available
          .where((teacher) => paperTeacherIds.contains(teacher.id))
          .toList();
      support = matches.isNotEmpty
          ? matches.first
          : (available..sort(
                  (a, b) =>
                      (dutyCounts[a.id] ?? 0).compareTo(dutyCounts[b.id] ?? 0),
                ))
                .first;
      available.removeWhere((teacher) => teacher.id == support!.id);
    }

    final restRotation = _rotationIndex(
      examDate: examDate,
      examDates: examDates,
      itemCount: available.length,
    );
    final restRanks = <String, int>{
      for (var index = 0; index < available.length; index++)
        available[index].id: (index - restRotation) % available.length,
    };
    available.sort((a, b) {
      int score(TeacherEntity teacher) =>
          (restCounts[teacher.id] ?? 0) * 1000 +
          (!isLastPapers && languageTeacher(teacher) ? 500 : 0) -
          (dutyCounts[teacher.id] ?? 0);
      final compared = score(a).compareTo(score(b));
      if (compared != 0) return compared;
      final rotationCompared = restRanks[a.id]!.compareTo(restRanks[b.id]!);
      return rotationCompared != 0
          ? rotationCompared
          : a.fullName.compareTo(b.fullName);
    });
    final rest = available.removeAt(0);
    available.sort((a, b) {
      final compared = (dutyCounts[a.id] ?? 0).compareTo(dutyCounts[b.id] ?? 0);
      return compared != 0 ? compared : a.fullName.compareTo(b.fullName);
    });

    final result = <TeacherDutyAssignmentEntity>[
      TeacherDutyAssignmentEntity(
        teacherId: rest.id,
        teacherName: rest.fullName,
        role: 'rest',
      ),
      if (support != null)
        TeacherDutyAssignmentEntity(
          teacherId: support.id,
          teacherName: support.fullName,
          role: 'paperSupport',
        ),
    ];
    final largerRoomsFirst = rooms.toList()
      ..sort((a, b) => b.capacity.compareTo(a.capacity));
    var roomIndex = 0;
    for (final teacher in available) {
      final room = roomIndex < rooms.length
          ? rooms[roomIndex]
          : largerRoomsFirst[(roomIndex - rooms.length) % rooms.length];
      result.add(
        TeacherDutyAssignmentEntity(
          teacherId: teacher.id,
          teacherName: teacher.fullName,
          role: 'invigilator',
          roomId: room.id,
          roomName: room.name,
        ),
      );
      roomIndex++;
    }
    return List.unmodifiable(result);
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static int _rotationIndex({
    required DateTime examDate,
    required List<DateTime> examDates,
    required int itemCount,
  }) {
    if (itemCount <= 1) return 0;
    final normalizedDates = examDates.map(_day).toSet().toList()..sort();
    final dayIndex = normalizedDates.indexOf(_day(examDate));
    if (dayIndex >= 0) return dayIndex % itemCount;
    return _day(examDate).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay %
        itemCount;
  }

  static int _rollCompare(String a, String b) {
    final left = int.tryParse(a), right = int.tryParse(b);
    return left != null && right != null
        ? left.compareTo(right)
        : a.compareTo(b);
  }
}
