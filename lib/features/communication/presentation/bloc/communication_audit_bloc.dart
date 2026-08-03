import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_communication_delivery_audit.dart';
import 'communication_audit_event.dart';
import 'communication_audit_state.dart';

class CommunicationAuditBloc
    extends Bloc<CommunicationAuditEvent, CommunicationAuditState> {
  CommunicationAuditBloc(this._getAudit)
    : super(const CommunicationAuditInitial()) {
    on<LoadCommunicationAudit>(_load);
  }

  final GetCommunicationDeliveryAudit _getAudit;

  Future<void> _load(
    LoadCommunicationAudit event,
    Emitter<CommunicationAuditState> emit,
  ) async {
    emit(const CommunicationAuditLoading());

    try {
      final data = await _getAudit();

      emit(
        CommunicationAuditLoaded(
          summary: data.summary,
          broadcasts: data.broadcasts,
          pushLogs: data.pushLogs,
          whatsappRequests: data.whatsappRequests,
          auditEntries: data.auditEntries,
        ),
      );
    } catch (error) {
      emit(
        CommunicationAuditFailure(
          error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}
