import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/parent_account_entity.dart';
import '../../domain/entities/parent_timeline_item_entity.dart';
import '../../domain/services/parent_timeline_service.dart';

class ParentTimelineServiceImpl implements ParentTimelineService {
  const ParentTimelineServiceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<ParentTimelineItemEntity>> loadTimeline({
    required ParentAccountEntity parent,
    required StudentEntity student,
    required String academicSession,
  }) async {
    final collections = await Future.wait([
      _safe('attendance'),
      _safe('homework_submissions'),
      _safe('fee_payments'),
      _safe('notices'),
      _safe('results'),
      _safe('result_sheets'),
      _safe('academic_calendar_events'),
    ]);

    final items = <ParentTimelineItemEntity>[];

    for (final doc in collections[0]) {
      final map = doc.data();
      if (!_student(map, student) || !_session(map, academicSession)) {
        continue;
      }
      final date = _date(map, ['date', 'attendanceDate', 'createdAt']);
      if (date == null) continue;
      final status = _text(map, ['status'], fallback: 'Attendance');
      items.add(
        ParentTimelineItemEntity(
          id: 'attendance_${doc.id}',
          title: 'Attendance: $status',
          description: _text(map, ['remarks', 'reason']),
          category: 'Attendance',
          eventDate: date,
          status: status,
        ),
      );
    }

    for (final doc in collections[1]) {
      final map = doc.data();
      if (!_student(map, student)) continue;
      final date = _date(map, ['submittedAt', 'updatedAt', 'createdAt']);
      if (date == null) continue;
      final status = _text(map, ['status'], fallback: 'Submitted');
      items.add(
        ParentTimelineItemEntity(
          id: 'homework_${doc.id}',
          title: 'Homework $status',
          description: _text(map, ['teacherRemarks', 'submissionText']),
          category: 'Homework',
          eventDate: date,
          status: status,
        ),
      );
    }

    for (final doc in collections[2]) {
      final map = doc.data();
      if (!_student(map, student)) continue;
      final date = _date(map, ['paymentDate', 'createdAt']);
      if (date == null) continue;
      final amount = _number(map, ['amount', 'paidAmount']) ?? 0;
      items.add(
        ParentTimelineItemEntity(
          id: 'fee_${doc.id}',
          title: 'Fee Payment',
          description: 'Rs. ${amount.toStringAsFixed(0)} received',
          category: 'Fee',
          eventDate: date,
          status: 'Paid',
        ),
      );
    }

    for (final doc in collections[3]) {
      final map = doc.data();
      if (!_session(map, academicSession)) continue;
      final date = _date(map, ['publishedAt', 'publishAt', 'createdAt']);
      if (date == null) continue;
      items.add(
        ParentTimelineItemEntity(
          id: 'notice_${doc.id}',
          title: _text(map, ['title'], fallback: 'School Notice'),
          description: _text(map, ['message']),
          category: 'Notice',
          eventDate: date,
          status: _text(map, ['priority'], fallback: 'Normal'),
        ),
      );
    }

    for (final doc in [...collections[4], ...collections[5]]) {
      final map = doc.data();
      if (!_student(map, student) || !_session(map, academicSession)) {
        continue;
      }
      final date = _date(map, ['publishedAt', 'updatedAt', 'createdAt']);
      if (date == null) continue;
      final percentage = _number(map, ['percentage', 'overallPercentage']);
      items.add(
        ParentTimelineItemEntity(
          id: 'result_${doc.id}',
          title: _text(map, ['examName', 'title'], fallback: 'Result'),
          description: percentage == null
              ? 'Result published'
              : '${percentage.toStringAsFixed(1)}%',
          category: 'Result',
          eventDate: date,
          status: 'Published',
        ),
      );
    }

    for (final doc in collections[6]) {
      final map = doc.data();
      if (!_session(map, academicSession)) continue;
      final date = _date(map, ['startDate', 'date', 'eventDate']);
      if (date == null) continue;
      items.add(
        ParentTimelineItemEntity(
          id: 'calendar_${doc.id}',
          title: _text(map, ['title', 'eventName'], fallback: 'School Event'),
          description: _text(map, ['description', 'notes']),
          category: 'Calendar',
          eventDate: date,
          status: _text(map, ['type', 'eventType'], fallback: 'Event'),
        ),
      );
    }

    items.sort((a, b) => b.eventDate.compareTo(a.eventDate));
    return items.take(100).toList(growable: false);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _safe(
    String collection,
  ) async {
    try {
      return (await _firestore.collection(collection).get()).docs;
    } catch (_) {
      return const [];
    }
  }

  bool _student(Map<String, dynamic> map, StudentEntity student) {
    final id = _text(map, ['studentId', 'studentID']);
    final admission = _text(map, ['admissionNo', 'admissionNumber']);
    return id == student.id ||
        (admission.isNotEmpty && admission == student.admissionNo);
  }

  bool _session(Map<String, dynamic> map, String session) {
    final value = _text(map, ['academicSession', 'session', 'academicYear']);
    return value.isEmpty || value == session;
  }

  String _text(
    Map<String, dynamic> map,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  double? _number(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  DateTime? _date(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}
