import 'package:equatable/equatable.dart';
import '../../domain/entities/exam_subject_setup_entity.dart';
sealed class ExamSubjectSetupEvent extends Equatable { const ExamSubjectSetupEvent(); @override List<Object?> get props=>[]; }
class LoadExamSubjectSetups extends ExamSubjectSetupEvent { const LoadExamSubjectSetups(); }
class RefreshExamSubjectSetups extends ExamSubjectSetupEvent { const RefreshExamSubjectSetups(); }
class CreateExamSubjectSetups extends ExamSubjectSetupEvent { const CreateExamSubjectSetups(this.setups); final List<ExamSubjectSetupEntity> setups; @override List<Object?> get props=>[setups]; }
class UpdateExamSubjectSetupEvent extends ExamSubjectSetupEvent { const UpdateExamSubjectSetupEvent(this.setup); final ExamSubjectSetupEntity setup; @override List<Object?> get props=>[setup]; }
class DeleteExamSubjectSetupEvent extends ExamSubjectSetupEvent { const DeleteExamSubjectSetupEvent(this.id); final String id; @override List<Object?> get props=>[id]; }
class FilterExamSubjectSetups extends ExamSubjectSetupEvent { const FilterExamSubjectSetups({this.query='',this.examId,this.classId,this.sectionId}); final String query; final String? examId,classId,sectionId; @override List<Object?> get props=>[query,examId,classId,sectionId]; }
