import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/appreciation_certificate_entity.dart';
import '../../domain/repositories/appreciation_certificate_repository.dart';

class AppreciationCertificateRepositoryImpl
    implements AppreciationCertificateRepository {
  const AppreciationCertificateRepositoryImpl(this._service);
  final FirebaseFirestoreService _service;
  @override
  Future<List<AppreciationCertificateEntity>> getCertificates() async {
    final snap = await _service
        .collection(FirestorePaths.appreciationCertificates)
        .get();
    final values = snap.docs.map((d) => _fromMap(d.id, d.data())).toList()
      ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
    return List.unmodifiable(values);
  }

  @override
  Future<void> saveCertificate(AppreciationCertificateEntity value) => _service
      .collection(FirestorePaths.appreciationCertificates)
      .doc(value.id)
      .set(_toMap(value));
  @override
  String newId() =>
      _service.collection(FirestorePaths.appreciationCertificates).doc().id;
  DateTime _date(Object? value) => value is Timestamp
      ? value.toDate()
      : value is DateTime
      ? value
      : DateTime.tryParse('$value') ?? DateTime.now();
  T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
      values.where((e) => e.name == name).firstOrNull ?? fallback;
  AppreciationCertificateEntity _fromMap(String id, Map<String, dynamic> m) =>
      AppreciationCertificateEntity(
        id: id,
        serialNumber: '${m['serialNumber'] ?? ''}',
        studentId: '${m['studentId'] ?? ''}',
        studentName: '${m['studentName'] ?? ''}',
        admissionNumber: '${m['admissionNumber'] ?? ''}',
        rollNumber: '${m['rollNumber'] ?? ''}',
        className: '${m['className'] ?? ''}',
        sectionName: '${m['sectionName'] ?? ''}',
        category: _enum(
          AppreciationCategory.values,
          m['category'],
          AppreciationCategory.specialAchievement,
        ),
        categoryLabel: '${m['categoryLabel'] ?? ''}',
        title: '${m['title'] ?? 'Certificate of Appreciation'}',
        description: '${m['description'] ?? ''}',
        achievementDate: _date(m['achievementDate']),
        issueDate: _date(m['issueDate']),
        teacherName: '${m['teacherName'] ?? ''}',
        principalName: '${m['principalName'] ?? ''}',
        theme: _enum(
          AppreciationTheme.values,
          m['theme'],
          AppreciationTheme.blueGold,
        ),
        issuedAt: _date(m['issuedAt']),
      );
  Map<String, dynamic> _toMap(AppreciationCertificateEntity v) => {
    'serialNumber': v.serialNumber,
    'studentId': v.studentId,
    'studentName': v.studentName,
    'admissionNumber': v.admissionNumber,
    'rollNumber': v.rollNumber,
    'className': v.className,
    'sectionName': v.sectionName,
    'category': v.category.name,
    'categoryLabel': v.categoryLabel,
    'title': v.title,
    'description': v.description,
    'achievementDate': v.achievementDate,
    'issueDate': v.issueDate,
    'teacherName': v.teacherName,
    'principalName': v.principalName,
    'theme': v.theme.name,
    'issuedAt': v.issuedAt,
    'schemaVersion': 1,
  };
}
