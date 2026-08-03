import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../authentication/domain/usecases/get_current_user_usecase.dart';
import '../bloc/security_bloc.dart';
import '../bloc/security_event.dart';
import '../bloc/security_state.dart';

class SecuritySessionsPage extends StatelessWidget {
  const SecuritySessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = sl<GetCurrentUserUseCase>()()?.uid ?? '';

    return BlocProvider(
      create: (_) => sl<SecurityBloc>()..add(LoadSecurityData(userId)),
      child: const _SecuritySessionsView(),
    );
  }
}

class _SecuritySessionsView extends StatelessWidget {
  const _SecuritySessionsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security and Sessions'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocConsumer<SecurityBloc, SecurityState>(
        listener: (context, state) {
          if (state is SecurityLoaded && state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          if (state is SecurityInitial || state is SecurityLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SecurityFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as SecurityLoaded;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () => _changePassword(context),
                  icon: const Icon(Icons.password_outlined),
                  label: const Text('Change Password'),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Active Sessions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (data.sessions.isEmpty)
                const Card(
                  child: ListTile(title: Text('No session records found.')),
                ),
              ...data.sessions.map(
                (session) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        session.isCurrent ? Icons.devices : Icons.devices_other,
                      ),
                    ),
                    title: Text(
                      session.deviceName.isEmpty
                          ? 'Unknown Device'
                          : session.deviceName,
                    ),
                    subtitle: Text(
                      '${session.platform} - '
                      '${_date(session.lastActiveAt)}',
                    ),
                    trailing: session.isCurrent || session.isRevoked
                        ? Text(session.isCurrent ? 'Current' : 'Revoked')
                        : TextButton(
                            onPressed: () {
                              context.read<SecurityBloc>().add(
                                RevokeSessionRequested(
                                  sessionId: session.id,
                                  userId: data.userId,
                                ),
                              );
                            },
                            child: const Text('Revoke'),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Login History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (data.loginHistory.isEmpty)
                const Card(
                  child: ListTile(title: Text('No login history found.')),
                ),
              ...data.loginHistory
                  .take(50)
                  .map(
                    (entry) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            entry.success
                                ? Icons.verified_user_outlined
                                : Icons.warning_amber_outlined,
                          ),
                        ),
                        title: Text(entry.activityType.name),
                        subtitle: Text(
                          '${entry.deviceName} - '
                          '${_date(entry.occurredAt)}',
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _changePassword(BuildContext context) async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (save == true && context.mounted) {
      context.read<SecurityBloc>().add(
        ChangePasswordRequested(
          currentPassword: currentController.text,
          newPassword: newController.text,
          confirmPassword: confirmController.text,
        ),
      );
    }

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
  }

  static String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}
