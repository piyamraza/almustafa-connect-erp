import 'package:flutter/material.dart';

import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../documents/presentation/pages/experience_certificate_preview_page.dart';
import '../../../documents/presentation/pages/employee_card_preview_page.dart';
import '../../../documents/presentation/pages/salary_slip_preview_page.dart';
import 'teacher_appointment_letters_page.dart';

class EmployeeCertificatesPage extends StatelessWidget {
  const EmployeeCertificatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Certificates'),
        actions: const [DashboardNavigationButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 700;
                  final columns = compact ? 2 : 3;

                  return GridView.count(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: compact ? 0.95 : 1.3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _CertificateCard(
                        title: 'Appointment Letters',
                        description: 'Create, issue and archive signed teacher appointment letters.',
                        icon: Icons.assignment_turned_in_outlined,
                        ready: true,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const TeacherAppointmentLettersPage()),
                        ),
                      ),
                      _CertificateCard(
                        title: 'Experience Certificate',
                        description:
                            'Generate employee experience certificate.',
                        icon: Icons.history_edu_outlined,
                        ready: true,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const ExperienceCertificatePreviewPage(),
                            ),
                          );
                        },
                      ),
                      _CertificateCard(
                        title: 'Employee Card',
                        description: 'Generate employee identity card.',
                        icon: Icons.badge_outlined,
                        ready: true,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const EmployeeCardPreviewPage(),
                            ),
                          );
                        },
                      ),
                      _CertificateCard(
                        title: 'Salary Slip',
                        description: 'Generate monthly employee salary slip.',
                        icon: Icons.receipt_long_outlined,
                        ready: true,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SalarySlipPreviewPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.ready,
    this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool ready;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: ready ? onTap : null,
        child: Padding(
          padding: EdgeInsets.all(compact ? 10 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: compact ? 40 : 48,
                    height: compact ? 40 : 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: compact ? 21 : 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (!compact)
                    Chip(label: Text(ready ? 'Ready' : 'Foundation Ready')),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (!compact) ...[const SizedBox(height: 8), Text(description)],
            ],
          ),
        ),
      ),
    );
  }
}
