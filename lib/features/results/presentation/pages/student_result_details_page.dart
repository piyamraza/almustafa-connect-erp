import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../../exams/presentation/widgets/result_status_chip.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../bloc/result_details_bloc.dart';
import '../bloc/result_details_event.dart';
import '../bloc/result_details_state.dart';

class StudentResultDetailsPage extends StatelessWidget {
  const StudentResultDetailsPage({required this.result, super.key});

  final ExamResultEntity result;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ResultDetailsBloc>()..add(LoadResultDetails(result)),
      child: const _StudentResultDetailsView(),
    );
  }
}

class _StudentResultDetailsView extends StatelessWidget {
  const _StudentResultDetailsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Result')),
      body: BlocBuilder<ResultDetailsBloc, ResultDetailsState>(
        builder: (context, state) {
          return switch (state) {
            ResultDetailsInitial() =>
              const Center(child: CircularProgressIndicator()),
            ResultDetailsLoading(:final result) => _DetailsContent(
                result: result,
                isLoadingStudent: true,
              ),
            ResultDetailsLoaded(:final result, :final student) => _DetailsContent(
                result: result,
                student: student,
              ),
            ResultDetailsFailure(:final result, :final message) => _DetailsContent(
                result: result,
                studentLoadError: message,
              ),
          };
        },
      ),
    );
  }
}

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({
    required this.result,
    this.student,
    this.isLoadingStudent = false,
    this.studentLoadError,
  });

  final ExamResultEntity result;
  final StudentEntity? student;
  final bool isLoadingStudent;
  final String? studentLoadError;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLoadingStudent) const LinearProgressIndicator(),
                if (studentLoadError != null) ...[
                  _ReadOnlyNotice(message: 'Student profile details are unavailable: $studentLoadError'),
                  const SizedBox(height: 12),
                ],
                _StudentHeader(result: result, student: student),
                const SizedBox(height: 16),
                _ResultInformation(result: result),
                const SizedBox(height: 16),
                _SubjectMarksTable(subjects: result.subjectResults),
                const SizedBox(height: 16),
                _RemarksCard(result: result),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentHeader extends StatelessWidget {
  const _StudentHeader({required this.result, required this.student});

  final ExamResultEntity result;
  final StudentEntity? student;

  @override
  Widget build(BuildContext context) {
    final photoUrl = student?.profileImageUrl.trim() ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final details = _StudentIdentity(result: result, student: student);
            if (constraints.maxWidth < 620) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StudentPhoto(url: photoUrl, name: result.studentName),
                  const SizedBox(height: 16),
                  details,
                ],
              );
            }
            return Row(
              children: [
                _StudentPhoto(url: photoUrl, name: result.studentName),
                const SizedBox(width: 20),
                Expanded(child: details),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StudentPhoto extends StatelessWidget {
  const _StudentPhoto({required this.url, required this.name});

  final String url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: 44,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      backgroundImage: url.isEmpty ? null : NetworkImage(url),
      onBackgroundImageError: url.isEmpty ? null : (_, _) {},
      child: url.isEmpty
          ? Text(initial, style: Theme.of(context).textTheme.headlineSmall)
          : null,
    );
  }
}

class _StudentIdentity extends StatelessWidget {
  const _StudentIdentity({required this.result, required this.student});

  final ExamResultEntity result;
  final StudentEntity? student;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          result.studentName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 20,
          runSpacing: 10,
          children: [
            _KeyValue(label: 'Admission No', value: _display(result.admissionNo)),
            _KeyValue(label: 'Roll No', value: _display(result.rollNumber)),
            _KeyValue(label: 'Father Name', value: _display(student?.fatherName ?? '')),
            _KeyValue(label: 'Class', value: _display(result.className)),
            _KeyValue(label: 'Section', value: _display(result.sectionName)),
          ],
        ),
      ],
    );
  }
}

class _ResultInformation extends StatelessWidget {
  const _ResultInformation({required this.result});

  final ExamResultEntity result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Published Result Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                ResultStatusChip(status: result.status),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 14,
              children: [
                _KeyValue(label: 'Exam', value: result.examName),
                _KeyValue(label: 'Academic Session', value: _display(result.academicSession)),
                _KeyValue(label: 'Total Marks', value: _number(result.grandTotalMarks)),
                _KeyValue(label: 'Obtained Marks', value: _number(result.grandObtainedMarks)),
                _KeyValue(label: 'Percentage', value: _percentage(result.percentage)),
                _KeyValue(label: 'Grade', value: result.grade),
                _KeyValue(label: 'Section Position', value: '${result.sectionPosition}'),
                _KeyValue(label: 'Class Position', value: '${result.classPosition}'),
                _KeyValue(label: 'Overall Position', value: '${result.overallRank}'),
                _KeyValue(label: 'Result', value: result.isPassed ? 'Pass' : 'Fail'),
                _KeyValue(
                  label: 'Published Date',
                  value: _date(result.publishedAt ?? result.updatedAt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectMarksTable extends StatelessWidget {
  const _SubjectMarksTable({required this.subjects});

  final List<SubjectResultEntity> subjects;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subject-wise Marks', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (subjects.isEmpty)
              const Text('No subject details are available for this published result.')
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Subject')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Obtained')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Teacher Remarks')),
                  ],
                  rows: subjects
                      .map(
                        (subject) => DataRow(
                          cells: [
                            DataCell(Text(subject.subjectName)),
                            DataCell(Text(_number(subject.totalMarks))),
                            DataCell(Text(_number(subject.obtainedMarks))),
                            DataCell(Text(subject.isPassed ? 'Pass' : 'Fail')),
                            DataCell(Text(_display(subject.remarks))),
                          ],
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RemarksCard extends StatelessWidget {
  const _RemarksCard({required this.result});

  final ExamResultEntity result;

  @override
  Widget build(BuildContext context) {
    final teacherRemarks = result.subjectResults
        .where((subject) => subject.remarks.trim().isNotEmpty)
        .map((subject) => '${subject.subjectName}: ${subject.remarks.trim()}')
        .join('\n');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Remarks', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _RemarkRow(label: 'Teacher Remarks', value: _display(teacherRemarks)),
            const SizedBox(height: 12),
            _RemarkRow(label: 'Principal Remarks', value: _display(result.principalRemarks)),
            const SizedBox(height: 12),
            const _ReadOnlyNotice(message: 'This published result is read-only.'),
          ],
        ),
      ),
    );
  }
}

class _RemarkRow extends StatelessWidget {
  const _RemarkRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }
}

class _ReadOnlyNotice extends StatelessWidget {
  const _ReadOnlyNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.visibility_outlined, color: colors.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

String _display(String value) => value.trim().isEmpty ? 'Not available' : value;
String _number(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
String _percentage(double value) => '${value.toStringAsFixed(1)}%';
String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
