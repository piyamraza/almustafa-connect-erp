enum AppPermission {
  studentsView,
  studentsCreate,
  studentsEdit,
  studentsDelete,
  teachersView,
  teachersCreate,
  teachersEdit,
  teachersDelete,
  staffView,
  staffCreate,
  staffEdit,
  staffDelete,
  classesView,
  classesManage,
  attendanceView,
  attendanceMark,
  attendanceEdit,
  feesView,
  feesCollect,
  feesManage,
  feesReports,
  examsView,
  examsManage,
  dateSheetsView,
  dateSheetsManage,
  resultsView,
  resultsEnter,
  resultsPublish,
  timetableView,
  timetableManage,
  homeworkView,
  homeworkCreate,
  homeworkReview,
  noticesView,
  noticesManage,
  calendarView,
  calendarManage,
  parentsView,
  parentsManage,
  reportsView,
  reportsExport,
  settingsView,
  settingsManage,
  usersManage,
  rolesManage,
  auditLogsView,
}

extension AppPermissionX on AppPermission {
  String get module => switch (this) {
    AppPermission.studentsView ||
    AppPermission.studentsCreate ||
    AppPermission.studentsEdit ||
    AppPermission.studentsDelete => 'Students',
    AppPermission.teachersView ||
    AppPermission.teachersCreate ||
    AppPermission.teachersEdit ||
    AppPermission.teachersDelete => 'Teachers',
    AppPermission.staffView ||
    AppPermission.staffCreate ||
    AppPermission.staffEdit ||
    AppPermission.staffDelete => 'Staff',
    AppPermission.classesView || AppPermission.classesManage => 'Classes',
    AppPermission.attendanceView ||
    AppPermission.attendanceMark ||
    AppPermission.attendanceEdit => 'Attendance',
    AppPermission.feesView ||
    AppPermission.feesCollect ||
    AppPermission.feesManage ||
    AppPermission.feesReports => 'Fee Management',
    AppPermission.examsView || AppPermission.examsManage => 'Examinations',
    AppPermission.dateSheetsView ||
    AppPermission.dateSheetsManage => 'Date Sheets',
    AppPermission.resultsView ||
    AppPermission.resultsEnter ||
    AppPermission.resultsPublish => 'Results',
    AppPermission.timetableView || AppPermission.timetableManage => 'Timetable',
    AppPermission.homeworkView ||
    AppPermission.homeworkCreate ||
    AppPermission.homeworkReview => 'Homework',
    AppPermission.noticesView ||
    AppPermission.noticesManage => 'Notices & Circulars',
    AppPermission.calendarView ||
    AppPermission.calendarManage => 'Academic Calendar',
    AppPermission.parentsView || AppPermission.parentsManage => 'Parent Portal',
    AppPermission.reportsView || AppPermission.reportsExport => 'Reports',
    AppPermission.settingsView || AppPermission.settingsManage => 'Settings',
    AppPermission.usersManage => 'Users',
    AppPermission.rolesManage => 'Roles & Permissions',
    AppPermission.auditLogsView => 'Audit Logs',
  };

  String get label {
    final value = name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    );
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
