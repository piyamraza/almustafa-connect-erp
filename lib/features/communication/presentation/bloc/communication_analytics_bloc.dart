import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_communication_analytics.dart';
import 'communication_analytics_event.dart';
import 'communication_analytics_state.dart';

class CommunicationAnalyticsBloc
    extends Bloc<CommunicationAnalyticsEvent, CommunicationAnalyticsState> {
  CommunicationAnalyticsBloc(this._getAnalytics)
    : super(const CommunicationAnalyticsInitial()) {
    on<LoadCommunicationAnalytics>(_load);
  }

  final GetCommunicationAnalytics _getAnalytics;

  Future<void> _load(
    LoadCommunicationAnalytics event,
    Emitter<CommunicationAnalyticsState> emit,
  ) async {
    emit(const CommunicationAnalyticsLoading());

    try {
      emit(CommunicationAnalyticsLoaded(await _getAnalytics()));
    } catch (error) {
      emit(
        CommunicationAnalyticsFailure(
          error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}
