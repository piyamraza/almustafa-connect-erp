import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../entities/engagement_person_entity.dart';

class SearchBirthdayPeople {
  const SearchBirthdayPeople({required this._studentRepository});

  final StudentRepository _studentRepository;

  Future<List<EngagementPersonEntity>> call(String keyword) async {
    final normalizedKeyword = keyword.trim();

    if (normalizedKeyword.isEmpty) {
      return const [];
    }

    final students = await _studentRepository.searchStudents(normalizedKeyword);

    return students
        .where((student) => student.isActive)
        .map(_mapStudent)
        .toList();
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
