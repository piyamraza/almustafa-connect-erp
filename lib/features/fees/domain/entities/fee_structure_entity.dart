import 'package:equatable/equatable.dart';

class FeeStructureEntity extends Equatable {
  const FeeStructureEntity({
    required this.id,
    required this.academicSession,
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    required this.monthlyTuitionFee,
    required this.admissionFee,
    required this.annualCharges,
    required this.transportFee,
    required this.otherMonthlyCharges,
    required this.dueDay,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String academicSession;
  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;
  final double monthlyTuitionFee;
  final double admissionFee;
  final double annualCharges;
  final double transportFee;
  final double otherMonthlyCharges;
  final int dueDay;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get recurringMonthlyTotal =>
      monthlyTuitionFee + transportFee + otherMonthlyCharges;

  double get oneTimeTotal => admissionFee + annualCharges;

  FeeStructureEntity copyWith({
    String? academicSession,
    String? classId,
    String? className,
    String? sectionId,
    String? sectionName,
    double? monthlyTuitionFee,
    double? admissionFee,
    double? annualCharges,
    double? transportFee,
    double? otherMonthlyCharges,
    int? dueDay,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return FeeStructureEntity(
      id: id,
      academicSession: academicSession ?? this.academicSession,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
      monthlyTuitionFee: monthlyTuitionFee ?? this.monthlyTuitionFee,
      admissionFee: admissionFee ?? this.admissionFee,
      annualCharges: annualCharges ?? this.annualCharges,
      transportFee: transportFee ?? this.transportFee,
      otherMonthlyCharges: otherMonthlyCharges ?? this.otherMonthlyCharges,
      dueDay: dueDay ?? this.dueDay,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object> get props => [
    id,
    academicSession,
    classId,
    className,
    sectionId,
    sectionName,
    monthlyTuitionFee,
    admissionFee,
    annualCharges,
    transportFee,
    otherMonthlyCharges,
    dueDay,
    isActive,
    createdAt,
    updatedAt,
  ];
}
