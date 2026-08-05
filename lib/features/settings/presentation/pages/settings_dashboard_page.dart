import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../domain/entities/school_settings_entity.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import 'backup_restore_page.dart';
import 'user_preferences_page.dart';
import 'security_sessions_page.dart';
import 'system_health_page.dart';
import '../../../../core/audit/presentation/pages/audit_configuration_page.dart';

class SettingsDashboardPage extends StatelessWidget {
  const SettingsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SettingsBloc>()..add(const LoadSettings()),
      child: const _SettingsDashboardView(),
    );
  }
}

class _SettingsDashboardView extends StatefulWidget {
  const _SettingsDashboardView();

  @override
  State<_SettingsDashboardView> createState() => _SettingsDashboardViewState();
}

class _SettingsDashboardViewState extends State<_SettingsDashboardView> {
  final _formKey = GlobalKey<FormState>();

  final _schoolName = TextEditingController();
  final _schoolCode = TextEditingController();
  final _session = TextEditingController();
  final _tagLine = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  final _phone = TextEditingController();
  final _whatsApp = TextEditingController();
  final _email = TextEditingController();
  final _website = TextEditingController();
  final _admissionPrefix = TextEditingController();
  final _rollPrefix = TextEditingController();
  final _receiptPrefix = TextEditingController();
  final _logoUrl = TextEditingController();
  final _headerUrl = TextEditingController();
  final _footerUrl = TextEditingController();

  DateTime _sessionStart = DateTime(2026, 4, 1);
  DateTime _sessionEnd = DateTime(2027, 3, 31);
  String _currency = 'PKR';
  String _currencySymbol = 'Rs.';
  String _dateFormat = 'dd-MM-yyyy';
  String _timeFormat = '12 Hour';
  bool _initialized = false;

  @override
  void dispose() {
    _schoolName.dispose();
    _schoolCode.dispose();
    _session.dispose();
    _tagLine.dispose();
    _address.dispose();
    _city.dispose();
    _country.dispose();
    _phone.dispose();
    _whatsApp.dispose();
    _email.dispose();
    _website.dispose();
    _admissionPrefix.dispose();
    _rollPrefix.dispose();
    _receiptPrefix.dispose();
    _logoUrl.dispose();
    _headerUrl.dispose();
    _footerUrl.dispose();
    super.dispose();
  }

