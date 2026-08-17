import 'package:equatable/equatable.dart';
import '../../domain/entities/admission_test_entities.dart';

sealed class AdmissionTestEvent extends Equatable {
  const AdmissionTestEvent();
  @override
  List<Object?> get props => [];
}

class LoadAdmissionTests extends AdmissionTestEvent {
  const LoadAdmissionTests();
}

class SaveAdmissionQuestion extends AdmissionTestEvent {
  const SaveAdmissionQuestion(this.value);
  final AdmissionQuestionEntity value;
  @override
  List<Object> get props => [value];
}

class DeleteAdmissionQuestion extends AdmissionTestEvent {
  const DeleteAdmissionQuestion(this.id);
  final String id;
  @override
  List<Object> get props => [id];
}

class SaveAdmissionTemplate extends AdmissionTestEvent {
  const SaveAdmissionTemplate(this.value);
  final AdmissionPaperTemplateEntity value;
  @override
  List<Object> get props => [value];
}

class GenerateAdmissionPaper extends AdmissionTestEvent {
  const GenerateAdmissionPaper(
    this.template, {
    required this.title,
    this.variant = 'A',
  });
  final AdmissionPaperTemplateEntity template;
  final String title, variant;
  @override
  List<Object> get props => [template, title, variant];
}

class SaveCustomAdmissionPaper extends AdmissionTestEvent {
  const SaveCustomAdmissionPaper(this.value);
  final AdmissionPaperEntity value;
  @override
  List<Object> get props => [value];
}

class SaveAdmissionCandidate extends AdmissionTestEvent {
  const SaveAdmissionCandidate(this.value);
  final AdmissionCandidateEntity value;
  @override
  List<Object> get props => [value];
}
