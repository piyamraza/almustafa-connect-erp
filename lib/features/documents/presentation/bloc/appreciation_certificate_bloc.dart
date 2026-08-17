import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../settings/domain/entities/school_settings_entity.dart';
import '../../../settings/domain/usecases/manage_settings.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../../domain/entities/appreciation_certificate_entity.dart';
import '../../domain/repositories/appreciation_certificate_repository.dart';

sealed class AppreciationCertificateEvent extends Equatable {
  const AppreciationCertificateEvent();
  @override
  List<Object?> get props => [];
}

class LoadAppreciationCertificates extends AppreciationCertificateEvent {
  const LoadAppreciationCertificates();
}

class SaveAppreciationCertificate extends AppreciationCertificateEvent {
  const SaveAppreciationCertificate(this.value);
  final AppreciationCertificateEntity value;
  @override
  List<Object> get props => [value];
}

sealed class AppreciationCertificateState extends Equatable {
  const AppreciationCertificateState();
  @override
  List<Object?> get props => [];
}

class AppreciationCertificateInitial extends AppreciationCertificateState {
  const AppreciationCertificateInitial();
}

class AppreciationCertificateLoading extends AppreciationCertificateState {
  const AppreciationCertificateLoading();
}

class AppreciationCertificateError extends AppreciationCertificateState {
  const AppreciationCertificateError(this.message);
  final String message;
  @override
  List<Object> get props => [message];
}

class AppreciationCertificateLoaded extends AppreciationCertificateState {
  const AppreciationCertificateLoaded({
    required this.students,
    required this.classes,
    required this.sections,
    required this.settings,
    required this.history,
    this.message,
  });
  final List<StudentEntity> students;
  final List<AcademicClassEntity> classes;
  final List<SectionEntity> sections;
  final SchoolSettingsEntity settings;
  final List<AppreciationCertificateEntity> history;
  final String? message;
  String get nextSerial {
    final year = DateTime.now().year;
    final used = history
        .where((e) => e.serialNumber.startsWith('APP-$year-'))
        .map((e) => int.tryParse(e.serialNumber.split('-').last) ?? 0)
        .fold<int>(0, (a, b) => a > b ? a : b);
    return 'APP-$year-${(used + 1).toString().padLeft(4, '0')}';
  }

  AppreciationCertificateLoaded copyWith({
    List<AppreciationCertificateEntity>? history,
    String? message,
  }) => AppreciationCertificateLoaded(
    students: students,
    classes: classes,
    sections: sections,
    settings: settings,
    history: history ?? this.history,
    message: message,
  );
  @override
  List<Object?> get props => [
    students,
    classes,
    sections,
    settings,
    history,
    message,
  ];
}

class AppreciationCertificateBloc
    extends Bloc<AppreciationCertificateEvent, AppreciationCertificateState> {
  AppreciationCertificateBloc(
    this._repository,
    this._students,
    this._structure,
    this._getSettings,
  ) : super(const AppreciationCertificateInitial()) {
    on<LoadAppreciationCertificates>(_load);
    on<SaveAppreciationCertificate>(_save);
  }
  final AppreciationCertificateRepository _repository;
  final StudentRepository _students;
  final AcademicStructureRepository _structure;
  final GetSchoolSettings _getSettings;
  Future<void> _load(
    LoadAppreciationCertificates event,
    Emitter<AppreciationCertificateState> emit,
  ) async {
    emit(const AppreciationCertificateLoading());
    try {
      final values = await Future.wait([
        _students.getStudents(),
        _structure.getClasses(),
        _structure.getSections(),
        _getSettings(),
        _repository.getCertificates(),
      ]);
      emit(
        AppreciationCertificateLoaded(
          students: (values[0] as List<StudentEntity>)
              .where((e) => e.isActive)
              .toList(),
          classes: values[1] as List<AcademicClassEntity>,
          sections: values[2] as List<SectionEntity>,
          settings: values[3] as SchoolSettingsEntity,
          history: values[4] as List<AppreciationCertificateEntity>,
        ),
      );
    } catch (e) {
      emit(
        AppreciationCertificateError(
          'Could not load appreciation certificates: $e',
        ),
      );
    }
  }

  Future<void> _save(
    SaveAppreciationCertificate event,
    Emitter<AppreciationCertificateState> emit,
  ) async {
    final s = state;
    if (s is! AppreciationCertificateLoaded) return;
    try {
      await _repository.saveCertificate(event.value);
      emit(
        s.copyWith(
          history: [
            event.value,
            ...s.history.where((e) => e.id != event.value.id),
          ],
          message: 'Appreciation certificate issued and saved.',
        ),
      );
    } catch (e) {
      emit(AppreciationCertificateError('Could not save certificate: $e'));
    }
  }
}
