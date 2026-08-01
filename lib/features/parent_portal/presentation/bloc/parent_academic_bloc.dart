import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/parent_academic_dashboard_entity.dart';
import '../../domain/services/parent_academic_service.dart';

sealed class ParentAcademicEvent {
  const ParentAcademicEvent();
}

class LoadParentAcademicDashboard extends ParentAcademicEvent {
  const LoadParentAcademicDashboard({
    required this.student,
    required this.academicSession,
  });

  final StudentEntity student;
  final String academicSession;
}

sealed class ParentAcademicState {
  const ParentAcademicState();
}

class ParentAcademicInitial extends ParentAcademicState {
  const ParentAcademicInitial();
}

class ParentAcademicLoading extends ParentAcademicState {
  const ParentAcademicLoading();
}

class ParentAcademicLoaded extends ParentAcademicState {
  const ParentAcademicLoaded(this.dashboard);

  final ParentAcademicDashboardEntity dashboard;
}

class ParentAcademicError extends ParentAcademicState {
  const ParentAcademicError(this.message);

  final String message;
}

class ParentAcademicBloc
    extends Bloc<ParentAcademicEvent, ParentAcademicState> {
  ParentAcademicBloc(this._service) : super(const ParentAcademicInitial()) {
    on<LoadParentAcademicDashboard>(_load);
  }

  final ParentAcademicService _service;

  Future<void> _load(
    LoadParentAcademicDashboard event,
    Emitter<ParentAcademicState> emit,
  ) async {
    emit(const ParentAcademicLoading());

    try {
      final dashboard = await _service.loadDashboard(
        student: event.student,
        academicSession: event.academicSession,
      );
      emit(ParentAcademicLoaded(dashboard));
    } catch (error) {
      emit(ParentAcademicError(error.toString()));
    }
  }
}
