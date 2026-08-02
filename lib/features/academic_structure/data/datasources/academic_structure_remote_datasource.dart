import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../models/academic_class_model.dart';
import '../models/academic_subject_model.dart';
import '../models/section_model.dart';
import '../models/subject_component_model.dart';

abstract class AcademicStructureRemoteDataSource {
  Future<List<AcademicClassModel>> getClasses();
  Future<List<SectionModel>> getSections();
  Future<List<AcademicSubjectModel>> getSubjects();
  Future<List<AcademicSubjectModel>> getSubjectsForClass(String classId);
  Future<List<AcademicSubjectModel>> getSubjectsForClassSection(
    String classId,
    String sectionId,
  );
  Future<void> saveClass(AcademicClassModel value);
  Future<void> saveSection(SectionModel value);
  Future<void> saveSubject(AcademicSubjectModel value);
  Future<void> deleteClass(String id);
  Future<void> deleteSection(String id);
  Future<void> deleteSubject(String id);
  Future<int> deleteSubjectsForScope({
    required String classId,
    String? sectionId,
  });
  Future<int> copySubjects({
    required String sourceClassId,
    required String targetClassId,
    String? sourceSectionId,
    String? targetSectionId,
  });
  String generateClassId();
  String generateSectionId();
  String generateSubjectId();
}

