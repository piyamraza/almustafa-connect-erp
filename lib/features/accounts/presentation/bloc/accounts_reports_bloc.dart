import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/services/accounts_report_service.dart';
import '../../domain/usecases/get_accounts_report_data.dart';
import 'accounts_reports_event.dart';
import 'accounts_reports_state.dart';

class AccountsReportsBloc
    extends Bloc<AccountsReportsEvent, AccountsReportsState> {
  AccountsReportsBloc({
    required this._getReportData,
    required this._reportService,
  }) : super(const AccountsReportsReady()) {
    on<ExportAccountsPdfRequested>(_exportPdf);
    on<ExportAccountsExcelRequested>(_exportExcel);
  }

  final GetAccountsReportData _getReportData;
  final AccountsReportService _reportService;

  Future<void> _exportPdf(
    ExportAccountsPdfRequested event,
    Emitter<AccountsReportsState> emit,
  ) async {
    emit(const AccountsReportsExporting());

    try {
      final data = await _getReportData(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      await _reportService.exportPdf(reportType: event.reportType, data: data);

      emit(const AccountsReportsSuccess('PDF report generated successfully.'));
    } catch (error) {
      emit(AccountsReportsFailure(_message(error)));
    }
  }

  Future<void> _exportExcel(
    ExportAccountsExcelRequested event,
    Emitter<AccountsReportsState> emit,
  ) async {
    emit(const AccountsReportsExporting());

    try {
      final data = await _getReportData(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      await _reportService.exportExcel(
        reportType: event.reportType,
        data: data,
      );

      emit(
        const AccountsReportsSuccess('Excel report generated successfully.'),
      );
    } catch (error) {
      emit(AccountsReportsFailure(_message(error)));
    }
  }

  String _message(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
