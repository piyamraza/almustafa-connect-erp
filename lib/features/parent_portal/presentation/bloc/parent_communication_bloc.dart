import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/parent_account_entity.dart';
import '../../domain/entities/parent_communication_dashboard_entity.dart';
import '../../domain/services/parent_communication_service.dart';

sealed class ParentCommunicationEvent {
  const ParentCommunicationEvent();
}

class LoadParentCommunicationDashboard extends ParentCommunicationEvent {
  const LoadParentCommunicationDashboard({
    required this.parent,
    required this.student,
    required this.academicSession,
  });

  final ParentAccountEntity parent;
  final StudentEntity student;
  final String academicSession;
}

class ReadParentNotice extends ParentCommunicationEvent {
  const ReadParentNotice({
    required this.parent,
    required this.student,
    required this.academicSession,
    required this.noticeId,
  });

  final ParentAccountEntity parent;
  final StudentEntity student;
  final String academicSession;
  final String noticeId;
}

class AcknowledgeParentNotice extends ParentCommunicationEvent {
  const AcknowledgeParentNotice({
    required this.parent,
    required this.student,
    required this.academicSession,
    required this.noticeId,
  });

  final ParentAccountEntity parent;
  final StudentEntity student;
  final String academicSession;
  final String noticeId;
}

sealed class ParentCommunicationState {
  const ParentCommunicationState();
}

class ParentCommunicationInitial extends ParentCommunicationState {
  const ParentCommunicationInitial();
}

class ParentCommunicationLoading extends ParentCommunicationState {
  const ParentCommunicationLoading();
}

class ParentCommunicationLoaded extends ParentCommunicationState {
  const ParentCommunicationLoaded(this.dashboard);

  final ParentCommunicationDashboardEntity dashboard;
}

class ParentCommunicationError extends ParentCommunicationState {
  const ParentCommunicationError(this.message);

  final String message;
}

class ParentCommunicationBloc
    extends Bloc<ParentCommunicationEvent, ParentCommunicationState> {
  ParentCommunicationBloc(this._service)
    : super(const ParentCommunicationInitial()) {
    on<LoadParentCommunicationDashboard>(_load);
    on<ReadParentNotice>(_read);
    on<AcknowledgeParentNotice>(_acknowledge);
  }

  final ParentCommunicationService _service;

  Future<void> _load(
    LoadParentCommunicationDashboard event,
    Emitter<ParentCommunicationState> emit,
  ) async {
    emit(const ParentCommunicationLoading());
    try {
      emit(
        ParentCommunicationLoaded(
          await _service.loadDashboard(
            parent: event.parent,
            student: event.student,
            academicSession: event.academicSession,
          ),
        ),
      );
    } catch (error) {
      emit(ParentCommunicationError(error.toString()));
    }
  }

  Future<void> _read(
    ReadParentNotice event,
    Emitter<ParentCommunicationState> emit,
  ) async {
    await _service.markNoticeRead(
      parentId: event.parent.id,
      noticeId: event.noticeId,
      parentName: event.parent.fullName,
    );
    add(
      LoadParentCommunicationDashboard(
        parent: event.parent,
        student: event.student,
        academicSession: event.academicSession,
      ),
    );
  }

  Future<void> _acknowledge(
    AcknowledgeParentNotice event,
    Emitter<ParentCommunicationState> emit,
  ) async {
    await _service.acknowledgeNotice(
      parentId: event.parent.id,
      noticeId: event.noticeId,
      parentName: event.parent.fullName,
    );
    add(
      LoadParentCommunicationDashboard(
        parent: event.parent,
        student: event.student,
        academicSession: event.academicSession,
      ),
    );
  }
}