class AcademicStructureRemoteDataSourceImpl
    implements AcademicStructureRemoteDataSource {
  AcademicStructureRemoteDataSourceImpl({
    required FirebaseFirestoreService firestoreService,
  }) : _service = firestoreService;

  final FirebaseFirestoreService _service;

  @override
  Future<List<AcademicClassModel>> getClasses() async {
    final data = await _service
        .collection(FirestorePaths.classes)
        .orderBy('name')
        .get();
    return data.docs
        .map((doc) => AcademicClassModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList(growable: false);
  }

  @override
  Future<List<SectionModel>> getSections() async {
    final data = await _service
        .collection(FirestorePaths.sections)
        .orderBy('name')
        .get();
    return data.docs
        .map((doc) => SectionModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList(growable: false);
  }

  @override
  Future<List<AcademicSubjectModel>> getSubjects() async {
    final data = await _service
        .collection(FirestorePaths.academicSubjects)
        .orderBy('name')
        .get();
    return data.docs
        .map(
          (doc) => AcademicSubjectModel.fromMap({...doc.data(), 'id': doc.id}),
        )
        .toList(growable: false);
  }

  @override
  Future<List<AcademicSubjectModel>> getSubjectsForClass(String classId) async {
    final subjects = await _subjectsForClass(classId);
    return subjects
        .where((value) => value.sectionId == null)
        .toList(growable: false);
  }

  @override
  Future<List<AcademicSubjectModel>> getSubjectsForClassSection(
    String classId,
    String sectionId,
  ) async {
    final subjects = await _subjectsForClass(classId);
    return subjects
        .where((value) => value.sectionId == sectionId)
        .toList(growable: false);
  }

  Future<List<AcademicSubjectModel>> _subjectsForClass(String classId) async {
    final data = await _service
        .collection(FirestorePaths.academicSubjects)
        .where('classId', isEqualTo: classId)
        .get();
    final subjects = data.docs
        .map(
          (doc) => AcademicSubjectModel.fromMap({...doc.data(), 'id': doc.id}),
        )
        .toList();
    subjects.sort((first, second) => first.name.compareTo(second.name));
    return subjects;
  }

  @override
  Future<void> saveClass(AcademicClassModel value) async {
    final existing = await _service
        .collection(FirestorePaths.classes)
        .where('nameKey', isEqualTo: value.name.trim().toLowerCase())
        .limit(1)
        .get();
    if (existing.docs.any((doc) => doc.id != value.id)) {
      throw StateError('A class with this name already exists.');
    }
    await _service
        .collection(FirestorePaths.classes)
        .doc(value.id)
        .set(value.toMap());
  }

  @override
  Future<void> saveSection(SectionModel value) async {
    final existing = await _service
        .collection(FirestorePaths.sections)
        .where('classSectionKey', isEqualTo: value.classSectionKey)
        .limit(1)
        .get();
    if (existing.docs.any((doc) => doc.id != value.id)) {
      throw StateError('This section already exists for the selected class.');
    }
    await _service
        .collection(FirestorePaths.sections)
        .doc(value.id)
        .set(value.toMap());
  }

  @override
  Future<void> saveSubject(AcademicSubjectModel value) async {
    final existing = await _subjectsForClass(value.classId);
    final duplicate = existing.any(
      (subject) =>
          subject.id != value.id &&
          subject.sectionId == value.sectionId &&
          subject.name.trim().toLowerCase() == value.name.trim().toLowerCase(),
    );
    if (duplicate) {
      throw StateError(
        value.sectionId == null
            ? 'This class already has a subject with this name.'
            : 'This section already has a subject with this name.',
      );
    }
    await _service
        .collection(FirestorePaths.academicSubjects)
        .doc(value.id)
        .set(value.toMap());
  }

  @override
  Future<void> deleteClass(String id) async {
    final students = await _service
        .collection(FirestorePaths.students)
        .where('classId', isEqualTo: id)
        .limit(1)
        .get();
    final sections = await _service
        .collection(FirestorePaths.sections)
        .where('classId', isEqualTo: id)
        .limit(1)
        .get();
    final subjects = await _service
        .collection(FirestorePaths.academicSubjects)
        .where('classId', isEqualTo: id)
        .limit(1)
        .get();
    if (students.docs.isNotEmpty ||
        sections.docs.isNotEmpty ||
        subjects.docs.isNotEmpty) {
      throw StateError('This class is in use and cannot be deleted.');
    }
    await _service.collection(FirestorePaths.classes).doc(id).delete();
  }

  @override
  Future<void> deleteSection(String id) async {
    final subjects = await _service
        .collection(FirestorePaths.academicSubjects)
        .where('sectionId', isEqualTo: id)
        .limit(1)
        .get();
    if (subjects.docs.isNotEmpty) {
      throw StateError(
        'This section has subject overrides. Delete them from Subjects first.',
      );
    }
    await _service.collection(FirestorePaths.sections).doc(id).delete();
  }

  @override
  Future<void> deleteSubject(String id) async {
    await _service.collection(FirestorePaths.academicSubjects).doc(id).delete();
  }

  @override
  Future<int> deleteSubjectsForScope({
    required String classId,
    String? sectionId,
  }) async {
    final subjects = sectionId == null
        ? await getSubjectsForClass(classId)
        : await getSubjectsForClassSection(classId, sectionId);
    if (subjects.isEmpty) return 0;

    final subjectIds = subjects.map((item) => item.id).toSet();
    final componentCollection = _service.collection(
      FirestorePaths.subjectComponents,
    );
    final componentSnapshot = await componentCollection.get();
    final componentIds = componentSnapshot.docs
        .where(
          (document) => subjectIds.contains(
            document.data()['parentSubjectId'] as String?,
          ),
        )
        .map((document) => document.id)
        .toList(growable: false);

    final subjectCollection = _service.collection(
      FirestorePaths.academicSubjects,
    );
    final deletions = <({String id, bool component})>[
      for (final id in componentIds) (id: id, component: true),
      for (final id in subjectIds) (id: id, component: false),
    ];
    for (var start = 0; start < deletions.length; start += 500) {
      final end = start + 500 > deletions.length
          ? deletions.length
          : start + 500;
      final batch = _service.instance.batch();
      for (final deletion in deletions.sublist(start, end)) {
        batch.delete(
          deletion.component
              ? componentCollection.doc(deletion.id)
              : subjectCollection.doc(deletion.id),
        );
      }
      await batch.commit();
    }
    return subjects.length;
  }

  @override
  Future<int> copySubjects({
    required String sourceClassId,
    required String targetClassId,
    String? sourceSectionId,
    String? targetSectionId,
  }) async {
    if (sourceClassId == targetClassId && sourceSectionId == targetSectionId) {
      throw StateError('Choose a different source subject list.');
    }

    final source = sourceSectionId == null
        ? await getSubjectsForClass(sourceClassId)
        : await getSubjectsForClassSection(sourceClassId, sourceSectionId);
    final target = targetSectionId == null
        ? await getSubjectsForClass(targetClassId)
        : await getSubjectsForClassSection(targetClassId, targetSectionId);
    final targetByName = {
      for (final value in target) value.name.trim().toLowerCase(): value,
    };
    final now = DateTime.now();
    final subjectCopies = <AcademicSubjectModel>[];
    final targetForSource = <String, AcademicSubjectModel>{};
    for (final value in source) {
      final nameKey = value.name.trim().toLowerCase();
      final existing = targetByName[nameKey];
      if (existing != null) {
        targetForSource[value.id] = existing;
        continue;
      }
      final copy = AcademicSubjectModel(
        id: generateSubjectId(),
        classId: targetClassId,
        sectionId: targetSectionId,
        name: value.name,
        isActive: value.isActive,
        createdAt: now,
        updatedAt: now,
        useComponentsInTimetable: value.useComponentsInTimetable,
        useComponentsInAttendance: value.useComponentsInAttendance,
        useComponentsInHomework: value.useComponentsInHomework,
        useComponentsInExamination: value.useComponentsInExamination,
        useComponentsInReportCard: value.useComponentsInReportCard,
      );
      subjectCopies.add(copy);
      targetByName[nameKey] = copy;
      targetForSource[value.id] = copy;
    }

    final componentCollection = _service.collection(
      FirestorePaths.subjectComponents,
    );
    final componentSnapshot = await componentCollection.get();
    final allComponents = componentSnapshot.docs
        .map(SubjectComponentModel.fromFirestore)
        .toList(growable: false);
    final componentsByParent = <String, List<SubjectComponentModel>>{};
    for (final component in allComponents) {
      componentsByParent
          .putIfAbsent(component.parentSubjectId, () => [])
          .add(component);
    }

    final componentCopies = <SubjectComponentModel>[];
    for (final sourceSubject in source) {
      final targetSubject = targetForSource[sourceSubject.id]!;
      final existingComponentNames =
          (componentsByParent[targetSubject.id] ??
                  const <SubjectComponentModel>[])
              .map((item) => item.componentName.trim().toLowerCase())
              .toSet();
      for (final component
          in componentsByParent[sourceSubject.id] ??
              const <SubjectComponentModel>[]) {
        if (!existingComponentNames.add(
          component.componentName.trim().toLowerCase(),
        )) {
          continue;
        }
        componentCopies.add(
          SubjectComponentModel(
            id: componentCollection.doc().id,
            parentSubjectId: targetSubject.id,
            parentSubjectName: targetSubject.name,
            componentName: component.componentName,
            displayOrder: component.displayOrder,
            isActive: component.isActive,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    }

    var batch = _service.instance.batch();
    var writeCount = 0;
    Future<void> flush() async {
      if (writeCount == 0) return;
      await batch.commit();
      batch = _service.instance.batch();
      writeCount = 0;
    }

    for (final value in subjectCopies) {
      batch.set(
        _service.collection(FirestorePaths.academicSubjects).doc(value.id),
        value.toMap(),
      );
      writeCount++;
      if (writeCount == 500) await flush();
    }
    for (final component in componentCopies) {
      batch.set(componentCollection.doc(component.id), component.toFirestore());
      writeCount++;
      if (writeCount == 500) await flush();
    }
    await flush();
    return subjectCopies.length;
  }

  @override
  String generateClassId() =>
      _service.collection(FirestorePaths.classes).doc().id;

  @override
  String generateSectionId() =>
      _service.collection(FirestorePaths.sections).doc().id;

  @override
  String generateSubjectId() =>
      _service.collection(FirestorePaths.academicSubjects).doc().id;
}
