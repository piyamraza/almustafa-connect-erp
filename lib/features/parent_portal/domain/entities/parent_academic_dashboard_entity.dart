import 'package:equatable/equatable.dart';

import 'parent_academic_item_entity.dart';

class ParentAcademicDashboardEntity extends Equatable {
  const ParentAcademicDashboardEntity({
    required this.attendancePercentage,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.leaveCount,
    required this.pendingHomeworkCount,
    required this.submittedHomeworkCount,
    required this.upcomingExamCount,
    required this.latestResultPercentage,
    required this.attendanceItems,
    required this.timetableItems,
    required this.homeworkItems,
    required this.dateSheetItems,
    required this.resultItems,
  });

  final double attendancePercentage;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int leaveCount;
  final int pendingHomeworkCount;
  final int submittedHomeworkCount;
  final int upcomingExamCount;
  final double? latestResultPercentage;
  final List<ParentAcademicItemEntity> attendanceItems;
  final List<ParentAcademicItemEntity> timetableItems;
  final List<ParentAcademicItemEntity> homeworkItems;
  final List<ParentAcademicItemEntity> dateSheetItems;
  final List<ParentAcademicItemEntity> resultItems;

  @override
  List<Object?> get props => [
    attendancePercentage,
    presentCount,
    absentCount,
    lateCount,
    leaveCount,
    pendingHomeworkCount,
    submittedHomeworkCount,
    upcomingExamCount,
    latestResultPercentage,
    attendanceItems,
    timetableItems,
    homeworkItems,
    dateSheetItems,
    resultItems,
  ];
}
