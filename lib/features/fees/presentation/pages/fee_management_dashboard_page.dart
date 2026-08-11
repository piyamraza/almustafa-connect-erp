import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/fee_payment_entity.dart';
import '../../domain/entities/monthly_fee_due_entity.dart';
import '../../domain/repositories/fee_payment_repository.dart';
import '../../domain/repositories/monthly_fee_due_repository.dart';
import 'fee_challan_page.dart';
import 'fee_collection_page.dart';
import 'fee_reports_page.dart';
import 'fee_structure_page.dart';
import 'monthly_fee_generation_page.dart';
import 'student_fee_assignment_page.dart';
import 'additional_charges_management_page.dart';

const _pageBackground = Color(0xFFF2F5FB);
const _textPrimary = Color(0xFF182230);
const _textSecondary = Color(0xFF667085);

class FeeManagementDashboardPage extends StatelessWidget {
  const FeeManagementDashboardPage({super.key});

  Future<_FeeDashboardSnapshot> _loadSnapshot() async {
    try {
      final values = await Future.wait<Object>([
        sl<FeePaymentRepository>().getPayments(),
        sl<MonthlyFeeDueRepository>().getMonthlyDues(),
      ]);
      return _FeeDashboardSnapshot(
        payments: values[0] as List<FeePaymentEntity>,
        dues: values[1] as List<MonthlyFeeDueEntity>,
        now: DateTime.now(),
      );
    } catch (_) {
      return _FeeDashboardSnapshot(
        payments: const [],
        dues: const [],
        now: DateTime.now(),
      );
    }
  }

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
        title: 'Additional Charges',
        description:
            'Create and generate school-wide, class-wise or student-specific charges.',
        icon: Icons.add_card_outlined,
        color: const Color(0xFFDB2777),
        lightColor: const Color(0xFFFFECF5),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AdditionalChargesManagementPage(),
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
        actions: const [DashboardNavigationButton()],
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
                      const SizedBox(height: 14),
                      FutureBuilder<_FeeDashboardSnapshot>(
                        future: _loadSnapshot(),
                        builder: (context, snapshot) => _FinancialOverview(
                          data: snapshot.data,
                          loading:
                              snapshot.connectionState != ConnectionState.done,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fee Operations',
                                  style: TextStyle(
                                    color: _textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Choose an operation to continue',
                                  style: TextStyle(
                                    color: _textSecondary,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const FeeCollectionPage(),
                              ),
                            ),
                            icon: const Icon(Icons.add_card_rounded),
                            label: const Text('Collect Fee'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 1180
                              ? 4
                              : constraints.maxWidth >= 900
                              ? 3
                              : constraints.maxWidth >= 700
                              ? 2
                              : 1;

                          final aspectRatio = switch (columns) {
                            4 => 1.95,
                            3 => 2.15,
                            2 => 2.05,
                            _ => 2.8,
                          };

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: features.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
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

class _FinancialOverview extends StatelessWidget {
  const _FinancialOverview({required this.data, required this.loading});

  final _FeeDashboardSnapshot? data;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final value = data;
    final metrics = [
      _FeeMetric(
        label: "Today's Collection",
        value: value == null ? '—' : _money(value.todayCollection),
        detail: value == null ? '' : '${value.todayPaidStudents} students paid',
        icon: Icons.savings_rounded,
        color: const Color(0xFF0F9D74),
      ),
      _FeeMetric(
        label: 'Monthly Collection',
        value: value == null ? '—' : _money(value.monthCollection),
        detail: value == null ? '' : '${value.monthPaidStudents} students paid',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF1769E8),
      ),
      _FeeMetric(
        label: 'Outstanding Fees',
        value: value == null ? '—' : _money(value.outstanding),
        detail: value == null
            ? ''
            : '${value.pendingStudents} students pending',
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFEF4444),
      ),
      _FeeMetric(
        label: 'Collection Rate',
        value: value == null
            ? '—'
            : '${value.collectionRate.toStringAsFixed(1)}%',
        detail: 'Current generated dues',
        icon: Icons.donut_large_rounded,
        color: const Color(0xFF7C3AED),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 620
            ? 1
            : constraints.maxWidth < 1000
            ? 2
            : 4;
        return Stack(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: metrics.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 116,
              ),
              itemBuilder: (context, index) =>
                  _MoneyMetric(metric: metrics[index]),
            ),
            if (loading)
              const Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MoneyMetric extends StatelessWidget {
  const _MoneyMetric({required this.metric});
  final _FeeMetric metric;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          metric.color.withValues(alpha: 0.13),
          Colors.white,
          Colors.white,
        ],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: metric.color.withValues(alpha: 0.22)),
      boxShadow: [
        BoxShadow(
          color: metric.color.withValues(alpha: 0.07),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: metric.color,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(metric.icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.label,
                style: const TextStyle(color: _textSecondary, fontSize: 11.5),
              ),
              const SizedBox(height: 3),
              Text(
                metric.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (metric.detail.isNotEmpty)
                Text(
                  metric.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: metric.color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FeeMetric {
  const _FeeMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
}

class _FeeDashboardSnapshot {
  const _FeeDashboardSnapshot({
    required this.payments,
    required this.dues,
    required this.now,
  });
  final List<FeePaymentEntity> payments;
  final List<MonthlyFeeDueEntity> dues;
  final DateTime now;

  Iterable<FeePaymentEntity> get _completed =>
      payments.where((item) => item.status == FeePaymentStatus.completed);
  double get todayCollection => _completed
      .where((item) => _sameDay(item.paymentDate, now))
      .fold(0, (sum, item) => sum + item.totalPaid);
  int get todayPaidStudents => _completed
      .where((item) => _sameDay(item.paymentDate, now))
      .map((item) => item.studentId)
      .toSet()
      .length;
  double get monthCollection => _completed
      .where(
        (item) =>
            item.paymentDate.year == now.year &&
            item.paymentDate.month == now.month,
      )
      .fold(0, (sum, item) => sum + item.totalPaid);
  int get monthPaidStudents => _completed
      .where(
        (item) =>
            item.paymentDate.year == now.year &&
            item.paymentDate.month == now.month,
      )
      .map((item) => item.studentId)
      .toSet()
      .length;
  Iterable<MonthlyFeeDueEntity> get _activeDues =>
      dues.where((item) => item.status != MonthlyFeeDueStatus.cancelled);
  double get outstanding =>
      _activeDues.fold(0, (sum, item) => sum + item.outstandingAmount);
  int get pendingStudents => _activeDues
      .where((item) => item.outstandingAmount > 0)
      .map((item) => item.studentId)
      .toSet()
      .length;
  double get collectionRate {
    final payable = _activeDues.fold<double>(
      0,
      (sum, item) => sum + item.netPayable,
    );
    final paid = _activeDues.fold<double>(
      0,
      (sum, item) => sum + item.paidAmount,
    );
    return payable <= 0 ? 0 : (paid / payable * 100).clamp(0, 100);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

String _money(double value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return 'Rs. $buffer';
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
              padding: const EdgeInsets.all(13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: feature.color.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: feature.color.withValues(alpha: .22),
                      ),
                    ),
                    child: Icon(feature.icon, color: feature.color, size: 19),
                  ),
                  const SizedBox(width: 10),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            feature.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 12,
                              height: 1.25,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: feature.color.withValues(alpha: .11),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: feature.color,
                              size: 15,
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
