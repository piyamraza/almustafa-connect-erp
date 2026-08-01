import 'package:flutter/material.dart';

import 'fee_challan_page.dart';
import 'fee_collection_page.dart';
import 'fee_reports_page.dart';
import 'fee_structure_page.dart';
import 'monthly_fee_generation_page.dart';
import 'student_fee_assignment_page.dart';

const _pageBackground = Color(0xFFF2F5FB);
const _textPrimary = Color(0xFF182230);
const _textSecondary = Color(0xFF667085);

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
        color: const Color(0xFF2563EB),
        lightColor: const Color(0xFFEAF2FF),
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
        color: const Color(0xFF7C3AED),
        lightColor: const Color(0xFFF3ECFF),
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
        color: const Color(0xFF0891B2),
        lightColor: const Color(0xFFE6F8FC),
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
        color: const Color(0xFFEA580C),
        lightColor: const Color(0xFFFFF0E8),
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
        color: const Color(0xFFB45309),
        lightColor: const Color(0xFFFFF5DE),
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
        color: const Color(0xFF059669),
        lightColor: const Color(0xFFE8FBF3),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const FeeReportsPage()),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        title: const Text('Fee Management'),
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1380),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DashboardHeader(featureCount: features.length),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 1080
                              ? 3
                              : constraints.maxWidth >= 700
                              ? 2
                              : 1;

                          final aspectRatio = switch (columns) {
                            3 => 2.05,
                            2 => 1.9,
                            _ => 2.4,
                          };

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: features.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: aspectRatio,
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
            );
          },
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.featureCount});

  final int featureCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B63CE), Color(0xFF3B82F6), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withValues(alpha: .25)),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fee Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Manage fee structures, monthly dues, payments, '
                  'receipts and reports.',
                  style: TextStyle(color: Color(0xFFEAF2FF), fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: .22)),
            ),
            child: Text(
              '$featureCount Modules',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeFeature {
  const _FeeFeature({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.lightColor,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color lightColor;
  final VoidCallback onTap;
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({required this.feature});

  final _FeeFeature feature;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final feature = widget.feature;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [feature.lightColor, Colors.white],
          ),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: _hovered
                ? feature.color.withValues(alpha: .48)
                : feature.color.withValues(alpha: .20),
            width: _hovered ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: feature.color.withValues(alpha: _hovered ? .16 : .08),
              blurRadius: _hovered ? 18 : 10,
              offset: Offset(0, _hovered ? 7 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: feature.onTap,
            borderRadius: BorderRadius.circular(17),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: feature.color.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: feature.color.withValues(alpha: .22),
                      ),
                    ),
                    child: Icon(feature.icon, color: feature.color, size: 23),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            feature.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            width: 29,
                            height: 29,
                            decoration: BoxDecoration(
                              color: feature.color.withValues(alpha: .11),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: feature.color,
                              size: 17,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
