import '../entities/teacher_attendance_entity.dart';
abstract class TeacherAttendanceRepository { Future<List<TeacherAttendanceEntity>> getByDate(DateTime date); Future<List<TeacherAttendanceEntity>> getByTeacher(String teacherId, DateTime fromDate, DateTime toDate); Future<void> save(TeacherAttendanceEntity record); }
