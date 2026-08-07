import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../entities/engagement_person_entity.dart';
import '../services/birthday_resolver_service.dart';

class GetTodayBirthdays {
  const GetTodayBirthdays({
    required this._studentRepository,
    required this._birthdayResolver,
  });

  final StudentRepository _studentRepository;
  final BirthdayResolverService _birthdayResolver;

  Future<List<EngagementPersonEntity>> call({DateTime? now}) async {
    final students = await _studentRepository.getStudents();

    final people = students.map(_mapStudent).toList();

    return _birthdayResolver.birthdaysToday(people, now: now);
  }

  EngagementPersonEntity _mapStudent(StudentEntity student) {
    return EngagementPersonEntity(
      id: student.id,
      personType: EngagementPersonType.student,
      displayName: student.fullName.trim(),
      gender: student.gender,
      dateOfBirth: student.dateOfBirth,
      profileImageUrl: student.profileImageUrl,
      classId: student.classId,
      sectionId: student.sectionId,
      isActive: student.isActive,
      sourceReference: 'students/${student.id}',
    );
  }
}
