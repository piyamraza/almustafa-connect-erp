import '../../domain/entities/academic_class_entity.dart';
import '../../domain/entities/academic_subject_entity.dart';
import '../../domain/entities/section_entity.dart';
import '../../domain/repositories/academic_structure_repository.dart';
import '../../domain/services/academic_class_order.dart';
import '../datasources/academic_structure_remote_datasource.dart';
import '../models/academic_class_model.dart';
import '../models/academic_subject_model.dart';
import '../models/section_model.dart';

class AcademicStructureRepositoryImpl implements AcademicStructureRepository {
  AcademicStructureRepositoryImpl({required this._source});

  final AcademicStructureRemoteDataSource _source;

  @override
  Future<List<AcademicClassEntity>> getClasses() async {
    final classes = await _source.getClasses();
    return List<AcademicClassEntity>.of(classes)..sort(compareAcademicClasses);
  }

  @override
  Future<List<SectionEntity>> getSections() => _source.getSections();

  @override
  Future<List<AcademicSubjectEntity>> getSubjects() => _source.getSubjects();

  @override
  Future<List<AcademicSubjectEntity>> getSubjectsForClass(String classId) =>
      _source.getSubjectsForClass(classId);

  @override
  Future<List<AcademicSubjectEntity>> getSubjectsForClassSection(
    String classId,
    String sectionId,
  ) => _source.getSubjectsForClassSection(classId, sectionId);

  @override
  Future<void> saveClass(AcademicClassEntity value) =>
      _source.saveClass(AcademicClassModel.fromEntity(value));

  @override
  Future<void> saveSection(SectionEntity value) =>
      _source.saveSection(SectionModel.fromEntity(value));

  @override
  Future<void> saveSubject(AcademicSubjectEntity value) =>
      _source.saveSubject(AcademicSubjectModel.fromEntity(value));

  @override
  Future<void> deleteClass(String id) => _source.deleteClass(id);

  @override
  Future<void> deleteSection(String id) => _source.deleteSection(id);

  @override
  Future<void> deleteSubject(String id) => _source.deleteSubject(id);

  @override
  Future<int> deleteSubjectsForScope({
    required String classId,
    String? sectionId,
  }) => _source.deleteSubjectsForScope(classId: classId, sectionId: sectionId);

  @override
  Future<int> copySubjects({
    required String sourceClassId,
    required String targetClassId,
    String? sourceSectionId,
    String? targetSectionId,
  }) => _source.copySubjects(
    sourceClassId: sourceClassId,
    targetClassId: targetClassId,
    sourceSectionId: sourceSectionId,
    targetSectionId: targetSectionId,
  );

  @override
  String generateClassId() => _source.generateClassId();

  @override
  String generateSectionId() => _source.generateSectionId();

  @override
  String generateSubjectId() => _source.generateSubjectId();
}
