import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../authentication/domain/usecases/get_current_user_usecase.dart';
import '../../domain/entities/user_preferences_entity.dart';
import '../bloc/user_preferences_bloc.dart';
import '../bloc/user_preferences_event.dart';
import '../bloc/user_preferences_state.dart';

class UserPreferencesPage extends StatelessWidget {
  const UserPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = sl<GetCurrentUserUseCase>()()?.uid ?? '';

    return BlocProvider(
      create: (_) =>
          sl<UserPreferencesBloc>()..add(LoadUserPreferences(userId)),
      child: const _UserPreferencesView(),
    );
  }
}

class _UserPreferencesView extends StatefulWidget {
  const _UserPreferencesView();

  @override
  State<_UserPreferencesView> createState() => _UserPreferencesViewState();
}

class _UserPreferencesViewState extends State<_UserPreferencesView> {
  bool _initialized = false;

  AppThemePreference _theme = AppThemePreference.system;
  String _landingPage = 'dashboard';
  bool _rememberLastScreen = true;
  bool _pushNotifications = true;
  bool _homeworkNotifications = true;
  bool _attendanceNotifications = true;
  bool _feeNotifications = true;
  bool _examNotifications = true;
  String _paperSize = 'A4';
  String _receiptFormat = 'Standard';
  String _resultCardFormat = 'Standard';
  String _language = 'English';

  void _fill(UserPreferencesEntity preferences) {
    if (_initialized) return;

    _theme = preferences.theme;
    _landingPage = preferences.defaultLandingPage;
    _rememberLastScreen = preferences.rememberLastScreen;
    _pushNotifications = preferences.pushNotifications;
    _homeworkNotifications = preferences.homeworkNotifications;
    _attendanceNotifications = preferences.attendanceNotifications;
    _feeNotifications = preferences.feeNotifications;
    _examNotifications = preferences.examNotifications;
    _paperSize = preferences.paperSize;
    _receiptFormat = preferences.receiptFormat;
    _resultCardFormat = preferences.resultCardFormat;
    _language = preferences.language;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Preferences'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocConsumer<UserPreferencesBloc, UserPreferencesState>(
        listener: (context, state) {
          if (state is UserPreferencesLoaded && state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          if (state is UserPreferencesInitial ||
              state is UserPreferencesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is UserPreferencesFailure) {
            return Center(child: Text(state.message));
          }

          final loaded = state as UserPreferencesLoaded;
          _fill(loaded.preferences);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _section(
                context,
                title: 'Appearance',
                children: [
                  DropdownButtonFormField<AppThemePreference>(
                    initialValue: _theme,
                    decoration: const InputDecoration(labelText: 'Theme'),
                    items: AppThemePreference.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _theme = value);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _section(
                context,
                title: 'Dashboard',
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _landingPage,
                    decoration: const InputDecoration(
                      labelText: 'Default Landing Page',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'dashboard',
                        child: Text('Dashboard'),
                      ),
                      DropdownMenuItem(
                        value: 'students',
                        child: Text('Students'),
                      ),
                      DropdownMenuItem(
                        value: 'attendance',
                        child: Text('Attendance'),
                      ),
                      DropdownMenuItem(
                        value: 'fees',
                        child: Text('Fee Management'),
                      ),
                      DropdownMenuItem(
                        value: 'accounts',
                        child: Text('Accounts'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _landingPage = value);
                      }
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Remember Last Open Screen'),
                    value: _rememberLastScreen,
                    onChanged: (value) {
                      setState(() => _rememberLastScreen = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _section(
                context,
                title: 'Notifications',
                children: [
                  _switch(
                    'Push Notifications',
                    _pushNotifications,
                    (value) => _pushNotifications = value,
                  ),
                  _switch(
                    'Homework Notifications',
                    _homeworkNotifications,
                    (value) => _homeworkNotifications = value,
                  ),
                  _switch(
                    'Attendance Notifications',
                    _attendanceNotifications,
                    (value) => _attendanceNotifications = value,
                  ),
                  _switch(
                    'Fee Reminder Notifications',
                    _feeNotifications,
                    (value) => _feeNotifications = value,
                  ),
                  _switch(
                    'Exam Notifications',
                    _examNotifications,
                    (value) => _examNotifications = value,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _section(
                context,
                title: 'Printing',
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _paperSize,
                    decoration: const InputDecoration(
                      labelText: 'Default Paper Size',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'A4', child: Text('A4')),
                      DropdownMenuItem(value: 'A5', child: Text('A5')),
                      DropdownMenuItem(value: 'Letter', child: Text('Letter')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _paperSize = value);
                      }
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _receiptFormat,
                    decoration: const InputDecoration(
                      labelText: 'Receipt Format',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Standard',
                        child: Text('Standard'),
                      ),
                      DropdownMenuItem(
                        value: 'Compact',
                        child: Text('Compact'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _receiptFormat = value);
                      }
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _resultCardFormat,
                    decoration: const InputDecoration(
                      labelText: 'Result Card Format',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Standard',
                        child: Text('Standard'),
                      ),
                      DropdownMenuItem(
                        value: 'Detailed',
                        child: Text('Detailed'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _resultCardFormat = value);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _section(
                context,
                title: 'General',
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _language,
                    decoration: const InputDecoration(labelText: 'Language'),
                    items: const [
                      DropdownMenuItem(
                        value: 'English',
                        child: Text('English'),
                      ),
                      DropdownMenuItem(
                        value: 'Urdu',
                        child: Text('Urdu - Future Ready'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _language = value);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: loaded.isSaving
                      ? null
                      : () => _save(context, loaded.preferences),
                  icon: loaded.isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save Preferences'),
                ),
              ),
            ],
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
            ...children.map(
              (child) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switch(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: (newValue) {
        setState(() => onChanged(newValue));
      },
    );
  }

  void _save(BuildContext context, UserPreferencesEntity current) {
    context.read<UserPreferencesBloc>().add(
      SaveUserPreferencesRequested(
        UserPreferencesEntity(
          id: current.id,
          userId: current.userId,
          theme: _theme,
          defaultLandingPage: _landingPage,
          rememberLastScreen: _rememberLastScreen,
          pushNotifications: _pushNotifications,
          homeworkNotifications: _homeworkNotifications,
          attendanceNotifications: _attendanceNotifications,
          feeNotifications: _feeNotifications,
          examNotifications: _examNotifications,
          paperSize: _paperSize,
          receiptFormat: _receiptFormat,
          resultCardFormat: _resultCardFormat,
          language: _language,
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }
}
