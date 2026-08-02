import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/additional_charge_entity.dart';
import '../../domain/entities/student_additional_charge_due_entity.dart';

class StudentAdditionalChargeDueModel extends StudentAdditionalChargeDueEntity {
  const StudentAdditionalChargeDueModel({
    required super.id,
    required super.chargeId,
    required super.chargeTitle,
    required super.chargeCategory,
    required super.studentId,
    required super.studentName,
    required super.admissionNo,
    required super.classId,
    required super.sectionId,
    required super.academicSession,
    required super.amount,
    required super.discountAmount,
    required super.waivedAmount,
    required super.netPayable,
    required super.paidAmount,
    required super.dueDate,
    required super.status,
    required super.notes,
    required super.generatedAt,
    required super.updatedAt,
  });
  factory StudentAdditionalChargeDueModel.fromEntity(
    StudentAdditionalChargeDueEntity e,
  ) => StudentAdditionalChargeDueModel(
    id: e.id,
    chargeId: e.chargeId,
    chargeTitle: e.chargeTitle,
    chargeCategory: e.chargeCategory,
    studentId: e.studentId,
    studentName: e.studentName,
    admissionNo: e.admissionNo,
    classId: e.classId,
    sectionId: e.sectionId,
    academicSession: e.academicSession,
    amount: e.amount,
    discountAmount: e.discountAmount,
    waivedAmount: e.waivedAmount,
    netPayable: e.netPayable,
    paidAmount: e.paidAmount,
    dueDate: e.dueDate,
    status: e.status,
    notes: e.notes,
    generatedAt: e.generatedAt,
    updatedAt: e.updatedAt,
  );
  factory StudentAdditionalChargeDueModel.fromMap(Map<String, dynamic> map) =>
      StudentAdditionalChargeDueModel(
        id: map['id'] as String? ?? '',
        chargeId: map['chargeId'] as String? ?? '',
        chargeTitle: map['chargeTitle'] as String? ?? '',
        chargeCategory:
            AdditionalChargeCategory.values
                .where((e) => e.name == map['chargeCategory'])
                .firstOrNull ??
            AdditionalChargeCategory.other,
        studentId: map['studentId'] as String? ?? '',
        studentName: map['studentName'] as String? ?? '',
        admissionNo: map['admissionNo'] as String? ?? '',
        classId: map['classId'] as String? ?? '',
        sectionId: map['sectionId'] as String? ?? '',
        academicSession: map['academicSession'] as String? ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0,
        waivedAmount: (map['waivedAmount'] as num?)?.toDouble() ?? 0,
        netPayable: (map['netPayable'] as num?)?.toDouble() ?? 0,
        paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
        dueDate: _date(map['dueDate']),
        status:
            StudentAdditionalChargeDueStatus.values
                .where((e) => e.name == map['status'])
                .firstOrNull ??
            StudentAdditionalChargeDueStatus.unpaid,
        notes: map['notes'] as String? ?? '',
        generatedAt: _date(map['generatedAt']),
        updatedAt: _date(map['updatedAt']),
      );
  Map<String, dynamic> toMap() => {
    'chargeId': chargeId,
    'chargeTitle': chargeTitle,
    'chargeCategory': chargeCategory.name,
    'studentId': studentId,
    'studentName': studentName,
    'admissionNo': admissionNo,
    'classId': classId,
    'sectionId': sectionId,
    'academicSession': academicSession,
    'amount': amount,
    'discountAmount': discountAmount,
    'waivedAmount': waivedAmount,
    'netPayable': netPayable,
    'paidAmount': paidAmount,
    'dueDate': Timestamp.fromDate(dueDate),
    'status': status.name,
    'notes': notes,
    'generatedAt': Timestamp.fromDate(generatedAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
  static DateTime _date(dynamic value) => value is Timestamp
      ? value.toDate()
      : value is DateTime
      ? value
      : DateTime.now();
}
