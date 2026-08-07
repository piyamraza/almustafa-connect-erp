import 'package:flutter/material.dart';
import '../../../school_engagement/presentation/pages/school_engagement_page.dart';
import '../../../students/presentation/pages/students_page.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../domain/entities/document_type.dart';

const _pageBackground = Color(0xFFF5F7FA);
const _brandBlue = Color(0xFF0B63CE);
const _borderColor = Color(0xFFE1E6ED);
const _textPrimary = Color(0xFF182230);
const _textSecondary = Color(0xFF667085);
const _successGreen = Color(0xFF067647);
const _successBackground = Color(0xFFECFDF3);

class DocumentCenterPage extends StatelessWidget {
  const DocumentCenterPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final groups = _buildGroups();

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1250,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const _DocumentCenterHeader(),
                  const SizedBox(height: 24),
                  const _OverviewCards(),
                  const SizedBox(height: 28),

                  for (final group in groups) ...[
                    _DocumentGroupSection(
                      group: group,
                    ),
                    const SizedBox(height: 26),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<_DocumentGroup> _buildGroups() {
    return const [
      _DocumentGroup(
        title: 'Student Documents',
        subtitle:
            'Cards and official documents generated for students.',
        items: [
          _DocumentCenterItem(
            type: DocumentType.birthdayCard,
            title: 'Birthday Cards',
            description:
                'Create branded birthday cards using the universal Document Engine.',
            icon: Icons.cake_outlined,
            status: _DocumentStatus.ready,
          ),
          _DocumentCenterItem(
            type: DocumentType.characterCertificate,
            title: 'Character Certificate',
            description:
                'Generate official character certificates with school branding.',
            icon: Icons.workspace_premium_outlined,
            status: _DocumentStatus.ready,
          ),
          _DocumentCenterItem(
            type: DocumentType.bonafideCertificate,
            title: 'Bonafide Certificate',
            description:
                'Create bonafide certificates from student records.',
            icon: Icons.verified_user_outlined,
            status: _DocumentStatus.ready,
          ),
          _DocumentCenterItem(
            type: DocumentType.leavingCertificate,
            title: 'Leaving Certificate',
            description:
                'Prepare student leaving and school transfer documentation.',
            icon: Icons.exit_to_app_outlined,
            status: _DocumentStatus.foundationReady,
          ),
          _DocumentCenterItem(
            type: DocumentType.idCard,
            title: 'Student ID Cards',
            description:
                'Generate student identity cards from reusable templates.',
            icon: Icons.badge_outlined,
            status: _DocumentStatus.foundationReady,
          ),
        ],
      ),

      _DocumentGroup(
        title: 'Academic Documents',
        subtitle:
            'Examination, result and academic output documents.',
        items: [
          _DocumentCenterItem(
            type: DocumentType.resultCard,
            title: 'Result Cards',
            description:
                'Generate branded result cards through the same rendering engine.',
            icon: Icons.assessment_outlined,
            status: _DocumentStatus.foundationReady,
          ),
          _DocumentCenterItem(
            type: DocumentType.feeChallan,
            title: 'Fee Challans',
            description:
                'Create printable student fee challans from reusable layouts.',
            icon: Icons.receipt_long_outlined,
            status: _DocumentStatus.foundationReady,
          ),
        ],
      ),

      _DocumentGroup(
        title: 'Staff Documents',
        subtitle:
            'Employee identity, experience and payroll documents.',
        items: [
          _DocumentCenterItem(
            type: DocumentType.experienceCertificate,
            title: 'Experience Certificate',
            description:
                'Generate staff and teacher experience certificates.',
            icon: Icons.history_edu_outlined,
            status: _DocumentStatus.foundationReady,
          ),
          _DocumentCenterItem(
            type: DocumentType.employeeCard,
            title: 'Employee Cards',
            description:
                'Generate staff and teacher identity cards.',
            icon: Icons.account_box_outlined,
            status: _DocumentStatus.foundationReady,
          ),
          _DocumentCenterItem(
            type: DocumentType.salarySlip,
            title: 'Salary Slips',
            description:
                'Create salary slips through the centralized Document Engine.',
            icon: Icons.payments_outlined,
            status: _DocumentStatus.foundationReady,
          ),
        ],
      ),
    ];
  }
}

class _DocumentCenterHeader extends StatelessWidget {
  const _DocumentCenterHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        const title = Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Document Center',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Create, preview and manage school documents through one universal engine.',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        );

