import 'package:flutter/material.dart';

import '../../../../core/widgets/dashboard_navigation_button.dart';

const _pageBackground = Color(0xFFF5F7FA);
const _brandBlue = Color(0xFF0B63CE);
const _borderColor = Color(0xFFE1E6ED);
const _textPrimary = Color(0xFF182230);
const _textSecondary = Color(0xFF667085);

class AcademicSettingsPage extends StatefulWidget {
  const AcademicSettingsPage({super.key});

  @override
  State<AcademicSettingsPage> createState() =>
      _AcademicSettingsPageState();
}

class _AcademicSettingsPageState
    extends State<AcademicSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  final _sessionController = TextEditingController();

  DateTime _sessionStart = DateTime(2026, 4, 1);
  DateTime _sessionEnd = DateTime(2027, 3, 31);

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1000,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const _AcademicHeader(),
                    const SizedBox(height: 24),
                    _SettingsCard(
                      title: 'Academic Session',
                      subtitle:
                          'Configure the active school session and its date range.',
                      icon:
                          Icons.calendar_month_outlined,
                      child: Column(
                        children: [
                          TextFormField(
                            controller:
                                _sessionController,
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Current Session',
                              prefixIcon: Icon(
                                Icons.school_outlined,
                              ),
                              border:
                                  OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value
                                      .trim()
                                      .isEmpty) {
                                return 'Current session is required.';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          _DateTile(
                            label:
                                'Session Start Date',
                            value:
                                _sessionStart,
                            onChanged: (value) {
                              setState(() {
                                _sessionStart =
                                    value;
                              });
                            },
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          _DateTile(
                            label:
                                'Session End Date',
                            value: _sessionEnd,
                            onChanged: (value) {
                              setState(() {
                                _sessionEnd =
                                    value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style:
                          FilledButton.styleFrom(
                        backgroundColor:
                            _brandBlue,
                      ),
                      onPressed: _save,
                      icon: const Icon(
                        Icons.save_outlined,
                      ),
                      label: const Text(
                        'Save Academic Settings',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Academic Settings save will be connected after all Settings pages are ready.',
        ),
      ),
    );
  }
}

class _AcademicHeader
    extends StatelessWidget {
  const _AcademicHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        DashboardNavigationButton(),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Academic Settings',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight:
                      FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage the current academic session and session dates.',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime>
      onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(12),
      onTap: () async {
        final picked =
            await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );

        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(
            Icons.calendar_today_outlined,
          ),
          suffixIcon: const Icon(
            Icons.chevron_right,
          ),
          border:
              const OutlineInputBorder(),
        ),
        child: Text(
          '${value.day.toString().padLeft(2, '0')}-'
          '${value.month.toString().padLeft(2, '0')}-'
          '${value.year}',
        ),
      ),
    );
  }
}

class _SettingsCard
    extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: _borderColor,
        ),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration:
                    BoxDecoration(
                  color: _brandBlue
                      .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(12),
                ),
                child: Icon(
                  icon,
                  color: _brandBlue,
                ),
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        color:
                            _textPrimary,
                        fontSize: 18,
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        color:
                            _textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 22,
          ),
          child,
        ],
      ),
    );
  }
}
