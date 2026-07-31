import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/academic_year_config_entity.dart';
import '../../domain/services/academic_calendar_policy_service.dart';

class AcademicCalendarIntegrationPage extends StatefulWidget {
  const AcademicCalendarIntegrationPage({
    super.key,
    this.academicSession = '2026-2027',
  });

  final String academicSession;

  @override
  State<AcademicCalendarIntegrationPage> createState() =>
      _AcademicCalendarIntegrationPageState();
}

class _AcademicCalendarIntegrationPageState
    extends State<AcademicCalendarIntegrationPage> {
  late final TextEditingController _sessionController;
  AcademicYearConfigEntity? _config;
  DateTime? _feeGenerationDate;
  DateTime? _feeDueDate;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sessionController = TextEditingController(text: widget.academicSession);
    _load();
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = sl<AcademicCalendarPolicyService>();
      final now = DateTime.now();
      final config = await service.getConfig(_sessionController.text.trim());

      if (config == null) {
        throw StateError('Academic Year Wizard configuration is missing.');
      }

      final generation = await service.resolveFeeGenerationDate(
        academicSession: config.academicSession,
        month: now.month,
        year: now.year,
      );
      final due = await service.resolveFeeDueDate(
        academicSession: config.academicSession,
        month: now.month,
        year: now.year,
      );

      if (!mounted) return;
      setState(() {
        _config = config;
        _feeGenerationDate = generation;
        _feeDueDate = due;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('StateError: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ERP Calendar Integration')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 190,
                          child: TextFormField(
                            controller: _sessionController,
                            decoration: const InputDecoration(
                              labelText: 'Academic Session',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reload'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _integrationCard(
                  icon: Icons.fact_check_outlined,
                  title: 'Attendance',
                  status: 'Connected',
                  description:
                      'Working-day, holiday and vacation validation is available.',
                ),
                _integrationCard(
                  icon: Icons.schedule_outlined,
                  title: 'Timetable',
                  status: 'Connected',
                  description:
                      'Saturday and zero-period rules are available to timetable generation.',
                ),
                _integrationCard(
                  icon: Icons.menu_book_outlined,
                  title: 'Homework',
                  status: 'Connected',
                  description:
                      'Holiday, vacation and allowed-weekday validation is available.',
                ),
                _integrationCard(
                  icon: Icons.quiz_outlined,
                  title: 'Exams & Date Sheets',
                  status: 'Connected',
                  description:
                      'Exam-window, holiday and vacation checks are available.',
                ),
                _integrationCard(
                  icon: Icons.payments_outlined,
                  title: 'Fee Management',
                  status: 'Connected',
                  description:
                      'Current resolved dates: generation ${_date(_feeGenerationDate!)}; due ${_date(_feeDueDate!)}.',
                ),
                _integrationCard(
                  icon: Icons.people_outline,
                  title: 'Parent & Teacher Portals',
                  status: 'Connected',
                  description:
                      'Audience-filtered calendar events are available through the policy service.',
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        Chip(
                          label: Text(
                            'Working Days: ${_config!.totalWorkingDays}',
                          ),
                        ),
                        Chip(
                          label: Text(
                            'Teaching Days: ${_config!.availableTeachingDays}',
                          ),
                        ),
                        Chip(
                          label: Text(
                            'Exam Windows: ${_config!.examWindows.length}',
                          ),
                        ),
                        Chip(
                          label: Text(
                            'Vacations: ${_config!.vacations.length}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _integrationCard({
    required IconData icon,
    required String title,
    required String status,
    required String description,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(description),
        trailing: Chip(label: Text(status)),
      ),
    );
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}
