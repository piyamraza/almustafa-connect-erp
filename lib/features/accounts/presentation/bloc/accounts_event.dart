import 'package:equatable/equatable.dart';

sealed class AccountsEvent extends Equatable {
  const AccountsEvent();

  @override
  List<Object?> get props => const [];
}

class LoadAccountsOverview extends AccountsEvent {
  const LoadAccountsOverview();
}

class RefreshAccountsOverview extends AccountsEvent {
  const RefreshAccountsOverview();
}
