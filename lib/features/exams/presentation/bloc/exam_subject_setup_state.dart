import 'package:equatable/equatable.dart';
import '../../domain/entities/exam_entity.dart';
import '../../domain/entities/exam_subject_setup_entity.dart';
sealed class ExamSubjectSetupState extends Equatable { const ExamSubjectSetupState(); @override List<Object?> get props=>[]; }
class ExamSubjectSetupInitial extends ExamSubjectSetupState { const ExamSubjectSetupInitial(); }
class ExamSubjectSetupLoading extends ExamSubjectSetupState { const ExamSubjectSetupLoading(); }
class ExamSubjectSetupLoaded extends ExamSubjectSetupState { const ExamSubjectSetupLoaded({required this.setups,required this.allSetups,required this.exams,required this.classes,required this.sectionsByClass,required this.subjectsByClassSection,this.query='',this.examId,this.classId,this.sectionId,this.successMessage}); final List<ExamSubjectSetupEntity> setups,allSetups; final List<ExamEntity> exams; final List<String> classes; final Map<String,List<String>> sectionsByClass,subjectsByClassSection; final String query; final String? examId,classId,sectionId,successMessage; List<String> sectionsFor(String value)=>sectionsByClass[value]??const []; List<String> subjectsFor(String classValue,String sectionValue)=>subjectsByClassSection['$classValue|$sectionValue']??const []; @override List<Object?> get props=>[setups,allSetups,exams,classes,sectionsByClass,subjectsByClassSection,query,examId,classId,sectionId,successMessage]; }
class ExamSubjectSetupError extends ExamSubjectSetupState { const ExamSubjectSetupError(this.message); final String message; @override List<Object?> get props=>[message]; }
