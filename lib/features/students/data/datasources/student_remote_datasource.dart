import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../models/student_model.dart';

abstract class StudentRemoteDataSource {

  String generateStudentId();
  Future<List<StudentModel>> getStudents();

  Future<List<StudentModel>> getStudentsByClassAndSection({
    required String classId,
    required String sectionId,
  });

  Future<StudentModel?> getStudentById(String id);

  Future<void> addStudent(StudentModel student);

  Future<void> updateStudent(StudentModel student);

  Future<void> deleteStudent(String id);

  Future<List<StudentModel>> searchStudents(String keyword);

  Future<String> uploadStudentPhoto(
    String studentId,
    Uint8List imageBytes,
  );
}

class StudentRemoteDataSourceImpl
    implements StudentRemoteDataSource {
  StudentRemoteDataSourceImpl({
    required FirebaseFirestoreService firestoreService,
  }) : _firestoreService = firestoreService;

  final FirebaseFirestoreService _firestoreService;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestoreService.collection(FirestorePaths.students);

@override
Future<void> addStudent(StudentModel student) async {
  print('STEP 1: addStudent() called');

  await _collection.doc(student.id).set(student.toMap());

  print('STEP 2: Firestore write completed');
}

  String generateStudentId() {
    return _collection.doc().id;
  }

  @override
  Future<void> deleteStudent(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Future<StudentModel?> getStudentById(String id) async {
    final doc = await _collection.doc(id).get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    data['id'] = doc.id;

    return StudentModel.fromMap(data);
  }

  @override
  Future<List<StudentModel>> getStudents() async {
    final snapshot = await _collection
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return StudentModel.fromMap(data);
    }).toList();
  }

  @override
  Future<List<StudentModel>> getStudentsByClassAndSection({
    required String classId,
    required String sectionId,
  }) async {
    final snapshot = await _collection
        .where('classId', isEqualTo: classId)
        .where('sectionId', isEqualTo: sectionId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return StudentModel.fromMap(data);
    }).toList(growable: false);
  }

  @override
  Future<List<StudentModel>> searchStudents(
    String keyword,
  ) async {
    final students = await getStudents();

    return students.where((student) {
      final name =
          "${student.firstName} ${student.lastName}".toLowerCase();

      return name.contains(keyword.toLowerCase()) ||
          student.admissionNo
              .toLowerCase()
              .contains(keyword.toLowerCase());
    }).toList();
  }

  @override
  Future<void> updateStudent(StudentModel student) async {
    await _collection.doc(student.id).update(student.toMap());
  }


  @override
Future<String> uploadStudentPhoto(
  String studentId,
  Uint8List imageBytes,
) async {
  try {
    print('==============================');
    print('UPLOAD STEP 1: Method Called');
    print('Student ID: $studentId');
    print('Image Size: ${imageBytes.lengthInBytes} bytes');

    final storage = FirebaseStorage.instance;

    final ref = storage.ref().child(
      'students/$studentId/profile.jpg',
    );

    print('UPLOAD STEP 2: Storage Reference Created');

    final uploadTask = await ref.putData(imageBytes);

    print('UPLOAD STEP 3: Upload Completed');

    final downloadUrl = await uploadTask.ref.getDownloadURL();

    print('UPLOAD STEP 4: Download URL Generated');
    print(downloadUrl);
    print('==============================');

    return downloadUrl;
  } catch (e, stackTrace) {
    print('==============================');
    print('UPLOAD ERROR');
    print(e);
    print(stackTrace);
    print('==============================');
    rethrow;
  }
}

}
