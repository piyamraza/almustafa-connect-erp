import 'package:almustafa_connect_erp/features/teachers/data/models/teacher_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads Firestore timestamps and legacy date strings', () {
    final timestamp = Timestamp.fromDate(DateTime(2026, 8, 17));
    final model = TeacherModel.fromMap({
      'id': 'teacher',
      'dateOfBirth': timestamp,
      'joiningDate': '2020-01-02T00:00:00.000',
      'createdAt': timestamp,
      'updatedAt': timestamp,
    });

    expect(model.dateOfBirth, DateTime(2026, 8, 17));
    expect(model.joiningDate, DateTime(2020, 1, 2));
    expect(model.createdAt, DateTime(2026, 8, 17));
  });
}
