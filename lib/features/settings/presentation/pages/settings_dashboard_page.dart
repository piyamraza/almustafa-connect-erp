import 'package:flutter/material.dart';

import '../../../../core/audit/presentation/pages/audit_configuration_page.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import 'backup_restore_page.dart';
import 'branding_settings_page.dart';
import 'academic_settings_page.dart';
import 'regional_settings_page.dart';
import 'system_prefixes_settings_page.dart';
import 'school_profile_settings_page.dart';
import 'security_sessions_page.dart';
import 'system_health_page.dart';
import 'user_preferences_page.dart';

const _pageBackground = Color(0xFFF5F7FA);
const _brandBlue = Color(0xFF0B63CE);
const _borderColor = Color(0xFFE1E6ED);
const _textPrimary = Color(0xFF182230);
const _textSecondary = Color(0xFF667085);

class SettingsDashboardPage extends StatelessWidget {
  const SettingsDashboardPage({super.key});

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
                maxWidth: 1050,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SettingsHeader(),
                  const SizedBox(height: 28),

                  const _SectionTitle(
                    title: 'School Configuration',
                  ),
                  const SizedBox(height: 12),

                  _SettingsTile(
                    icon: Icons.school_outlined,
                    title: 'School Profile',
                    subtitle:
                        'General school information, address and contact details',
                    onTap: () => _open(
                      context,
                      const SchoolProfileSettingsPage(),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.palette_outlined,
                    title: 'Branding',
                    subtitle:
                        'School logo, principal, signature and official stamp',
                    onTap: () => _open(
                      context,
                      const BrandingSettingsPage(),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.calendar_month_outlined,
                    title: 'Academic Settings',
                    subtitle:
                        'Academic session, start date and end date',
                    onTap: () => _open(
  context,
  const AcademicSettingsPage(),
),
                  ),
                  _SettingsTile(
                    icon: Icons.public_outlined,
                    title: 'Regional Settings',
                    subtitle:
                        'Currency, date format and time format',
                    onTap: () => _open(
  context,
  const RegionalSettingsPage(),
),
                  ),
                  _SettingsTile(
                    icon: Icons.tag_outlined,
                    title: 'System Prefixes',
                    subtitle:
                        'Admission, roll number and receipt prefixes',
                    onTap: () => _open(
  context,
  const SystemPrefixesSettingsPage(),
),
                  ),

                  const SizedBox(height: 28),
                  const _SectionTitle(
                    title: 'User & Security',
                  ),
                  const SizedBox(height: 12),

                  _SettingsTile(
                    icon: Icons.tune_outlined,
                    title: 'User Preferences',
                    subtitle:
                        'Personal preferences and application behaviour',
                    onTap: () => _open(
                      context,
                      const UserPreferencesPage(),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.security_outlined,
                    title: 'Security & Sessions',
                    subtitle:
                        'Manage security settings and active sessions',
                    onTap: () => _open(
                      context,
                      const SecuritySessionsPage(),
                    ),
                  ),

                  const SizedBox(height: 28),
                  const _SectionTitle(
                    title: 'System Administration',
                  ),
                  const SizedBox(height: 12),

                  _SettingsTile(
                    icon: Icons.backup_outlined,
                    title: 'Backup & Restore',
                    subtitle:
                        'Backup school data and restore previous backups',
                    onTap: () => _open(
                      context,
                      const BackupRestorePage(),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.monitor_heart_outlined,
                    title: 'System Health',
                    subtitle:
                        'Diagnostics and system health information',
                    onTap: () => _open(
                      context,
                      const SystemHealthPage(),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.history_outlined,
                    title: 'Audit Logging',
                    subtitle:
                        'Configure audit tracking and activity logging',
                    onTap: () => _open(
                      context,
                      const AuditConfigurationPage(),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _open(
    BuildContext context,
    Widget page,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => page,
      ),
    );
  }

  }

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardNavigationButton(),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage school configuration, branding, security and system preferences.',
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 17,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: _borderColor,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _brandBlue.withValues(
                      alpha: 0.09,
                    ),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: _brandBlue,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.chevron_right,
                  color: _textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}