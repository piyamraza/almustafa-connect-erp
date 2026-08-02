import 'package:equatable/equatable.dart';

sealed class AccountsReportsState extends Equatable {
  const AccountsReportsState();

  @override
  List<Object?> get props => const [];
}

class AccountsReportsReady extends AccountsReportsState {
  const AccountsReportsReady();
}

class AccountsReportsExporting extends AccountsReportsState {
  const AccountsReportsExporting();
}

class AccountsReportsSuccess extends AccountsReportsState {
  const AccountsReportsSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class AccountsReportsFailure extends AccountsReportsState {
  const AccountsReportsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