  void _fill(SchoolSettingsEntity value) {
    if (_initialized) return;

    _schoolName.text = value.schoolName;
    _schoolCode.text = value.schoolCode;
    _session.text = value.currentSession;
    _tagLine.text = value.tagLine;
    _address.text = value.address;
    _city.text = value.city;
    _country.text = value.country;
    _phone.text = value.phone;
    _whatsApp.text = value.whatsApp;
    _email.text = value.email;
    _website.text = value.website;
    _admissionPrefix.text = value.admissionPrefix;
    _rollPrefix.text = value.rollNumberPrefix;
    _receiptPrefix.text = value.receiptPrefix;
    _logoUrl.text = value.logoUrl;
    _headerUrl.text = value.reportHeaderUrl;
    _footerUrl.text = value.reportFooterUrl;
    _sessionStart = value.sessionStartDate;
    _sessionEnd = value.sessionEndDate;
    _currency = value.currency;
    _currencySymbol = value.currencySymbol;
    _dateFormat = value.dateFormat;
    _timeFormat = value.timeFormat;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsLoaded && state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          if (state is SettingsInitial || state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SettingsFailure) {
            return Center(child: Text(state.message));
          }

          final loaded = state as SettingsLoaded;
          _fill(loaded.settings);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _section(
                  context,
                  title: 'School Profile',
                  children: [
                    _field(_schoolName, 'School Name', required: true),
                    _field(_schoolCode, 'School Code', required: true),
                    _field(_tagLine, 'Tag Line'),
                    _field(_address, 'Address'),
                    _field(_city, 'City'),
                    _field(_country, 'Country'),
                    _field(_phone, 'Phone'),
                    _field(_whatsApp, 'WhatsApp'),
                    _field(_email, 'Email'),
                    _field(_website, 'Website'),
                  ],
                ),
                const SizedBox(height: 14),
                _section(
                  context,
                  title: 'Academic Settings',
                  children: [
                    _field(_session, 'Current Session', required: true),
                    _dateTile(context, 'Session Start Date', _sessionStart, (
                      value,
                    ) {
                      setState(() => _sessionStart = value);
                    }),
                    _dateTile(context, 'Session End Date', _sessionEnd, (
                      value,
                    ) {
                      setState(() => _sessionEnd = value);
                    }),
                  ],
                ),
                const SizedBox(height: 14),
                _section(
                  context,
                  title: 'Regional Settings',
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      items: const [
                        DropdownMenuItem(value: 'PKR', child: Text('PKR')),
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _currency = value);
                        }
                      },
                    ),
                    _field(
                      null,
                      'Currency Symbol',
                      externalValue: _currencySymbol,
                      onChanged: (value) {
                        _currencySymbol = value;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _dateFormat,
                      decoration: const InputDecoration(
                        labelText: 'Date Format',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'dd-MM-yyyy',
                          child: Text('dd-MM-yyyy'),
                        ),
                        DropdownMenuItem(
                          value: 'dd/MM/yyyy',
                          child: Text('dd/MM/yyyy'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _dateFormat = value);
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _timeFormat,
                      decoration: const InputDecoration(
                        labelText: 'Time Format',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: '12 Hour',
                          child: Text('12 Hour'),
                        ),
                        DropdownMenuItem(
                          value: '24 Hour',
                          child: Text('24 Hour'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _timeFormat = value);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _section(
                  context,
                  title: 'System Prefixes',
                  children: [
                    _field(_admissionPrefix, 'Admission Prefix'),
                    _field(_rollPrefix, 'Roll Number Prefix'),
                    _field(_receiptPrefix, 'Receipt Prefix'),
                  ],
                ),
                const SizedBox(height: 14),
                _section(
                  context,
                  title: 'Branding',
                  children: [
                    _field(_logoUrl, 'School Logo URL'),
                    _field(_headerUrl, 'Report Header URL'),
                    _field(_footerUrl, 'Report Footer URL'),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const BackupRestorePage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.backup_outlined),
                    label: const Text('Backup and Restore'),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const UserPreferencesPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.tune_outlined),
                    label: const Text('User Preferences'),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SecuritySessionsPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.security_outlined),
                    label: const Text('Security and Sessions'),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SystemHealthPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.monitor_heart_outlined),
                    label: const Text('System Health and Diagnostics'),
                  ),
const SizedBox(height: 10),
Align(
  alignment: Alignment.centerLeft,
  child: FilledButton.tonalIcon(
    onPressed: () {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const AuditConfigurationPage(),
        ),
      );
    },
    icon: const Icon(Icons.history_outlined),
    label: const Text('Audit Logging'),
  ),
),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: loaded.isSaving
                        ? null
                        : () => _save(context, loaded.settings.id),
                    icon: loaded.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save Settings'),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 800
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: children
                      .map((child) => SizedBox(width: width, child: child))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController? controller,
    String label, {
    bool required = false,
    String? externalValue,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? externalValue : null,
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required.';
              }
              return null;
            }
          : null,
    );
  }

  Widget _dateTile(
    BuildContext context,
    String label,
    DateTime value,
    ValueChanged<DateTime> onChanged,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        '${value.day.toString().padLeft(2, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.year}',
      ),
      trailing: const Icon(Icons.calendar_month_outlined),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );

        if (picked != null) {
          onChanged(picked);
        }
      },
    );
  }

  void _save(BuildContext context, String id) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<SettingsBloc>().add(
      SaveSettingsRequested(
        SchoolSettingsEntity(
          id: id,
          schoolName: _schoolName.text.trim(),
          schoolCode: _schoolCode.text.trim(),
          currentSession: _session.text.trim(),
          sessionStartDate: _sessionStart,
          sessionEndDate: _sessionEnd,
          currency: _currency,
          currencySymbol: _currencySymbol.trim(),
          dateFormat: _dateFormat,
          timeFormat: _timeFormat,
          admissionPrefix: _admissionPrefix.text.trim(),
          rollNumberPrefix: _rollPrefix.text.trim(),
          receiptPrefix: _receiptPrefix.text.trim(),
          updatedAt: DateTime.now(),
          tagLine: _tagLine.text.trim(),
          address: _address.text.trim(),
          city: _city.text.trim(),
          country: _country.text.trim(),
          phone: _phone.text.trim(),
          whatsApp: _whatsApp.text.trim(),
          email: _email.text.trim(),
          website: _website.text.trim(),
          logoUrl: _logoUrl.text.trim(),
          reportHeaderUrl: _headerUrl.text.trim(),
          reportFooterUrl: _footerUrl.text.trim(),
        ),
      ),
    );
  }
}
