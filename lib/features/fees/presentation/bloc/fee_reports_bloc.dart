import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/fee_report_entity.dart';
import '../../domain/entities/monthly_fee_due_entity.dart';
import '../../domain/repositories/fee_payment_repository.dart';
import '../../domain/repositories/monthly_fee_due_repository.dart';
import '../../domain/services/fee_report_service.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/services/academic_class_order.dart';

sealed class FeeReportsEvent {
  const FeeReportsEvent();
}

class LoadFeeReport extends FeeReportsEvent {
  const LoadFeeReport({
    required this.type,
    required this.academicSession,
    required this.startDate,
    required this.endDate,
  });

  final FeeReportType type;
  final String academicSession;
  final DateTime startDate;
  final DateTime endDate;
}

class PrintLoadedFeeReport extends FeeReportsEvent {
  const PrintLoadedFeeReport();
}

class ShareLoadedFeeReport extends FeeReportsEvent {
  const ShareLoadedFeeReport();
}

class ExportLoadedFeeReportExcel extends FeeReportsEvent {
  const ExportLoadedFeeReportExcel();
}

sealed class FeeReportsState {
  const FeeReportsState();
}

class FeeReportsInitial extends FeeReportsState {
  const FeeReportsInitial();
}

class FeeReportsLoading extends FeeReportsState {
  const FeeReportsLoading();
}

class FeeReportsLoaded extends FeeReportsState {
  const FeeReportsLoaded(this.report, {this.message});

  final FeeReportData report;
  final String? message;
}

class FeeReportsError extends FeeReportsState {
  const FeeReportsError(this.message);

  final String message;
}

class FeeReportsBloc extends Bloc<FeeReportsEvent, FeeReportsState> {
  FeeReportsBloc(
    this._dueRepository,
    this._paymentRepository,
    this._reportService,
    this._studentRepository,
    this._academicRepository,
  ) : super(const FeeReportsInitial()) {
    on<LoadFeeReport>(_load);
    on<PrintLoadedFeeReport>(_print);
    on<ShareLoadedFeeReport>(_share);
    on<ExportLoadedFeeReportExcel>(_excel);
  }

  final MonthlyFeeDueRepository _dueRepository;
  final FeePaymentRepository _paymentRepository;
  final FeeReportService _reportService;
  final StudentRepository _studentRepository;
  final AcademicStructureRepository _academicRepository;
  FeeReportData? _current;

  Future<void> _load(LoadFeeReport event, Emitter<FeeReportsState> emit) async {
    emit(const FeeReportsLoading());

    try {
      final dues = await _dueRepository.getMonthlyDues(
        academicSession: event.academicSession,
      );
      final payments = await _paymentRepository.getPayments(
        academicSession: event.academicSession,
      );
      final students = await _studentRepository.getStudents();
      final classes = await _academicRepository.getClasses();

      final filteredDues = dues.where((item) {
        final date = DateTime(item.year, item.month);
        return !date.isBefore(
              DateTime(event.startDate.year, event.startDate.month),
            ) &&
            !date.isAfter(DateTime(event.endDate.year, event.endDate.month));
      }).toList();

      final filteredPayments = payments.where((item) {
        final date = DateTime(
          item.paymentDate.year,
          item.paymentDate.month,
          item.paymentDate.day,
        );
        final start = DateTime(
          event.startDate.year,
          event.startDate.month,
          event.startDate.day,
        );
        final end = DateTime(
          event.endDate.year,
          event.endDate.month,
          event.endDate.day,
          23,
          59,
          59,
        );
        return !date.isBefore(start) && !date.isAfter(end);
      }).toList();

      _current = FeeReportData(
        type: event.type,
        dues: filteredDues,
        payments: filteredPayments,
        startDate: event.startDate,
        endDate: event.endDate,
        outstandingGroups: _buildOutstandingGroups(
          filteredDues,
          students,
          classes,
        ),
      );

      emit(FeeReportsLoaded(_current!));
    } catch (error) {
      emit(FeeReportsError(_message(error)));
    }
  }

  List<ClassOutstandingFeeGroup> _buildOutstandingGroups(
    List<MonthlyFeeDueEntity> dues,
    List<StudentEntity> students,
    List<AcademicClassEntity> classes,
  ) {
    final studentById = {for (final student in students) student.id: student};
    final classById = {for (final item in classes) item.id: item};
    final totals = <String, double>{};
    for (final due in dues.where((item) => item.outstandingAmount > 0)) {
      totals[due.studentId] =
          (totals[due.studentId] ?? 0) + due.outstandingAmount;
    }

    final grouped = <String, List<OutstandingFeeStudent>>{};
    for (final entry in totals.entries) {
      final student = studentById[entry.key];
      if (student == null) continue;
      final classItem = classById[student.classId];
      final className = classItem?.name.trim();
      final row = OutstandingFeeStudent(
        studentId: student.id,
        classId: student.classId,
        className: className == null || className.isEmpty
            ? student.classId
            : className,
        studentName: student.fullName,
        fatherName: student.fatherName,
        rollNumber: student.rollNumber,
        outstandingAmount: entry.value,
      );
      grouped.putIfAbsent(row.classId, () => []).add(row);
    }

    final result =
        grouped.entries.map((entry) {
          final rows = entry.value
            ..sort(
              (a, b) =>
                  _rollValue(a.rollNumber).compareTo(_rollValue(b.rollNumber)),
            );
          return ClassOutstandingFeeGroup(
            classId: entry.key,
            className: rows.first.className,
            students: rows,
          );
        }).toList()..sort(
          (a, b) => compareAcademicClassNames(a.className, b.className),
        );
    return result;
  }

  int _rollValue(String value) => int.tryParse(value.trim()) ?? 999999;

  Future<void> _print(
    PrintLoadedFeeReport event,
    Emitter<FeeReportsState> emit,
  ) async {
    await _run(
      emit,
      action: () => _reportService.printPdf(_requiredReport()),
      message: 'Print preview opened.',
    );
  }

  Future<void> _share(
    ShareLoadedFeeReport event,
    Emitter<FeeReportsState> emit,
  ) async {
    await _run(
      emit,
      action: () => _reportService.sharePdf(_requiredReport()),
      message: 'PDF report prepared.',
    );
  }

  Future<void> _excel(
    ExportLoadedFeeReportExcel event,
    Emitter<FeeReportsState> emit,
  ) async {
    await _run(
      emit,
      action: () => _reportService.exportExcel(_requiredReport()),
      message: 'Excel report prepared.',
    );
  }

  FeeReportData _requiredReport() {
    final report = _current;
    if (report == null) {
      throw StateError('Load a report first.');
    }
    return report;
  }

  Future<void> _run(
    Emitter<FeeReportsState> emit, {
    required Future<void> Function() action,
    required String message,
  }) async {
    final report = _requiredReport();
    emit(const FeeReportsLoading());

    try {
      await action();
      emit(FeeReportsLoaded(report, message: message));
    } catch (error) {
      emit(FeeReportsError(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('StateError: ', '');
}
