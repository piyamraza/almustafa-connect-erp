import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/exam_question_entity.dart';

class QuestionPaperRepository {
  QuestionPaperRepository(this._service, this._storage);
  final FirebaseFirestoreService _service;
  final FirebaseStorage _storage;

  String newQuestionId() =>
      _service.collection(FirestorePaths.examQuestions).doc().id;
  String newPaperId() =>
      _service.collection(FirestorePaths.examQuestionPapers).doc().id;

  Future<String> uploadDiagram({
    required List<int> bytes,
    required String fileName,
  }) async {
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'png';
    // Branding uploads already use this authorised school-owned folder.
    // Keep question-paper images flat in the same scope so existing Storage
    // rules apply without exposing a new public path.
    final reference = _storage.ref(
      'school/branding/exam-diagram-${newQuestionId()}.$extension',
    );
    await reference.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: 'image/$extension'),
    );
    return reference.getDownloadURL();
  }

  Future<List<ExamQuestionEntity>> getQuestions({
    required String classId,
    required String subjectId,
    String componentId = '',
  }) async {
    final snapshot = await _service
        .collection(FirestorePaths.examQuestions)
        .where('classId', isEqualTo: classId)
        .where('subjectId', isEqualTo: subjectId)
        .get();
    final values = snapshot.docs
        .map((doc) => _question({...doc.data(), 'id': doc.id}))
        .where((question) => question.componentId == componentId)
        .toList();
    values.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return values;
  }

  Future<Map<String, SubjectPaperProgress>> getAllProgress() async {
    final snapshot = await _service
        .collection(FirestorePaths.examQuestionProgress)
        .get();
    return {
      for (final doc in snapshot.docs)
        doc.id: _progress({...doc.data(), 'id': doc.id}),
    };
  }

  Future<List<ExamQuestionPaperEntity>> getSavedPapers() async {
    final snapshot = await _service
        .collection(FirestorePaths.examQuestionPapers)
        .get();
    final papers =
        snapshot.docs
            .map((doc) => _paper({...doc.data(), 'id': doc.id}))
            .where((paper) => paper.questions.isNotEmpty)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return papers;
  }

  Future<int> copyPaperToTarget({
    required ExamQuestionPaperEntity source,
    required String classId,
    required String className,
    required String subjectId,
    required String subjectName,
    String componentId = '',
    String componentName = '',
  }) async {
    final existing = await getQuestions(
      classId: classId,
      subjectId: subjectId,
      componentId: componentId,
    );
    final copiesObjective = source.questions.any((q) => q.isObjective);
    final copiesSubjective = source.questions.any((q) => !q.isObjective);
    final batch = _service.instance.batch();
    for (final question in existing.where(
      (q) =>
          (q.isObjective && copiesObjective) ||
          (!q.isObjective && copiesSubjective),
    )) {
      batch.delete(
        _service.collection(FirestorePaths.examQuestions).doc(question.id),
      );
    }
    final now = DateTime.now();
    for (final entry in source.questions.asMap().entries) {
      final original = entry.value;
      final copy = ExamQuestionEntity(
        id: newQuestionId(),
        classId: classId,
        className: className,
        subjectId: subjectId,
        subjectName: subjectName,
        componentId: componentId,
        componentName: componentName,
        type: original.type,
        text: original.text,
        marks: original.marks,
        cells: List<String>.from(original.cells),
        chapter: original.chapter,
        imageUrl: original.imageUrl,
        answerLines: original.answerLines,
        createdAt: now.add(Duration(milliseconds: entry.key)),
      );
      batch.set(
        _service.collection(FirestorePaths.examQuestions).doc(copy.id),
        _questionMap(copy),
      );
    }
    await batch.commit();
    if (copiesObjective) {
      await setSectionStatus(
        classId: classId,
        subjectId: subjectId,
        componentId: componentId,
        objective: true,
        status: PaperSectionStatus.draft,
      );
    }
    if (copiesSubjective) {
      await setSectionStatus(
        classId: classId,
        subjectId: subjectId,
        componentId: componentId,
        objective: false,
        status: PaperSectionStatus.draft,
      );
    }
    await refreshProgress(classId, subjectId, componentId: componentId);
    return source.questions.length;
  }

  Future<void> saveQuestions(List<ExamQuestionEntity> questions) async {
    final batch = _service.instance.batch();
    for (final question in questions) {
      batch.set(
        _service.collection(FirestorePaths.examQuestions).doc(question.id),
        _questionMap(question),
      );
    }
    await batch.commit();
    if (questions.isNotEmpty) {
      await setSectionStatus(
        classId: questions.first.classId,
        subjectId: questions.first.subjectId,
        componentId: questions.first.componentId,
        objective: questions.first.isObjective,
        status: PaperSectionStatus.draft,
      );
      await refreshProgress(
        questions.first.classId,
        questions.first.subjectId,
        componentId: questions.first.componentId,
      );
    }
  }

  Future<void> deleteQuestion(ExamQuestionEntity question) async {
    await _service
        .collection(FirestorePaths.examQuestions)
        .doc(question.id)
        .delete();
    await setSectionStatus(
      classId: question.classId,
      subjectId: question.subjectId,
      componentId: question.componentId,
      objective: question.isObjective,
      status: PaperSectionStatus.draft,
    );
    await refreshProgress(
      question.classId,
      question.subjectId,
      componentId: question.componentId,
    );
  }

  Future<void> setSectionStatus({
    required String classId,
    required String subjectId,
    required bool objective,
    required PaperSectionStatus status,
    String componentId = '',
  }) async {
    final id = componentId.isEmpty
        ? '${classId}_$subjectId'
        : '${classId}_${subjectId}_$componentId';
    await _service.collection(FirestorePaths.examQuestionProgress).doc(id).set({
      'classId': classId,
      'subjectId': subjectId,
      'componentId': componentId,
      objective ? 'objectiveStatus' : 'subjectiveStatus': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> refreshProgress(
    String classId,
    String subjectId, {
    String componentId = '',
  }) async {
    final questions = await getQuestions(
      classId: classId,
      subjectId: subjectId,
      componentId: componentId,
    );
    final objective = questions.where((q) => q.isObjective).toList();
    final subjective = questions.where((q) => !q.isObjective).toList();
    final id = componentId.isEmpty
        ? '${classId}_$subjectId'
        : '${classId}_${subjectId}_$componentId';
    final ref = _service
        .collection(FirestorePaths.examQuestionProgress)
        .doc(id);
    final old = await ref.get();
    final data = old.data() ?? const <String, dynamic>{};
    await ref.set({
      'classId': classId,
      'subjectId': subjectId,
      'componentId': componentId,
      'objectiveCount': objective.length,
      'subjectiveCount': subjective.length,
      'objectiveMarks': objective.fold<double>(
        0,
        (total, q) => total + q.marks,
      ),
      'subjectiveMarks': subjective.fold<double>(
        0,
        (total, q) => total + q.marks,
      ),
      'objectiveStatus': objective.isEmpty
          ? PaperSectionStatus.pending.name
          : (data['objectiveStatus'] == PaperSectionStatus.complete.name
                ? PaperSectionStatus.complete.name
                : PaperSectionStatus.draft.name),
      'subjectiveStatus': subjective.isEmpty
          ? PaperSectionStatus.pending.name
          : (data['subjectiveStatus'] == PaperSectionStatus.complete.name
                ? PaperSectionStatus.complete.name
                : PaperSectionStatus.draft.name),
      'updatedAt': DateTime.now().toIso8601String(),
      'schemaVersion': 2,
    }, SetOptions(merge: true));
  }

  Future<void> savePaper(ExamQuestionPaperEntity paper) =>
      _service.collection(FirestorePaths.examQuestionPapers).doc(paper.id).set({
        'title': paper.title,
        'schoolName': paper.schoolName,
        'classId': paper.classId,
        'className': paper.className,
        'subjectId': paper.subjectId,
        'subjectName': paper.subjectName,
        'componentId': paper.componentId,
        'componentName': paper.componentName,
        'logoUrl': paper.logoUrl,
        'durationMinutes': paper.durationMinutes,
        'instructions': paper.instructions,
        'totalMarks': paper.totalMarks,
        'passingMarks': paper.passingMarks,
        'createdAt': paper.createdAt.toIso8601String(),
        'questions': paper.questions.map(_questionMap).toList(),
        'schemaVersion': 2,
      });

  Map<String, dynamic> _questionMap(ExamQuestionEntity q) => {
    'id': q.id,
    'classId': q.classId,
    'className': q.className,
    'subjectId': q.subjectId,
    'subjectName': q.subjectName,
    'componentId': q.componentId,
    'componentName': q.componentName,
    'type': q.type.name,
    'text': q.text,
    'marks': q.marks,
    'cells': q.cells,
    'chapter': q.chapter,
    'imageUrl': q.imageUrl,
    'answerLines': q.answerLines,
    'createdAt': q.createdAt.toIso8601String(),
    'schemaVersion': 2,
  };

  ExamQuestionEntity _question(Map<String, dynamic> map) => ExamQuestionEntity(
    id: map['id'] as String? ?? '',
    classId: map['classId'] as String? ?? '',
    className: map['className'] as String? ?? '',
    subjectId: map['subjectId'] as String? ?? '',
    subjectName: map['subjectName'] as String? ?? '',
    componentId: map['componentId'] as String? ?? '',
    componentName: map['componentName'] as String? ?? '',
    type: ExamQuestionType.values.firstWhere(
      (e) => e.name == map['type'],
      orElse: () => ExamQuestionType.shortAnswer,
    ),
    text: map['text'] as String? ?? '',
    marks: (map['marks'] as num?)?.toDouble() ?? 1,
    cells: List<String>.from(
      map['cells'] as List? ?? map['options'] as List? ?? const [],
    ),
    chapter: map['chapter'] as String? ?? '',
    imageUrl: map['imageUrl'] as String? ?? '',
    answerLines: (map['answerLines'] as num?)?.toInt() ?? 0,
    createdAt: _date(map['createdAt']),
  );

  ExamQuestionPaperEntity _paper(Map<String, dynamic> map) {
    final rawQuestions = map['questions'] as List? ?? const [];
    return ExamQuestionPaperEntity(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Question Paper',
      schoolName: map['schoolName'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      className: map['className'] as String? ?? '',
      subjectId: map['subjectId'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      componentId: map['componentId'] as String? ?? '',
      componentName: map['componentName'] as String? ?? '',
      logoUrl: map['logoUrl'] as String? ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 120,
      passingMarks: (map['passingMarks'] as num?)?.toDouble() ?? 0,
      instructions: map['instructions'] as String? ?? '',
      questions: rawQuestions
          .whereType<Map>()
          .map((value) => _question(Map<String, dynamic>.from(value)))
          .toList(),
      createdAt: _date(map['createdAt']),
    );
  }

  SubjectPaperProgress _progress(Map<String, dynamic> map) =>
      SubjectPaperProgress(
        classId: map['classId'] as String? ?? '',
        subjectId: map['subjectId'] as String? ?? '',
        componentId: map['componentId'] as String? ?? '',
        objectiveStatus: _status(map['objectiveStatus']),
        subjectiveStatus: _status(map['subjectiveStatus']),
        objectiveCount: (map['objectiveCount'] as num?)?.toInt() ?? 0,
        subjectiveCount: (map['subjectiveCount'] as num?)?.toInt() ?? 0,
        objectiveMarks: (map['objectiveMarks'] as num?)?.toDouble() ?? 0,
        subjectiveMarks: (map['subjectiveMarks'] as num?)?.toDouble() ?? 0,
      );
  PaperSectionStatus _status(dynamic value) =>
      PaperSectionStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => PaperSectionStatus.pending,
      );
  DateTime _date(dynamic value) => value is Timestamp
      ? value.toDate()
      : DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}
