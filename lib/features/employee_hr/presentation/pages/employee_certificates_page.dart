import 'package:flutter/material.dart';

import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../documents/presentation/pages/experience_certificate_preview_page.dart';

class EmployeeCertificatesPage extends StatelessWidget {
  const EmployeeCertificatesPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Certificates'),
        actions: const [
          DashboardNavigationButton(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1000,
              ),
              child: LayoutBuilder(
                builder: (
                  context,
                  constraints,
                ) {
                  final columns =
                      constraints.maxWidth >= 700
                          ? 3
                          : 1;

                  return GridView.count(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    children: [
                      _CertificateCard(
                        title:
                            'Experience Certificate',
                        description:
                            'Generate employee experience certificate.',
                        icon:
                            Icons.history_edu_outlined,
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
                      const _CertificateCard(
                        title: 'Employee Card',
                        description:
                            'Employee identity card.',
                        icon:
                            Icons.badge_outlined,
                        ready: false,
                      ),
                      const _CertificateCard(
                        title: 'Salary Slip',
                        description:
                            'Employee salary slip document.',
                        icon:
                            Icons.receipt_long_outlined,
                        ready: false,
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: ready ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 34,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                  ),
                  const Spacer(),
                  Chip(
                    label: Text(
                      ready
                          ? 'Ready'
                          : 'Foundation Ready',
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(description),
            ],
          ),
        ),
      ),
    );
  }
}
