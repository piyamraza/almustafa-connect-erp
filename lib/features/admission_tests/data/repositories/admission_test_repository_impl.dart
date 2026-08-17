import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/admission_test_entities.dart';
import '../../domain/repositories/admission_test_repository.dart';

class AdmissionTestRepositoryImpl implements AdmissionTestRepository {
  const AdmissionTestRepositoryImpl(this._service);
  final FirebaseFirestoreService _service;

  @override
  Future<List<AdmissionQuestionEntity>> getQuestions() async {
    final snap = await _service
        .collection(FirestorePaths.admissionTestQuestions)
        .get();
    final values = snap.docs.map((d) => _question(d.id, d.data())).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(values);
  }

  @override
  Future<void> saveQuestion(AdmissionQuestionEntity value) => _service
      .collection(FirestorePaths.admissionTestQuestions)
      .doc(value.id)
      .set(_questionMap(value));
  @override
  Future<void> deleteQuestion(String id) => _service
      .collection(FirestorePaths.admissionTestQuestions)
      .doc(id)
      .delete();
  @override
  Future<List<AdmissionPaperTemplateEntity>> getTemplates() async {
    final snap = await _service
        .collection(FirestorePaths.admissionTestTemplates)
        .get();
    return List.unmodifiable(
      snap.docs.map((d) => _template(d.id, d.data())).toList()
        ..sort((a, b) => a.classLevel.compareTo(b.classLevel)),
    );
  }

