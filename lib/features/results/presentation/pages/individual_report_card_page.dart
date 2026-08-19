import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../documents/presentation/pages/merit_certificate_preview_page.dart';
import '../../../documents/presentation/pages/result_card_preview_page.dart';
import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../../exams/presentation/widgets/result_status_chip.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/result_export_request.dart';
import '../../domain/entities/student_development_profile_entity.dart';
import '../../domain/services/result_card_insight_service.dart';
import '../bloc/report_card_bloc.dart';
import '../bloc/report_card_event.dart';
import '../bloc/report_card_state.dart';
import '../widgets/results_export_actions.dart';
import '../widgets/grouped_subject_results_table.dart';

class IndividualReportCardPage extends StatelessWidget {
  const IndividualReportCardPage({required this.result, super.key});

  final ExamResultEntity result;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReportCardBloc>()..add(LoadReportCard(result)),
      child: const _IndividualReportCardView(),
    );
  }
}

class _IndividualReportCardView extends StatelessWidget {
  const _IndividualReportCardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [DashboardNavigationButton()],
        title: const Text('Individual Report Card'),
      ),
      body: BlocBuilder<ReportCardBloc, ReportCardState>(
        builder: (context, state) {
          return switch (state) {
            ReportCardInitial() => const Center(
              child: CircularProgressIndicator(),
            ),
            ReportCardLoading(:final result) => _ReportCardContent(
              result: result,
              isLoading: true,
            ),
            ReportCardLoaded(
              :final result,
              :final student,
              :final attendancePercentage,
              :final attendanceDays,
              :final attendedDays,
              :final punctualityRating,
              :final developmentProfile,
              :final classAverage,
              :final highestPercentage,
              :final termProgress,
            ) =>
              _ReportCardContent(
                result: result,
                student: student,
                attendancePercentage: attendancePercentage,
                attendanceDays: attendanceDays,
                attendedDays: attendedDays,
                punctualityRating: punctualityRating,
                developmentProfile: developmentProfile,
                classAverage: classAverage,
                highestPercentage: highestPercentage,
                termProgress: termProgress,
              ),
            ReportCardFailure(:final result, :final message) =>
              _ReportCardContent(result: result, loadMessage: message),
          };
        },
      ),
    );
  }
}

class _ReportCardContent extends StatelessWidget {
  const _ReportCardContent({
    required this.result,
    this.student,
    this.attendancePercentage,
    this.attendanceDays = 0,
    this.attendedDays = 0,
    this.punctualityRating = 0,
    this.developmentProfile,
    this.classAverage,
    this.highestPercentage,
    this.termProgress = const [],
    this.isLoading = false,
    this.loadMessage,
  });

