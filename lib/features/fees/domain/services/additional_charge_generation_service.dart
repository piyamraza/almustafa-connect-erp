import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../academic_structure/domain/services/academic_reference_resolver.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../entities/additional_charge_entity.dart';
import '../entities/student_additional_charge_due_entity.dart';
import '../repositories/additional_charge_repository.dart';
import '../repositories/student_additional_charge_due_repository.dart';

class ChargeGenerationResult {
  const ChargeGenerationResult({
    required this.eligibleCount,
    required this.generatedCount,
    required this.skippedCount,
    required this.excludedCount,
    required this.totalAmountGenerated,
  });
  final int eligibleCount, generatedCount, skippedCount, excludedCount;
  final double totalAmountGenerated;
}

class AdditionalChargeGenerationService {
  const AdditionalChargeGenerationService(
    this._students,
    this._charges,
    this._dues,
    this._academicStructure,
  );
  final StudentRepository _students;
  final AdditionalChargeRepository _charges;
  final StudentAdditionalChargeDueRepository _dues;
  final AcademicStructureRepository _academicStructure;

  Future<ChargeGenerationResult> estimate(AdditionalChargeEntity charge) =>
      _run(charge, persist: false);
  Future<ChargeGenerationResult> generate(AdditionalChargeEntity charge) =>
      _run(charge, persist: true);

  Future<ChargeGenerationResult> _run(
    AdditionalChargeEntity charge, {
    required bool persist,
  }) async {
    if (!charge.isActive) {
      throw StateError('Activate this charge before generation.');
    }
    if (charge.amount <= 0) {
      throw StateError('Charge amount must be greater than zero.');
    }
    final values = await Future.wait<Object>([
      _students.getStudents(),
      _academicStructure.getClasses(),
      _academicStructure.getSections(),
    ]);
    final all = (values[0] as List<StudentEntity>)
        .where((s) => s.isActive)
        .toList();
    final resolver = AcademicReferenceResolver(
      classes: values[1] as List<AcademicClassEntity>,
      sections: values[2] as List<SectionEntity>,
    );
    bool matches(StudentEntity student) {
      final classMatch =
          resolver.sameClass(student.classId, charge.classId) ||
          resolver.sameClass(student.classId, charge.className);
      final sectionMatch =
          resolver.sameSection(student.sectionId, charge.sectionId) ||
          resolver.sameSection(student.sectionId, charge.sectionName);
      return switch (charge.scope) {
        AdditionalChargeScope.entireSchool => true,
        AdditionalChargeScope.classWise => classMatch,
        AdditionalChargeScope.sectionWise => classMatch && sectionMatch,
        AdditionalChargeScope.selectedStudents =>
          charge.selectedStudentIds.contains(student.id),
      };
    }

    final scoped = all.where(matches).toList();
    final excluded = scoped
        .where((s) => charge.excludedStudentIds.contains(s.id))
        .length;
    final eligible = scoped
        .where((s) => !charge.excludedStudentIds.contains(s.id))
        .toList();
    final existing = await _dues.getDues(chargeId: charge.id);
    final existingIds = existing
        .where((d) => d.status != StudentAdditionalChargeDueStatus.cancelled)
        .map((d) => d.studentId)
        .toSet();
    final fresh = eligible.where((s) => !existingIds.contains(s.id)).toList();
    if (persist && fresh.isNotEmpty) {
      final now = DateTime.now();
      await _dues.saveDuesBatch(
        fresh
            .map(
              (student) => StudentAdditionalChargeDueEntity(
                id: _dues.generateId(),
                chargeId: charge.id,
                chargeTitle: charge.title,
                chargeCategory: charge.category,
                studentId: student.id,
                studentName: student.fullName,
                admissionNo: student.admissionNo,
                classId: student.classId,
                sectionId: student.sectionId,
                academicSession: charge.academicSession,
                amount: charge.amount,
                discountAmount: 0,
                waivedAmount: 0,
                netPayable: charge.amount,
                paidAmount: 0,
                dueDate: charge.dueDate,
                status: StudentAdditionalChargeDueStatus.unpaid,
                notes: '',
                generatedAt: now,
                updatedAt: now,
              ),
            )
            .toList(),
      );
    }
    if (persist && eligible.isNotEmpty) {
      await _charges.markGenerated(
        charge.id,
        existingIds.length + fresh.length,
      );
    }
    return ChargeGenerationResult(
      eligibleCount: eligible.length,
      generatedCount: fresh.length,
      skippedCount: eligible.length - fresh.length,
      excludedCount: excluded,
      totalAmountGenerated: fresh.length * charge.amount,
    );
  }

}
