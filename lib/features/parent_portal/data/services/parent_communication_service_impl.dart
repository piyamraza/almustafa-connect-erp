import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/parent_account_entity.dart';
import '../../domain/entities/parent_communication_dashboard_entity.dart';
import '../../domain/services/parent_communication_service.dart';

class ParentCommunicationServiceImpl
    implements ParentCommunicationService {
  const ParentCommunicationServiceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<ParentCommunicationDashboardEntity> loadDashboard({
    required ParentAccountEntity parent,
    required StudentEntity student,
    required String academicSession,
  }) async {
    final values = await Future.wait([
      _safeCollection('student_fees'),
      _safeCollection('monthly_fees'),
      _safeCollection('fee_payments'),
      _safeCollection('fee_challans'),
      _safeCollection('fee_receipts'),
      _safeCollection('notices'),
      _safeCollection('notice_receipts'),
      _safeCollection('academic_calendar_events'),
    ]);

    final fees = _feeItems(
      [...values[0], ...values[1]],
      values[2],
      values[3],
      values[4],
      student,
      academicSession,
    );

    final notices = _noticeItems(
      values[5],
      values[6],
      parent,
      student,
      academicSession,
    );

    final calendarItems = _calendarItems(
      values[7],
      student,
      academicSession,
    );

    final totalOutstanding = fees.fold<double>(
      0,
      (sum, item) => sum + (item.outstanding > 0 ? item.outstanding : 0),
    );
    final unpaidCount =
        fees.where((item) => item.outstanding > 0).length;
    final unreadNoticeCount =
        notices.where((item) => !item.isRead).length;
    final pendingAcknowledgementCount = notices
        .where(
          (item) =>
              item.acknowledgementRequired &&
              !item.isAcknowledged,
        )
        .length;
    final now = DateTime.now();
    final upcomingEventCount = calendarItems
        .where(
          (item) =>
              item.startDate != null &&
              !item.startDate!.isBefore(
                DateTime(now.year, now.month, now.day),
              ),
        )
        .length;

    return ParentCommunicationDashboardEntity(
      totalOutstanding: totalOutstanding,
      unpaidCount: unpaidCount,
      unreadNoticeCount: unreadNoticeCount,
      pendingAcknowledgementCount:
          pendingAcknowledgementCount,
      upcomingEventCount: upcomingEventCount,
      fees: fees,
      notices: notices,
      calendarItems: calendarItems,
    );
  }

  @override
  Future<void> markNoticeRead({
    required String parentId,
    required String noticeId,
    required String parentName,
  }) async {
    final reference = _firestore
        .collection('notice_receipts')
        .doc('${noticeId}_$parentId');

    final snapshot = await reference.get();
    final now = DateTime.now();

    await reference.set({
      'noticeId': noticeId,
      'recipientId': parentId,
      'recipientName': parentName,
      'recipientType': 'parent',
      'status': 'read',
      'readAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'createdAt': snapshot.exists
          ? snapshot.data()?['createdAt'] ??
              Timestamp.fromDate(now)
          : Timestamp.fromDate(now),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> acknowledgeNotice({
    required String parentId,
    required String noticeId,
    required String parentName,
  }) async {
    final reference = _firestore
        .collection('notice_receipts')
        .doc('${noticeId}_$parentId');

    final now = DateTime.now();

    await reference.set({
      'noticeId': noticeId,
      'recipientId': parentId,
      'recipientName': parentName,
      'recipientType': 'parent',
      'status': 'acknowledged',
      'readAt': Timestamp.fromDate(now),
      'acknowledgedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'createdAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _safeCollection(String name) async {
    try {
      return (await _firestore.collection(name).get()).docs;
    } catch (_) {
      return const [];
    }
  }

  List<ParentFeeItemEntity> _feeItems(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> feeDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> paymentDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> challanDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> receiptDocs,
    StudentEntity student,
    String session,
  ) {
    final paymentsByFee = <String, double>{};
    for (final doc in paymentDocs) {
      final map = doc.data();
      if (!_belongsToStudent(map, student)) continue;
      final feeId = _string(map, ['feeId', 'monthlyFeeId']);
      paymentsByFee[feeId] =
          (paymentsByFee[feeId] ?? 0) +
          (_number(map, ['amount', 'paidAmount']) ?? 0);
    }

    final challanByFee = <String, String>{};
    for (final doc in challanDocs) {
      final map = doc.data();
      final feeId = _string(map, ['feeId', 'monthlyFeeId']);
      final url = _string(map, ['fileUrl', 'challanUrl', 'pdfUrl']);
      if (feeId.isNotEmpty && url.isNotEmpty) challanByFee[feeId] = url;
    }

    final receiptByFee = <String, String>{};
    for (final doc in receiptDocs) {
      final map = doc.data();
      final feeId = _string(map, ['feeId', 'monthlyFeeId']);
      final url = _string(map, ['fileUrl', 'receiptUrl', 'pdfUrl']);
      if (feeId.isNotEmpty && url.isNotEmpty) receiptByFee[feeId] = url;
    }

    final items = <ParentFeeItemEntity>[];
    for (final doc in feeDocs) {
      final map = doc.data();
      if (!_belongsToStudent(map, student)) continue;
      if (!_matchesSession(map, session)) continue;

      final amount = _number(
            map,
            ['totalAmount', 'amount', 'payableAmount'],
          ) ??
          0;
      final paidAmount = paymentsByFee[doc.id] ??
          (_number(map, ['paidAmount']) ?? 0);

      items.add(
        ParentFeeItemEntity(
          id: doc.id,
          title: _string(
            map,
            ['title', 'feeTitle', 'description'],
            fallback: 'Monthly Fee',
          ),
          month: _string(
            map,
            ['monthName', 'month', 'feeMonth'],
          ),
          amount: amount,
          paidAmount: paidAmount,
          status: paidAmount >= amount && amount > 0
              ? 'Paid'
              : _string(
                  map,
                  ['status', 'paymentStatus'],
                  fallback: 'Unpaid',
                ),
          dueDate: _date(map, ['dueDate']),
          challanUrl: challanByFee[doc.id] ??
              _string(map, ['challanUrl']),
          receiptUrl: receiptByFee[doc.id] ??
              _string(map, ['receiptUrl']),
        ),
      );
    }

    items.sort(
      (a, b) => (b.dueDate ?? DateTime(1970))
          .compareTo(a.dueDate ?? DateTime(1970)),
    );
    return items;
  }

  List<ParentNoticeItemEntity> _noticeItems(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> noticeDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> receiptDocs,
    ParentAccountEntity parent,
    StudentEntity student,
    String session,
  ) {
    final receiptByNotice = <String, Map<String, dynamic>>{};
    for (final doc in receiptDocs) {
      final map = doc.data();
      if (_string(map, ['recipientId']) == parent.id) {
        receiptByNotice[_string(map, ['noticeId'])] = map;
      }
    }

    final items = <ParentNoticeItemEntity>[];
    final now = DateTime.now();

    for (final doc in noticeDocs) {
      final map = doc.data();
      if (!_matchesSession(map, session)) continue;
      if (!_noticeTargetsStudent(map, student)) continue;

      final status = _string(map, ['status']).toLowerCase();
      if (status != 'published') continue;

      final publishAt = _date(map, ['publishedAt', 'publishAt']);
      final expireAt = _date(map, ['expireAt']);
      if (publishAt != null && publishAt.isAfter(now)) continue;
      if (expireAt != null && expireAt.isBefore(now)) continue;

      final receipt = receiptByNotice[doc.id];
      final receiptStatus =
          _string(receipt ?? const {}, ['status']).toLowerCase();

      final rawAttachments =
          map['attachments'] as List<dynamic>? ?? const [];
      final attachmentUrls = rawAttachments
          .whereType<Map<String, dynamic>>()
          .map((item) => item['fileUrl']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList(growable: false);

      items.add(
        ParentNoticeItemEntity(
          id: doc.id,
          title: _string(map, ['title'], fallback: 'Notice'),
          message: _string(map, ['message']),
          priority: _string(
            map,
            ['priority'],
            fallback: 'normal',
          ),
          publishAt: publishAt,
          expireAt: expireAt,
          isRead: receiptStatus == 'read' ||
              receiptStatus == 'acknowledged',
          acknowledgementRequired:
              map['acknowledgementRequired'] as bool? ?? false,
          isAcknowledged: receiptStatus == 'acknowledged',
          attachmentUrls: attachmentUrls,
        ),
      );
    }

    items.sort(
      (a, b) => (b.publishAt ?? DateTime(1970))
          .compareTo(a.publishAt ?? DateTime(1970)),
    );
    return items;
  }

  List<ParentCalendarItemEntity> _calendarItems(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    StudentEntity student,
    String session,
  ) {
    final items = <ParentCalendarItemEntity>[];
    for (final doc in docs) {
      final map = doc.data();
      if (!_matchesSession(map, session)) continue;
      if (!_calendarTargetsStudent(map, student)) continue;

      items.add(
        ParentCalendarItemEntity(
          id: doc.id,
          title: _string(
            map,
            ['title', 'eventName'],
            fallback: 'School Event',
          ),
          type: _string(
            map,
            ['type', 'eventType'],
            fallback: 'event',
          ),
          startDate: _date(
            map,
            ['startDate', 'date', 'eventDate'],
          ),
          endDate: _date(map, ['endDate']),
          description: _string(
            map,
            ['description', 'notes'],
          ),
        ),
      );
    }

    items.sort(
      (a, b) => (a.startDate ?? DateTime(2100))
          .compareTo(b.startDate ?? DateTime(2100)),
    );
    return items;
  }

  bool _noticeTargetsStudent(
    Map<String, dynamic> map,
    StudentEntity student,
  ) {
    final audience = _string(
      map,
      ['audienceType'],
      fallback: 'wholeSchool',
    );

    if ([
      'wholeSchool',
      'students',
      'parents',
    ].contains(audience)) {
      return true;
    }

    final classIds =
        (map['classIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();
    final sectionIds =
        (map['sectionIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();

    if (audience == 'selectedClasses') {
      return classIds.contains(student.classId);
    }
    if (audience == 'selectedSections') {
      return sectionIds.contains(student.sectionId);
    }

    return false;
  }

  bool _calendarTargetsStudent(
    Map<String, dynamic> map,
    StudentEntity student,
  ) {
    final classId = _string(map, ['classId']);
    final sectionId = _string(map, ['sectionId']);

    return (classId.isEmpty || classId == student.classId) &&
        (sectionId.isEmpty || sectionId == student.sectionId);
  }

  bool _belongsToStudent(
    Map<String, dynamic> map,
    StudentEntity student,
  ) {
    final studentId = _string(
      map,
      ['studentId', 'studentID'],
    );
    final admissionNo = _string(
      map,
      ['admissionNo', 'admissionNumber'],
    );

    return studentId == student.id ||
        (admissionNo.isNotEmpty &&
            admissionNo == student.admissionNo);
  }

  bool _matchesSession(
    Map<String, dynamic> map,
    String session,
  ) {
    final value = _string(
      map,
      ['academicSession', 'session', 'academicYear'],
    );
    return value.isEmpty || value == session;
  }

  String _string(
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

  double? _number(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  DateTime? _date(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
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