import '../../../teachers/domain/entities/teacher_entity.dart';
import '../../../teachers/domain/repositories/teacher_repository.dart';
import '../../../teachers/domain/entities/teacher_assignment_entity.dart';
import '../../../teachers/domain/repositories/teacher_assignment_repository.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../entities/class_timetable_entry_entity.dart';
import '../entities/teacher_workload_entity.dart';
import '../entities/timetable_configuration_entity.dart';
import '../repositories/timetable_repository.dart';

class GetTeacherWorkloads {
  const GetTeacherWorkloads(
    this._timetableRepository,
    this._teacherRepository,
    this._assignmentRepository,
    this._academicStructureRepository,
  );

  final TimetableRepository _timetableRepository;
  final TeacherRepository _teacherRepository;
  final TeacherAssignmentRepository _assignmentRepository;
  final AcademicStructureRepository _academicStructureRepository;

  Future<TeacherWorkloadReportEntity> call({
    required String branchId,
    required String academicSession,
  }) async {
    final cleanBranchId = branchId.trim();
    final cleanAcademicSession = academicSession.trim();

    if (cleanBranchId.isEmpty) {
      throw ArgumentError('Branch is required.');
    }
    if (cleanAcademicSession.isEmpty) {
      throw ArgumentError('Academic session is required.');
    }

    final values = await Future.wait<Object?>([
      _teacherRepository.getTeachers(),
      _timetableRepository.getConfiguration(
        branchId: cleanBranchId,
        academicSession: cleanAcademicSession,
      ),
      _timetableRepository.getAllTimetableEntries(
        branchId: cleanBranchId,
        academicSession: cleanAcademicSession,
      ),
      _assignmentRepository.getAssignments(),
      _academicStructureRepository.getClasses(),
      _academicStructureRepository.getSections(),
    ]);

    final teachers =
        (values[0] as List<TeacherEntity>)
            .where((teacher) => teacher.isActive)
            .toList()
          ..sort(
            (first, second) => first.fullName.toLowerCase().compareTo(
              second.fullName.toLowerCase(),
            ),
          );

    final configuration = values[1] as TimetableConfigurationEntity?;
    final entries = values[2] as List<ClassTimetableEntryEntity>;
    final assignments = (values[3] as List<TeacherAssignmentEntity>)
        .where(
          (assignment) =>
              _normalise(assignment.academicSession) ==
              _normalise(cleanAcademicSession),
        )
        .toList(growable: false);
    final classes = values[4] as List<AcademicClassEntity>;
    final sections = values[5] as List<SectionEntity>;
    final classNames = {for (final value in classes) value.id: value.name};
    final sectionNames = {for (final value in sections) value.id: value.name};
    final assignmentsByTeacher = <String, List<TeacherAssignmentEntity>>{};
    for (final assignment in assignments) {
      assignmentsByTeacher
          .putIfAbsent(assignment.teacherId, () => [])
          .add(assignment);
    }

    if (configuration == null) {
      return TeacherWorkloadReportEntity(
        branchId: cleanBranchId,
        academicSession: cleanAcademicSession,
        configuration: null,
        workloads: [
          for (final teacher in teachers)
            TeacherWorkloadEntity(
              teacherId: teacher.id,
              employeeId: teacher.employeeId,
              teacherName: teacher.fullName,
              designation: teacher.designation,
              assignedPeriods: 0,
              maxWeeklyPeriods: 0,
              teachingDays: 0,
              academicAssignments:
                  assignmentsByTeacher[teacher.id]?.length ?? 0,
              classSections: _assignmentClasses(
                assignmentsByTeacher[teacher.id] ?? const [],
                classNames,
                sectionNames,
              ),
              subjects: _assignmentSubjects(
                assignmentsByTeacher[teacher.id] ?? const [],
              ),
              assignedPeriodsByDay: const {},
            ),
        ],
      );
    }

    final workingDays = configuration.workingDays.toSet();
    final teachingPeriods = configuration.orderedPeriods
        .where((period) => period.isTeaching)
        .toList(growable: false);
    final teachingPeriodIds = teachingPeriods
        .map((period) => period.id)
        .toSet();
    final maxWeeklyPeriods = workingDays.length * teachingPeriods.length;

    final validEntries = entries
        .where(
          (entry) =>
              workingDays.contains(entry.weekday) &&
              teachingPeriodIds.contains(entry.periodId),
        )
        .toList(growable: false);

    final entriesByTeacher = <String, List<ClassTimetableEntryEntity>>{};
    for (final entry in validEntries) {
      entriesByTeacher.putIfAbsent(entry.teacherId, () => []).add(entry);
    }

    final workloads = <TeacherWorkloadEntity>[];

    for (final teacher in teachers) {
      final teacherEntries =
          entriesByTeacher[teacher.id] ?? const <ClassTimetableEntryEntity>[];
      final teacherAssignments =
          assignmentsByTeacher[teacher.id] ?? const <TeacherAssignmentEntity>[];

      final uniqueSlots = <String, ClassTimetableEntryEntity>{};
      for (final entry in teacherEntries) {
        uniqueSlots['${entry.weekday}|${entry.periodId}'] = entry;
      }

      final uniqueEntries = uniqueSlots.values.toList()
        ..sort((first, second) {
          final dayComparison = first.weekday.compareTo(second.weekday);
          if (dayComparison != 0) {
            return dayComparison;
          }
          return first.periodOrder.compareTo(second.periodOrder);
        });

      final assignedPeriodsByDay = <int, int>{
        for (final day in workingDays) day: 0,
      };
      final classSections = <String>{};
      final subjects = <String>{};

      classSections.addAll(
        _assignmentClasses(teacherAssignments, classNames, sectionNames),
      );
      subjects.addAll(_assignmentSubjects(teacherAssignments));

      for (final entry in uniqueEntries) {
        assignedPeriodsByDay[entry.weekday] =
            (assignedPeriodsByDay[entry.weekday] ?? 0) + 1;
        classSections.add('${entry.className} - ${entry.sectionName}');
        subjects.add(entry.subjectName);
      }

      final sortedClassSections = classSections.toList()
        ..sort((first, second) => first.compareTo(second));
      final sortedSubjects = subjects.toList()
        ..sort((first, second) => first.compareTo(second));

      workloads.add(
        TeacherWorkloadEntity(
          teacherId: teacher.id,
          employeeId: teacher.employeeId,
          teacherName: teacher.fullName,
          designation: teacher.designation,
          assignedPeriods: uniqueEntries.length,
          maxWeeklyPeriods: maxWeeklyPeriods,
          teachingDays: assignedPeriodsByDay.values
              .where((count) => count > 0)
              .length,
          academicAssignments: teacherAssignments.length,
          classSections: sortedClassSections,
          subjects: sortedSubjects,
          assignedPeriodsByDay: assignedPeriodsByDay,
        ),
      );
    }

    workloads.sort((first, second) {
      final assignedComparison = second.assignedPeriods.compareTo(
        first.assignedPeriods,
      );
      if (assignedComparison != 0) {
        return assignedComparison;
      }
      return first.teacherName.toLowerCase().compareTo(
        second.teacherName.toLowerCase(),
      );
    });

    return TeacherWorkloadReportEntity(
      branchId: cleanBranchId,
      academicSession: cleanAcademicSession,
      configuration: configuration,
      workloads: workloads,
    );
  }

  static List<String> _assignmentClasses(
    List<TeacherAssignmentEntity> assignments,
    Map<String, String> classNames,
    Map<String, String> sectionNames,
  ) {
    final values = <String>{};
    for (final assignment in assignments) {
      final className = classNames[assignment.classId] ?? assignment.classId;
      final sectionName =
          sectionNames[assignment.sectionId] ?? assignment.sectionId;
      values.add('$className - $sectionName');
    }
    return values.toList()..sort();
  }

  static List<String> _assignmentSubjects(
    List<TeacherAssignmentEntity> assignments,
  ) {
    final values = assignments.map((item) => item.subject).toSet().toList();
    return values..sort();
  }

  static String _normalise(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}