  final ExamResultEntity result;
  final StudentEntity? student;
  final double? attendancePercentage;
  final int attendanceDays;
  final int attendedDays;
  final int punctualityRating;
  final StudentDevelopmentProfileEntity? developmentProfile;
  final double? classAverage;
  final double? highestPercentage;
  final List<String> termProgress;
  final bool isLoading;
  final String? loadMessage;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              children: [
                if (isLoading) const LinearProgressIndicator(),
                if (loadMessage != null) ...[
                  _InformationBanner(message: loadMessage!),
                  const SizedBox(height: 12),
                ],

                _DocumentActions(
                  result: result,
                  student: student,
                  attendancePercentage: attendancePercentage,
                  attendanceDays: attendanceDays,
                  attendedDays: attendedDays,
                  punctualityRating: punctualityRating,
                  developmentProfile: developmentProfile,
                  classAverage: classAverage,
                  highestPercentage: highestPercentage,
                  termProgress: termProgress,
                ),

                const SizedBox(height: 16),

                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _SchoolHeader(result: result),
                        const Divider(height: 32),
                        _StudentInformation(result: result, student: student),
                        const SizedBox(height: 24),
                        _SubjectMarksTable(subjects: result.subjectResults),
                        const SizedBox(height: 20),
                        _ResultSummary(
                          result: result,
                          attendancePercentage: attendancePercentage,
                        ),
                        const SizedBox(height: 20),
                        _DevelopmentProfile(
                          profile: developmentProfile,
                          punctualityRating: punctualityRating,
                        ),
                        const SizedBox(height: 20),
                        _PerformanceComparison(
                          studentPercentage: result.percentage,
                          classAverage: classAverage,
                          highestPercentage: highestPercentage,
                          termProgress: termProgress,
                        ),
                        const SizedBox(height: 20),
                        _Remarks(result: result),
                        const SizedBox(height: 20),
                        const _InformationBanner(
                          message: 'Published result — read-only record.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentActions extends StatelessWidget {
  const _DocumentActions({
    required this.result,
    required this.student,
    required this.attendancePercentage,
    required this.attendanceDays,
    required this.attendedDays,
    required this.punctualityRating,
    required this.developmentProfile,
    required this.classAverage,
    required this.highestPercentage,
    required this.termProgress,
  });

  final ExamResultEntity result;
  final StudentEntity? student;
  final double? attendancePercentage;
  final int attendanceDays;
  final int attendedDays;
  final int punctualityRating;
  final StudentDevelopmentProfileEntity? developmentProfile;
  final double? classAverage;
  final double? highestPercentage;
  final List<String> termProgress;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: () => _openResultCard(context),
            icon: const Icon(Icons.assessment_outlined),
            label: const Text('Result Card'),
          ),

          OutlinedButton.icon(
            onPressed: () => _openMeritCertificate(context),
            icon: const Icon(Icons.workspace_premium_outlined),
            label: const Text('Merit Certificate'),
          ),

          ResultsExportActions(
            request: ResultExportRequest(
              type: ResultExportType.reportCard,
              title: 'Student Report Card',
              results: [result],
              student: student,
              attendancePercentage: attendancePercentage,
              filters: {
                'Academic Session': result.academicSession,
                'Exam': result.examName,
                'Class': result.className,
                'Section': result.sectionName,
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openResultCard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultCardPreviewPage(
          result: result,
          student: student,
          attendancePercentage: attendancePercentage,
          attendanceDays: attendanceDays,
          attendedDays: attendedDays,
          punctualityRating: punctualityRating,
          developmentProfile: developmentProfile,
          classAverage: classAverage,
          highestPercentage: highestPercentage,
          termProgress: termProgress,
        ),
      ),
    );
  }

  void _openMeritCertificate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MeritCertificatePreviewPage(result: result),
      ),
    );
  }
}

class _SchoolHeader extends StatelessWidget {
  const _SchoolHeader({required this.result});

  final ExamResultEntity result;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/images/logo.jpeg',
            width: 68,
            height: 68,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 68,
              height: 68,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.school_outlined,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Almustafa Model School',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'VIP Colony, Suraj Miani, Multan',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 7),
              Text(
                'STUDENT REPORT CARD',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        ResultStatusChip(status: result.status),
      ],
    );
  }
}

class _StudentInformation extends StatelessWidget {
  const _StudentInformation({required this.result, required this.student});

  final ExamResultEntity result;
  final StudentEntity? student;

  @override
  Widget build(BuildContext context) {
    final photoUrl = student?.profileImageUrl.trim() ?? '';

    final initial = result.studentName.trim().isEmpty
        ? '?'
        : result.studentName.trim()[0].toUpperCase();

    final information = Wrap(
      spacing: 28,
      runSpacing: 14,
      children: [
        _Field(label: 'Student Name', value: result.studentName),
        _Field(label: 'Father Name', value: _value(student?.fatherName)),
        _Field(label: 'Admission No', value: _value(result.admissionNo)),
        _Field(label: 'Roll No', value: _value(result.rollNumber)),
        _Field(label: 'Class', value: _value(result.className)),
        _Field(label: 'Section', value: _value(result.sectionName)),
        _Field(
          label: 'Academic Session',
          value: _value(result.academicSession),
        ),
        _Field(label: 'Exam', value: _value(result.examName)),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final photo = CircleAvatar(
          radius: 42,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          backgroundImage: photoUrl.isEmpty ? null : NetworkImage(photoUrl),
          onBackgroundImageError: photoUrl.isEmpty ? null : (_, _) {},
          child: photoUrl.isEmpty
              ? Text(initial, style: Theme.of(context).textTheme.headlineSmall)
              : null,
        );

        if (constraints.maxWidth < 660) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [photo, const SizedBox(height: 16), information],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            photo,
            const SizedBox(width: 22),
            Expanded(child: information),
          ],
        );
      },
    );
  }
}

class _SubjectMarksTable extends StatelessWidget {
  const _SubjectMarksTable({required this.subjects});

