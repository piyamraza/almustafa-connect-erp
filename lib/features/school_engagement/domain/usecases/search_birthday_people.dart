import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../entities/engagement_person_entity.dart';

class SearchBirthdayPeople {
  const SearchBirthdayPeople({
    required StudentRepository
        studentRepository,
    required AcademicStructureRepository
        academicStructureRepository,
  })  : _studentRepository =
            studentRepository,
        _academicStructureRepository =
            academicStructureRepository;

  final StudentRepository
      _studentRepository;

  final AcademicStructureRepository
      _academicStructureRepository;

  Future<List<EngagementPersonEntity>>
      call(String keyword) async {
    final normalizedKeyword =
        keyword.trim();

    if (normalizedKeyword.isEmpty) {
      return const [];
    }

    final results = await Future.wait([
      _studentRepository.searchStudents(
        normalizedKeyword,
      ),
      _academicStructureRepository
          .getClasses(),
      _academicStructureRepository
          .getSections(),
    ]);

    final students =
        results[0] as List<StudentEntity>;

    final classes =
        results[1] as dynamic;

    final sections =
        results[2] as dynamic;

    final classNames =
        <String, String>{};

    for (final item in classes) {
      classNames[item.id as String] =
          item.name as String;
    }

    final sectionNames =
        <String, String>{};

    for (final item in sections) {
      sectionNames[item.id as String] =
          item.name as String;
    }

    return students
        .where(
          (student) =>
              student.isActive,
        )
        .map(
          (student) => _mapStudent(
            student,
            classNames,
            sectionNames,
          ),
        )
        .toList();
  }

  EngagementPersonEntity _mapStudent(
    StudentEntity student,
    Map<String, String> classNames,
    Map<String, String> sectionNames,
  ) {
    return EngagementPersonEntity(
      id: student.id,
      personType:
          EngagementPersonType.student,
      displayName:
          student.fullName.trim(),
      gender: student.gender,
      dateOfBirth:
          student.dateOfBirth,
      profileImageUrl:
          student.profileImageUrl,

      fatherName:
          student.fatherName.trim(),

      classId:
          student.classId,
      sectionId:
          student.sectionId,

      className:
          classNames[student.classId] ??
              '',

      sectionName:
          sectionNames[
                  student.sectionId] ??
              '',

      isActive:
          student.isActive,

      sourceReference:
          'students/${student.id}',
    );
  }
}