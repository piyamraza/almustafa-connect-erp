import 'package:flutter/material.dart';

import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../fees/presentation/pages/fee_challan_page.dart';
import '../../../fees/presentation/pages/fee_collection_page.dart';
import '../../../results/presentation/pages/merit_list_page.dart';
import '../../../results/presentation/pages/report_cards_page.dart';
import '../../../school_engagement/presentation/pages/school_engagement_page.dart';
import '../../../students/presentation/pages/students_page.dart';
import '../../domain/entities/document_type.dart';
import 'experience_certificate_preview_page.dart';
import 'employee_card_preview_page.dart';
import 'salary_slip_preview_page.dart';

const _pageBackground = Color(0xFFF5F7FA);
const _brandBlue = Color(0xFF0B63CE);
const _borderColor = Color(0xFFE1E6ED);
const _textPrimary = Color(0xFF182230);
const _textSecondary = Color(0xFF667085);
const _successGreen = Color(0xFF067647);
const _successBackground = Color(0xFFECFDF3);

class DocumentCenterPage extends StatefulWidget {
  const DocumentCenterPage({super.key});

  @override
  State<DocumentCenterPage> createState() => _DocumentCenterPageState();
}

class _DocumentCenterPageState extends State<DocumentCenterPage> {
  final TextEditingController _searchController = TextEditingController();

  _DocumentCategory _selectedCategory = _DocumentCategory.all;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = _filteredGroups();

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1250),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _DocumentCenterHeader(),
                  const SizedBox(height: 14),
                  _SearchAndCategories(
                    controller: _searchController,
                    selectedCategory: _selectedCategory,
                    onSearchChanged: (value) {
                      setState(() {
                        _query = value.trim().toLowerCase();
                      });
                    },
                    onCategoryChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    onClear: _clearFilters,
                  ),
                  const SizedBox(height: 16),
                  if (groups.isEmpty)
                    _EmptySearchState(onClear: _clearFilters)
                  else
                    for (final group in groups) ...[
                      _DocumentGroupSection(group: group),
                      const SizedBox(height: 14),
                    ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedCategory = _DocumentCategory.all;
    });
  }

  List<_DocumentGroup> _filteredGroups() {
    final result = <_DocumentGroup>[];

    for (final group in _buildGroups()) {
      if (_selectedCategory != _DocumentCategory.all &&
          group.category != _selectedCategory) {
        continue;
      }

      final items = group.items
          .where((item) {
            if (_query.isEmpty) {
              return true;
            }

            final searchable = [
              item.title,
              item.description,
              item.type.label,
              group.title,
            ].join(' ').toLowerCase();

            return searchable.contains(_query);
          })
          .toList(growable: false);

      if (items.isNotEmpty) {
        result.add(
          _DocumentGroup(
            category: group.category,
            title: group.title,
            subtitle: group.subtitle,
            items: items,
          ),
        );
      }
    }

    return result;
  }

  List<_DocumentGroup> _buildGroups() {
    return const [
      _DocumentGroup(
        category: _DocumentCategory.student,
        title: 'Student Documents',
        subtitle: 'Cards and official documents generated for students.',
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
            description: 'Create bonafide certificates from student records.',
            icon: Icons.verified_user_outlined,
            status: _DocumentStatus.ready,
          ),
          _DocumentCenterItem(
            type: DocumentType.leavingCertificate,
            title: 'Leaving Certificate',
            description:
                'Prepare student leaving and school transfer documentation.',
            icon: Icons.exit_to_app_outlined,
            status: _DocumentStatus.ready,
          ),
          _DocumentCenterItem(
            type: DocumentType.idCard,
            title: 'Student ID Cards',
            description:
                'Generate student identity cards from reusable templates.',
            icon: Icons.badge_outlined,
            status: _DocumentStatus.ready,
          ),
        ],
      ),
      _DocumentGroup(
        category: _DocumentCategory.academic,
        title: 'Academic Documents',
        subtitle: 'Examination, result and fee-related school documents.',
        items: [
          _DocumentCenterItem(
            type: DocumentType.resultCard,
            title: 'Result Cards',
            description:
                'Generate branded result cards from published student results.',
            icon: Icons.assessment_outlined,
            status: _DocumentStatus.ready,
          ),
          _DocumentCenterItem(
            type: DocumentType.meritCertificate,
            title: 'Merit Certificate',
            description:
                'Generate merit certificates for students from published results.',
            icon: Icons.emoji_events_outlined,
            status: _DocumentStatus.ready,
          ),
          _DocumentCenterItem(
            type: DocumentType.feeChallan,
            title: 'Fee Challans',
            description:
                'Create printable student fee challans from current fee dues.',
            icon: Icons.receipt_long_outlined,
            status: _DocumentStatus.ready,
          ),
          _DocumentCenterItem(
            type: DocumentType.feeReceipt,
            title: 'Fee Receipts',
            description:
                'Preview, print and share receipts from recorded fee payments.',
            icon: Icons.receipt_outlined,
            status: _DocumentStatus.ready,
          ),
        ],
      ),
      _DocumentGroup(
        category: _DocumentCategory.staff,
        title: 'Staff Documents',
        subtitle: 'Employee identity, experience and payroll documents.',
        items: [
          _DocumentCenterItem(
            type: DocumentType.experienceCertificate,
            title: 'Experience Certificate',
            description:
                'Generate staff and teacher experience certificates manually.',
            icon: Icons.history_edu_outlined,
            status: _DocumentStatus.ready,
          ),
          _DocumentCenterItem(
            type: DocumentType.employeeCard,
            title: 'Employee Cards',
            description: 'Generate staff and teacher identity cards.',
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
      builder: (context, constraints) {
        const title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document Center',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Create, preview and manage school documents through one universal engine.',
              style: TextStyle(color: _textSecondary, fontSize: 13),
            ),
          ],
        );

        if (constraints.maxWidth < 720) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardNavigationButton(),
              SizedBox(height: 10),
              title,
            ],
          );
        }

        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardNavigationButton(),
            SizedBox(width: 12),
            Expanded(child: title),
          ],
        );
      },
    );
  }
}

