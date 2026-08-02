import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_accounts_overview.dart';
import 'accounts_event.dart';
import 'accounts_state.dart';

class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  AccountsBloc(this._getOverview) : super(const AccountsInitial()) {
    on<LoadAccountsOverview>(_onLoad);
    on<RefreshAccountsOverview>(_onRefresh);
  }

  final GetAccountsOverview _getOverview;

  Future<void> _onLoad(
    LoadAccountsOverview event,
    Emitter<AccountsState> emit,
  ) async {
    emit(const AccountsLoading());
    await _loadOverview(emit);
  }

  Future<void> _onRefresh(
    RefreshAccountsOverview event,
    Emitter<AccountsState> emit,
  ) async {
    await _loadOverview(emit);
  }

  Future<void> _loadOverview(Emitter<AccountsState> emit) async {
    try {
      final data = await _getOverview();
      emit(
        AccountsLoaded(
          expenses: data.expenses,
          incomeEntries: data.incomeEntries,
          payrollRecords: data.payrollRecords,
          profitLoss: data.profitLoss,
          cashbookEntries: data.cashbookEntries,
        ),
      );
    } catch (error) {
      emit(AccountsFailure(error.toString().replaceFirst('Exception: ', '')));
    }
  }
}
