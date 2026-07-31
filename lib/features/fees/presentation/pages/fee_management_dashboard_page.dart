import 'package:flutter/material.dart';

import 'monthly_fee_generation_page.dart';
import 'student_fee_assignment_page.dart';
import 'fee_challan_page.dart';
import 'fee_collection_page.dart';
import 'fee_reports_page.dart';
import 'fee_structure_page.dart';

class FeeManagementDashboardPage extends StatelessWidget {
  const FeeManagementDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final features = <_FeeFeature>[
      _FeeFeature(
        title: 'Fee Structure',
        description:
            'Configure class and section-wise monthly and one-time charges.',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF1565C0),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const FeeStructurePage()),
          );
        },
      ),
      _FeeFeature(
        title: 'Student Fee Assignment',
        description:
            'Assign fee structures, discounts and individual adjustments.',
        icon: Icons.assignment_ind_outlined,
        color: const Color(0xFF6A1B9A),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const StudentFeeAssignmentPage(),
            ),
          );
        },
      ),
      _FeeFeature(
        title: 'Monthly Fee Generation',
        description:
            'Generate monthly dues, arrears and advance month charges.',
        icon: Icons.calendar_month_outlined,
        color: const Color(0xFF00897B),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const MonthlyFeeGenerationPage(),
            ),
          );
        },
      ),
      _FeeFeature(
        title: 'Collect Payment',
        description: 'Receive partial or full payments and issue receipts.',
        icon: Icons.payments_outlined,
        color: const Color(0xFFEF6C00),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const FeeCollectionPage()),
          );
        },
      ),
      _FeeFeature(
        title: 'Fee Challans',
        description:
            'Print and share school, parent and bank fee challan copies.',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF5D4037),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const FeeChallanPage()),
          );
        },
      ),
      _FeeFeature(
        title: 'Fee Reports',
        description:
            'Paid, unpaid, arrears, collection and student ledger reports.',
        icon: Icons.analytics_outlined,
        color: const Color(0xFF455A64),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const FeeReportsPage()),
          );
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Fee Management')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fee Management',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Manage fee structures, monthly dues, payments, '
                    'receipts and reports.',
                  ),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 1050
                          ? 3
                          : constraints.maxWidth >= 680
                          ? 2
                          : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: features.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: columns == 1 ? 2.15 : 1.35,
                        ),
                        itemBuilder: (context, index) =>
                            _FeatureCard(feature: features[index]),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will be added in the next phase.')),
    );
  }
}

class _FeeFeature {
  const _FeeFeature({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final _FeeFeature feature;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: feature.onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: feature.color.withAlpha(24),
                child: Icon(feature.icon, color: feature.color),
              ),
              const Spacer(),
              Text(
                feature.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              Text(feature.description),
            ],
          ),
        ),
      ),
    );
  }
}