  final List<SubjectResultEntity> subjects;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject-wise Marks',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        GroupedSubjectResultsTable(subjects: subjects),
      ],
    );
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({
    required this.result,
    required this.attendancePercentage,
  });

  final ExamResultEntity result;
  final double? attendancePercentage;

  @override
  Widget build(BuildContext context) {
    final fields = [
      _Field(label: 'Total Marks', value: _number(result.grandTotalMarks)),
      _Field(
        label: 'Obtained Marks',
        value: _number(result.grandObtainedMarks),
      ),
      _Field(
        label: 'Percentage',
        value: '${result.percentage.toStringAsFixed(1)}%',
      ),
      _Field(label: 'Grade', value: result.grade),
      _Field(label: 'Position', value: '${result.sectionPosition}'),
      _Field(label: 'Result', value: result.isPassed ? 'Pass' : 'Fail'),
      if (attendancePercentage != null)
        _Field(
          label: 'Attendance Percentage',
          value: '${attendancePercentage!.toStringAsFixed(1)}%',
        ),
      _Field(
        label: 'Published Date',
        value: _date(result.publishedAt ?? result.updatedAt),
      ),
      _Field(label: 'Result Status', value: result.status.name.toUpperCase()),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(spacing: 28, runSpacing: 14, children: fields),
    );
  }
}

class _Remarks extends StatelessWidget {
  const _Remarks({required this.result});

  final ExamResultEntity result;

  @override
  Widget build(BuildContext context) {
    final teacherRemarks = const ResultCardInsightService().teacherRemark(
      result,
    );

    return Wrap(
      spacing: 28,
      runSpacing: 16,
      children: [
        _Field(
          label: 'Teacher Remarks',
          value: _value(teacherRemarks),
          wide: true,
        ),
        if (result.principalRemarks.trim().isNotEmpty)
          _Field(
            label: 'Principal Remarks',
            value: result.principalRemarks.trim(),
            wide: true,
          ),
      ],
    );
  }
}

class _DevelopmentProfile extends StatelessWidget {
  const _DevelopmentProfile({
    required this.profile,
    required this.punctualityRating,
  });
  final StudentDevelopmentProfileEntity? profile;
  final int punctualityRating;

  @override
  Widget build(BuildContext context) {
    final profile = this.profile;
    if (profile == null && punctualityRating == 0) {
      return const SizedBox.shrink();
    }
    final values = <(String, int)>[
      ('Discipline', profile?.discipline ?? 0),
      ('Punctuality', punctualityRating),
      ('Communication', profile?.communication ?? 0),
      ('Class Participation', profile?.classParticipation ?? 0),
      ('Homework', profile?.homework ?? 0),
      ('Personal Hygiene', profile?.personalHygiene ?? 0),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Student Development Profile',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: values
              .map(
                (item) => Container(
                  width: 250,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(item.$1)),
                      Text(
                        item.$2 <= 0
                            ? 'Not rated'
                            : '${'★' * item.$2}${'☆' * (5 - item.$2)}',
                        style: TextStyle(
                          color: item.$2 <= 0 ? null : const Color(0xFFF59E0B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _PerformanceComparison extends StatelessWidget {
  const _PerformanceComparison({
    required this.studentPercentage,
    required this.classAverage,
    required this.highestPercentage,
    required this.termProgress,
  });
  final double studentPercentage;
  final double? classAverage;
  final double? highestPercentage;
  final List<String> termProgress;

  @override
  Widget build(BuildContext context) {
    if (classAverage == null &&
        highestPercentage == null &&
        termProgress.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Comparison',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              Text('Student: ${studentPercentage.toStringAsFixed(1)}%'),
              if (classAverage != null)
                Text('Class Average: ${classAverage!.toStringAsFixed(1)}%'),
              if (highestPercentage != null)
                Text('Highest: ${highestPercentage!.toStringAsFixed(1)}%'),
            ],
          ),
          if (termProgress.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Term Progress: ${termProgress.join('  →  ')}'),
          ],
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value, this.wide = false});

  final String label;
  final String value;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: wide
          ? const BoxConstraints(maxWidth: 420)
          : const BoxConstraints(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 3),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InformationBanner extends StatelessWidget {
  const _InformationBanner({required this.message});

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

String _value(String? value) {
  return value == null || value.trim().isEmpty ? 'Not available' : value;
}

String _number(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}

String _date(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