class _SearchAndCategories extends StatelessWidget {
  const _SearchAndCategories({
    required this.controller,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final _DocumentCategory selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_DocumentCategory> onCategoryChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            labelText: 'Search Documents',
            hintText: 'Search fee, result, certificate, ID card...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: onClear,
                    icon: const Icon(Icons.close),
                  ),
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final category in _DocumentCategory.values)
              ChoiceChip(
                label: Text(category.label),
                selected: selectedCategory == category,
                onSelected: (_) => onCategoryChanged(category),
              ),
          ],
        ),
      ],
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 56),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_outlined,
              size: 56,
              color: _textSecondary,
            ),
            const SizedBox(height: 12),
            const Text(
              'No documents found.',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try another search or category.',
              style: TextStyle(color: _textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.refresh),
              label: const Text('Show All Documents'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentGroupSection extends StatelessWidget {
  const _DocumentGroupSection({required this.group});

  final _DocumentGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.title,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          group.subtitle,
          style: const TextStyle(color: _textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth >= 1150
                ? (constraints.maxWidth - 48) / 5
                : constraints.maxWidth >= 900
                ? (constraints.maxWidth - 36) / 4
                : constraints.maxWidth >= 680
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final item in group.items)
                  SizedBox(
                    width: itemWidth,
                    child: _DocumentTypeCard(item: item),
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
  const _DocumentTypeCard({required this.item});

  final _DocumentCenterItem item;

  @override
  Widget build(BuildContext context) {
    final ready = item.status == _DocumentStatus.ready;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _open(context),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: _borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _brandBlue.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(item.icon, color: _brandBlue, size: 19),
                  ),
                  const Spacer(),
                  _StatusBadge(status: item.status),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                item.title,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.description,
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 11,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    ready ? 'Open' : 'View',
                    style: const TextStyle(
                      color: _brandBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.arrow_forward, size: 14, color: _brandBlue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    switch (item.type) {
      case DocumentType.birthdayCard:
        _push(context, const SchoolEngagementPage());
        return;

      case DocumentType.characterCertificate:
      case DocumentType.bonafideCertificate:
      case DocumentType.leavingCertificate:
      case DocumentType.idCard:
        _push(context, const StudentsPage());
        return;

      case DocumentType.resultCard:
        _push(context, const ReportCardsPage());
        return;

      case DocumentType.meritCertificate:
        _push(context, const MeritListPage());
        return;

      case DocumentType.feeChallan:
        _push(context, const FeeChallanPage());
        return;

      case DocumentType.feeReceipt:
        _push(context, const FeeCollectionPage());
        return;

      case DocumentType.experienceCertificate:
        _push(context, const ExperienceCertificatePreviewPage());
        return;

      case DocumentType.employeeCard:
        _push(context, const EmployeeCardPreviewPage());
        return;

      case DocumentType.salarySlip:
        _push(context, const SalarySlipPreviewPage());
        return;
    }
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _DocumentStatus status;

  @override
  Widget build(BuildContext context) {
    final ready = status == _DocumentStatus.ready;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: ready ? _successBackground : _pageBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        ready ? 'Ready' : 'Foundation Ready',
        style: TextStyle(
          color: ready ? _successGreen : _textSecondary,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum _DocumentStatus { ready, foundationReady }

enum _DocumentCategory { all, student, academic, staff }

extension _DocumentCategoryX on _DocumentCategory {
  String get label {
    return switch (this) {
      _DocumentCategory.all => 'All',
      _DocumentCategory.student => 'Student',
      _DocumentCategory.academic => 'Academic',
      _DocumentCategory.staff => 'Staff',
    };
  }
}

class _DocumentGroup {
  const _DocumentGroup({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final _DocumentCategory category;
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
