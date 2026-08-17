import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class TeacherAppointmentLetterService {
  TeacherAppointmentLetterService(this.firestore, this.storage);

  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  CollectionReference<Map<String, dynamic>> get _letters =>
      firestore.collection('teacherAppointmentLetters');

  Stream<List<Map<String, dynamic>>> watchLetters() => _letters
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());

  String newId() => _letters.doc().id;

  String generateNumber() {
    final now = DateTime.now();
    return 'APL-${now.year}-${now.microsecondsSinceEpoch.toString().substring(7)}';
  }

  Future<void> save(Map<String, dynamic> value) async {
    final id = value['id'] as String;
    await _letters.doc(id).set({...value, 'updatedAt': Timestamp.now()});
  }

  Future<String> upload({
    required String id,
    required String name,
    required Uint8List bytes,
  }) async {
    final ref = storage.ref('teacher_appointment_letters/$id/$name');
    await ref.putData(bytes);
    return ref.getDownloadURL();
  }

  Future<List<Map<String, dynamic>>> loadTerms() async {
    final doc = await firestore
        .collection('hrConfiguration')
        .doc('appointmentLetterTerms')
        .get();
    final terms = doc.data()?['terms'];
    if (terms is List) {
      return terms
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return defaultTerms.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> saveTerms(List<Map<String, dynamic>> terms) => firestore
      .collection('hrConfiguration')
      .doc('appointmentLetterTerms')
      .set({'terms': terms, 'updatedAt': Timestamp.now()});

  static const defaultTerms = <Map<String, dynamic>>[
    {'enabled': true, 'text': 'The appointment is subject to successful completion of the probation period and written confirmation by management.'},
    {'enabled': true, 'text': 'Regular attendance, punctuality and compliance with the assigned timetable and workload are mandatory.'},
    {'enabled': true, 'text': 'The teacher will prepare lessons, check student work, conduct assessments and maintain required academic records.'},
    {'enabled': true, 'text': 'Examination, invigilation and other school duties assigned by management must be performed responsibly.'},
    {'enabled': true, 'text': 'Student safety, professional conduct and the school dress code must be observed at all times.'},
    {'enabled': true, 'text': 'Leave is subject to entitlement, prior approval and the applicable school leave policy.'},
    {'enabled': true, 'text': 'Salary will be paid according to the school payroll schedule; unauthorized absence or late arrival may result in deductions.'},
    {'enabled': true, 'text': 'Student, employee and school information is confidential and must not be shared without authorization.'},
    {'enabled': true, 'text': 'Corporal punishment, harassment and discrimination are strictly prohibited.'},
    {'enabled': true, 'text': 'School property and devices issued to the employee remain the employee’s responsibility.'},
    {'enabled': true, 'text': 'Photography, social media use and publication of school-related content require prior authorization.'},
    {'enabled': true, 'text': 'Private tuition involving school students and any conflict of interest must be disclosed and approved.'},
    {'enabled': true, 'text': 'Resignation requires the applicable notice period; termination will be governed by contract terms and school policy.'},
    {'enabled': true, 'text': 'All submitted qualifications and identity documents are subject to verification; false information may cancel this appointment.'},
    {'enabled': true, 'text': 'Management may transfer duties between classes, subjects or campuses when operationally required.'},
    {'enabled': true, 'text': 'The employee agrees to comply with current school policies and future amendments communicated by management.'},
  ];
}
