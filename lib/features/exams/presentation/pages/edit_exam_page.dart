import 'package:flutter/material.dart';

import '../../domain/entities/exam_entity.dart';
import 'exam_form_page.dart';

class EditExamPage extends StatelessWidget {
  const EditExamPage({super.key, required this.exam});

  final ExamEntity exam;

  @override
  Widget build(BuildContext context) => ExamFormPage(exam: exam);
}
