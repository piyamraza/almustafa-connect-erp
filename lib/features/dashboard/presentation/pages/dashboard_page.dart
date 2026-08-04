import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../access_control/domain/services/access_control_service.dart';
import '../../../teacher_portal/presentation/pages/teacher_portal_dashboard_page.dart';
import '../widgets/dashboard_layout.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final AccessControlService _access;

  @override
  void initState() {
    super.initState();

    _access = sl<AccessControlService>();
    _access.addListener(_refresh);
    _access.loadCurrentAccess();
  }

  @override
  void dispose() {
    _access.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isTeacherWorkspace {
    if (_access.isBootstrapAccess) {
      return false;
    }

    return _access.hasRole('teacher');
  }

  @override
  Widget build(BuildContext context) {
    if (_access.isLoading || !_access.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isTeacherWorkspace) {
      return const TeacherPortalDashboardPage();
    }

    return const DashboardLayout();
  }
}