        if (constraints.maxWidth < 720) {
          return const Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              DashboardNavigationButton(),
              SizedBox(height: 16),
              title,
            ],
          );
        }

        return const Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            DashboardNavigationButton(),
            SizedBox(width: 16),
            Expanded(
              child: title,
            ),
          ],
        );
      },
    );
  }
}

class _OverviewCards extends StatelessWidget {
  const _OverviewCards();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final width =
            constraints.maxWidth >= 900
                ? (constraints.maxWidth - 32) / 3
                : constraints.maxWidth >= 600
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: width,
              child: const _OverviewCard(
                icon: Icons.dashboard_customize_outlined,
                value: '10',
                label: 'Document Types',
              ),
            ),
            SizedBox(
              width: width,
              child: const _OverviewCard(
                icon: Icons.check_circle_outline,
                value: '1',
                label: 'Production Ready',
              ),
            ),
            SizedBox(
              width: width,
              child: const _OverviewCard(
                icon: Icons.auto_awesome_outlined,
                value: '1',
                label: 'Universal Engine',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: _borderColor,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _brandBlue.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: _brandBlue,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentGroupSection
    extends StatelessWidget {
  const _DocumentGroupSection({
    required this.group,
  });

  final _DocumentGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          group.title,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          group.subtitle,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final itemWidth =
                constraints.maxWidth >= 1050
                    ? (constraints.maxWidth - 32) / 3
                    : constraints.maxWidth >= 680
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final item in group.items)
                  SizedBox(
                    width: itemWidth,
                    child: _DocumentTypeCard(
                      item: item,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DocumentTypeCard extends StatelessWidget {
  const _DocumentTypeCard({
    required this.item,
  });

  final _DocumentCenterItem item;

  @override
  Widget build(BuildContext context) {
    final ready =
        item.status == _DocumentStatus.ready;

    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(16),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(16),
        onTap: () => _open(
          context,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
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
                    decoration: BoxDecoration(
                      color: _brandBlue.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.icon,
                      color: _brandBlue,
                    ),
                  ),
                  const Spacer(),
                  _StatusBadge(
                    status: item.status,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                item.title,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                item.description,
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    ready
                        ? 'Open'
                        : 'View',
                    style: const TextStyle(
                      color: _brandBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: _brandBlue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(
  BuildContext context,
) {
  switch (item.type) {
case DocumentType.birthdayCard:
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const SchoolEngagementPage(),
    ),
  );
  return;
    case DocumentType.characterCertificate:
    case DocumentType.bonafideCertificate:
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const StudentsPage(),
        ),
      );
      return;

    default:
      final message = switch (item.status) {
        _DocumentStatus.ready =>
          '${item.title} is connected to the Document Engine.',
        _DocumentStatus.foundationReady =>
          '${item.title} engine foundation is ready. Its template will be added next.',
      };

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
  }
}
}
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
  });

  final _DocumentStatus status;

  @override
  Widget build(BuildContext context) {
    final ready =
        status == _DocumentStatus.ready;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: ready
            ? _successBackground
            : _pageBackground,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        ready
            ? 'Ready'
            : 'Foundation Ready',
        style: TextStyle(
          color: ready
              ? _successGreen
              : _textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum _DocumentStatus {
  ready,
  foundationReady,
}

class _DocumentGroup {
  const _DocumentGroup({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<_DocumentCenterItem> items;
}

class _DocumentCenterItem {
  const _DocumentCenterItem({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.status,
  });

  final DocumentType type;
  final String title;
  final String description;
  final IconData icon;
  final _DocumentStatus status;
}
