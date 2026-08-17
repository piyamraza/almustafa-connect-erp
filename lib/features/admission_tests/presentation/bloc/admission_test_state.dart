import 'package:equatable/equatable.dart';
import '../../domain/entities/admission_test_entities.dart';

sealed class AdmissionTestState extends Equatable {
  const AdmissionTestState();
  @override
  List<Object?> get props => [];
}

class AdmissionTestInitial extends AdmissionTestState {
  const AdmissionTestInitial();
}

class AdmissionTestLoading extends AdmissionTestState {
  const AdmissionTestLoading();
}

class AdmissionTestError extends AdmissionTestState {
  const AdmissionTestError(this.message);
  final String message;
  @override
  List<Object> get props => [message];
}

class AdmissionTestLoaded extends AdmissionTestState {
  const AdmissionTestLoaded({
    required this.questions,
    required this.templates,
    required this.papers,
    required this.candidates,
    this.preview,
    this.message,
  });
  final List<AdmissionQuestionEntity> questions;
  final List<AdmissionPaperTemplateEntity> templates;
  final List<AdmissionPaperEntity> papers;
  final List<AdmissionCandidateEntity> candidates;
  final AdmissionPaperEntity? preview;
  final String? message;
  AdmissionTestLoaded copyWith({
    List<AdmissionQuestionEntity>? questions,
    List<AdmissionPaperTemplateEntity>? templates,
    List<AdmissionPaperEntity>? papers,
    List<AdmissionCandidateEntity>? candidates,
    AdmissionPaperEntity? preview,
    String? message,
  }) => AdmissionTestLoaded(
    questions: questions ?? this.questions,
    templates: templates ?? this.templates,
    papers: papers ?? this.papers,
    candidates: candidates ?? this.candidates,
    preview: preview ?? this.preview,
    message: message,
  );
  @override
  List<Object?> get props => [
    questions,
    templates,
    papers,
    candidates,
    preview,
    message,
  ];
}