  @override
  Future<void> saveTemplate(AdmissionPaperTemplateEntity value) => _service
      .collection(FirestorePaths.admissionTestTemplates)
      .doc(value.id)
      .set(_templateMap(value));
  @override
  Future<List<AdmissionPaperEntity>> getPapers() async {
    final snap = await _service
        .collection(FirestorePaths.admissionTestPapers)
        .get();
    return List.unmodifiable(
      snap.docs.map((d) => _paper(d.id, d.data())).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  @override
  Future<void> savePaper(AdmissionPaperEntity value) => _service
      .collection(FirestorePaths.admissionTestPapers)
      .doc(value.id)
      .set(_paperMap(value));
  @override
  Future<List<AdmissionCandidateEntity>> getCandidates() async {
    final snap = await _service
        .collection(FirestorePaths.admissionTestCandidates)
        .get();
    return List.unmodifiable(
      snap.docs.map((d) => _candidate(d.id, d.data())).toList()
        ..sort((a, b) => b.testDate.compareTo(a.testDate)),
    );
  }

  @override
  Future<void> saveCandidate(AdmissionCandidateEntity value) => _service
      .collection(FirestorePaths.admissionTestCandidates)
      .doc(value.id)
      .set(_candidateMap(value));
  @override
  String newId(String collection) => _service.collection(collection).doc().id;

  DateTime _date(Object? value) => value is Timestamp
      ? value.toDate()
      : value is DateTime
      ? value
      : DateTime.tryParse('$value') ?? DateTime.now();
  T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
      values.where((e) => e.name == name).firstOrNull ?? fallback;
  AdmissionQuestionEntity _question(String id, Map<String, dynamic> m) =>
      AdmissionQuestionEntity(
        id: id,
        classLevel: '${m['classLevel'] ?? ''}',
        subject: '${m['subject'] ?? ''}',
        type: _enum(
          AdmissionQuestionType.values,
          m['type'],
          AdmissionQuestionType.shortAnswer,
        ),
        difficulty: _enum(
          AdmissionQuestionDifficulty.values,
          m['difficulty'],
          AdmissionQuestionDifficulty.medium,
        ),
        prompt: '${m['prompt'] ?? ''}',
        marks: (m['marks'] as num?)?.toDouble() ?? 1,
        correctAnswer: '${m['correctAnswer'] ?? ''}',
        options: List<String>.from(m['options'] as List? ?? const []),
        createdAt: _date(m['createdAt']),
        isDefault: m['isDefault'] == true,
      );
  Map<String, dynamic> _questionMap(AdmissionQuestionEntity q) => {
    'classLevel': q.classLevel,
    'subject': q.subject,
    'type': q.type.name,
    'difficulty': q.difficulty.name,
    'prompt': q.prompt,
    'marks': q.marks,
    'correctAnswer': q.correctAnswer,
    'options': q.options,
    'createdAt': q.createdAt,
    'isDefault': q.isDefault,
    'schemaVersion': 1,
  };
  AdmissionPaperTemplateEntity _template(String id, Map<String, dynamic> m) =>
      AdmissionPaperTemplateEntity(
        id: id,
        classLevel: '${m['classLevel'] ?? ''}',
        mode: _enum(
          AdmissionAssessmentMode.values,
          m['mode'],
          AdmissionAssessmentMode.written,
        ),
        durationMinutes: (m['durationMinutes'] as num?)?.toInt() ?? 60,
        passingPercentage: (m['passingPercentage'] as num?)?.toDouble() ?? 50,
        sections: (m['sections'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (e) => AdmissionTemplateSection(
                subject: '${e['subject'] ?? ''}',
                questionCount: (e['questionCount'] as num?)?.toInt() ?? 0,
              ),
            )
            .toList(),
        easyPercent: (m['easyPercent'] as num?)?.toInt() ?? 40,
        mediumPercent: (m['mediumPercent'] as num?)?.toInt() ?? 40,
        difficultPercent: (m['difficultPercent'] as num?)?.toInt() ?? 20,
        updatedAt: _date(m['updatedAt']),
      );
  Map<String, dynamic> _templateMap(AdmissionPaperTemplateEntity t) => {
    'classLevel': t.classLevel,
    'mode': t.mode.name,
    'durationMinutes': t.durationMinutes,
    'passingPercentage': t.passingPercentage,
    'sections': t.sections
        .map((s) => {'subject': s.subject, 'questionCount': s.questionCount})
        .toList(),
    'easyPercent': t.easyPercent,
    'mediumPercent': t.mediumPercent,
    'difficultPercent': t.difficultPercent,
    'updatedAt': t.updatedAt,
    'schemaVersion': 1,
  };
  AdmissionPaperEntity _paper(String id, Map<String, dynamic> m) =>
      AdmissionPaperEntity(
        id: id,
        title: '${m['title'] ?? ''}',
        classLevel: '${m['classLevel'] ?? ''}',
        variant: '${m['variant'] ?? 'A'}',
        mode: _enum(
          AdmissionAssessmentMode.values,
          m['mode'],
          AdmissionAssessmentMode.written,
        ),
        durationMinutes: (m['durationMinutes'] as num?)?.toInt() ?? 60,
        passingPercentage: (m['passingPercentage'] as num?)?.toDouble() ?? 50,
        questions: (m['questions'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (e) =>
                  _question('${e['id'] ?? ''}', Map<String, dynamic>.from(e)),
            )
            .toList(),
        createdAt: _date(m['createdAt']),
      );
  Map<String, dynamic> _paperMap(AdmissionPaperEntity p) => {
    'title': p.title,
    'classLevel': p.classLevel,
    'variant': p.variant,
    'mode': p.mode.name,
    'durationMinutes': p.durationMinutes,
    'passingPercentage': p.passingPercentage,
    'questions': p.questions
        .map((q) => {'id': q.id, ..._questionMap(q)})
        .toList(),
    'createdAt': p.createdAt,
    'schemaVersion': 1,
  };
  AdmissionCandidateEntity _candidate(String id, Map<String, dynamic> m) =>
      AdmissionCandidateEntity(
        id: id,
        applicantNumber: '${m['applicantNumber'] ?? ''}',
        studentName: '${m['studentName'] ?? ''}',
        guardianName: '${m['guardianName'] ?? ''}',
        guardianPhone: '${m['guardianPhone'] ?? ''}',
        applyingClass: '${m['applyingClass'] ?? ''}',
        testDate: _date(m['testDate']),
        paperId: '${m['paperId'] ?? ''}',
        paperTitle: '${m['paperTitle'] ?? ''}',
        obtainedMarks: (m['obtainedMarks'] as num?)?.toDouble() ?? 0,
        totalMarks: (m['totalMarks'] as num?)?.toDouble() ?? 0,
        observations: Map<String, String>.from(
          m['observations'] as Map? ?? const {},
        ),
        recommendation: _enum(
          AdmissionRecommendation.values,
          m['recommendation'],
          AdmissionRecommendation.pending,
        ),
        remarks: '${m['remarks'] ?? ''}',
        updatedAt: _date(m['updatedAt']),
      );
  Map<String, dynamic> _candidateMap(AdmissionCandidateEntity c) => {
    'applicantNumber': c.applicantNumber,
    'studentName': c.studentName,
    'guardianName': c.guardianName,
    'guardianPhone': c.guardianPhone,
    'applyingClass': c.applyingClass,
    'testDate': c.testDate,
    'paperId': c.paperId,
    'paperTitle': c.paperTitle,
    'obtainedMarks': c.obtainedMarks,
    'totalMarks': c.totalMarks,
    'observations': c.observations,
    'recommendation': c.recommendation.name,
    'remarks': c.remarks,
    'updatedAt': c.updatedAt,
    'schemaVersion': 1,
  };
}
