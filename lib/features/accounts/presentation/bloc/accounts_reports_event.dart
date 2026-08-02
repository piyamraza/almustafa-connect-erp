import 'package:equatable/equatable.dart';

import '../../domain/services/accounts_report_service.dart';

sealed class AccountsReportsEvent extends Equatable {
  const AccountsReportsEvent();

  @override
  List<Object?> get props => const [];
}

class ExportAccountsPdfRequested extends AccountsReportsEvent {
  const ExportAccountsPdfRequested({
    required this.reportType,
    required this.fromDate,
    required this.toDate,
  });

  final AccountsReportType reportType;
  final DateTime fromDate;
  final DateTime toDate;

  @override
  List<Object?> get props => [reportType, fromDate, toDate];
}

class ExportAccountsExcelRequested extends AccountsReportsEvent {
  const ExportAccountsExcelRequested({
    required this.reportType,
    required this.fromDate,
    required this.toDate,
  });

  final AccountsReportType reportType;
  final DateTime fromDate;
  final DateTime toDate;

  @override
  List<Object?> get props => [reportType, fromDate, toDate];
}
