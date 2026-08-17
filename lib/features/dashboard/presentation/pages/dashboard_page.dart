import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../access_control/domain/services/access_control_service.dart';
import '../../../authentication/domain/usecases/get_current_user_usecase.dart';
import '../../../communication/domain/services/push_notification_service.dart';
import '../../../communication/domain/usecases/register_push_device.dart';
import '../../../communication/presentation/pages/in_app_chat_page.dart';
import '../../../parent_portal/presentation/pages/parent_workspace_page.dart';
import '../../../teacher_portal/presentation/pages/teacher_portal_dashboard_page.dart';
import '../widgets/dashboard_layout.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final AccessControlService _access;
  StreamSubscription<RemoteMessage>? _foregroundMessages;
  StreamSubscription<RemoteMessage>? _openedMessages;
  StreamSubscription<String>? _tokenRefreshes;

  @override
  void initState() {
    super.initState();

    _access = sl<AccessControlService>();
    _access.addListener(_refresh);
    _access.loadCurrentAccess();
    _configurePushNotifications();
  }

  @override
  void dispose() {
    _access.removeListener(_refresh);
    _foregroundMessages?.cancel();
    _openedMessages?.cancel();
    _tokenRefreshes?.cancel();
    super.dispose();
  }

  Future<void> _configurePushNotifications() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    final user = sl<GetCurrentUserUseCase>()();
    if (user == null) return;
    await _registerPushDevice(user.uid);
    _tokenRefreshes = sl<PushNotificationService>().tokenRefreshes.listen(
      (_) => _registerPushDevice(user.uid),
    );
    _foregroundMessages = FirebaseMessaging.onMessage.listen((message) {
      if (!mounted) return;
      final title = message.notification?.title ?? 'New notification';
      final body = message.notification?.body ?? '';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(body.isEmpty ? title : '$title\n$body'),
            action: message.data['type'] == 'chat'
                ? SnackBarAction(
                    label: 'Open',
                    onPressed: () => _openPushMessage(message),
                  )
                : null,
          ),
        );
    });
    _openedMessages = FirebaseMessaging.onMessageOpenedApp.listen(
      _openPushMessage,
    );
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openPushMessage(initial),
      );
    }
  }

  Future<void> _registerPushDevice(String userId) async {
    try {
      await sl<RegisterPushDevice>()(userId: userId);
    } catch (_) {
      // The dashboard must remain usable if notifications are denied/unavailable.
    }
  }

  void _openPushMessage(RemoteMessage message) {
    if (!mounted || message.data['type'] != 'chat') return;
    final threadId =
        message.data['threadId'] ?? message.data['referenceId'] ?? '';
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => InAppChatPage(initialThreadId: threadId),
      ),
    );
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isParentWorkspace {
    return _access.assignment?.roleId == 'parent';
  }

  bool get _isTeacherWorkspace {
    return _access.assignment?.roleId == 'teacher';
  }

  bool get _isAdminWorkspace =>
      _access.isBootstrapAccess ||
      const {'admin', 'school_admin', 'super_admin'}
          .contains(_access.assignment?.roleId);

  @override
  Widget build(BuildContext context) {
    if (_access.isLoading || !_access.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isParentWorkspace) {
      return const ParentWorkspacePage();
    }

    if (_isTeacherWorkspace) {
      return const TeacherPortalDashboardPage();
    }

    if (_isAdminWorkspace) return const DashboardLayout();

    return Scaffold(
      appBar: AppBar(title: const Text('Account Access')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_person_outlined, size: 54),
              const SizedBox(height: 12),
              const Text(
                'Dashboard access is not configured',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _access.errorMessage ??
                    'Ask Super Admin to assign an active Parent, Teacher or Admin role.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _access.loadCurrentAccess(forceRefresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
