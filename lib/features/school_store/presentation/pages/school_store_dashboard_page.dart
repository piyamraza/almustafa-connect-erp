import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../domain/entities/store_item_entity.dart';
import '../bloc/school_store_bloc.dart';
import '../bloc/school_store_event.dart';
import '../bloc/school_store_state.dart';
import 'store_purchases_page.dart';
import 'store_sales_page.dart';
import 'store_payments_page.dart';
import 'store_reports_page.dart';

class SchoolStoreDashboardPage extends StatelessWidget {
  const SchoolStoreDashboardPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<SchoolStoreBloc>()..add(const LoadSchoolStore()),
    child: const _View(),
  );
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final _searchController = TextEditingController();
  StoreItemCategory? _category;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F7FC),
    appBar: AppBar(
      title: const Text('School Store'),
      actions: const [DashboardNavigationButton()],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _dialog(context),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add Item'),
    ),
    body: BlocConsumer<SchoolStoreBloc, SchoolStoreState>(
      listener: (c, s) {
        if (s is SchoolStoreLoaded && s.message != null) {
          ScaffoldMessenger.of(
            c,
          ).showSnackBar(SnackBar(content: Text(s.message!)));
        }
      },
      builder: (c, s) {
        if (s is SchoolStoreInitial || s is SchoolStoreLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (s is SchoolStoreFailure) {
          return Center(child: Text(s.message));
        }
        final data = s as SchoolStoreLoaded;
        final query = _searchController.text.trim().toLowerCase();
        final items = data.items.where((item) {
          final matchesQuery =
              query.isEmpty ||
              '${item.name} ${item.itemCode} ${item.category.name}'
                  .toLowerCase()
                  .contains(query);
          return matchesQuery &&
              (_category == null || item.category == _category);
        }).toList();
        final profitValue = data.items.fold<double>(
          0,
          (sum, item) => sum + item.unitProfit * item.currentStock,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final kpiColumns = constraints.maxWidth >= 1050
                ? 4
                : constraints.maxWidth >= 620
                ? 2
                : 4;
            final itemColumns = constraints.maxWidth >= 1220
                ? 3
                : constraints.maxWidth >= 760
                ? 2
                : 1;
            return ListView(
              padding: EdgeInsets.fromLTRB(
                compact ? 10 : 20,
                compact ? 10 : 20,
                compact ? 10 : 20,
                100,
              ),
              children: [
                const _StoreHero(),
                const SizedBox(height: 18),
                GridView.count(
                  crossAxisCount: kpiColumns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: compact ? 6 : 14,
                  mainAxisSpacing: compact ? 6 : 14,
                  mainAxisExtent: compact ? 92 : null,
                  childAspectRatio: compact ? 1 : 2.65,
                  children: [
                    _StoreKpi(
                      'Total Items',
                      '${data.items.length}',
                      Icons.inventory_2_rounded,
                      const Color(0xFF246BFD),
                    ),
                    _StoreKpi(
                      'Units in Stock',
                      '${data.totalStock}',
                      Icons.warehouse_rounded,
                      const Color(0xFF0AA47A),
                    ),
                    _StoreKpi(
                      'Low Stock',
                      '${data.lowStockItems}',
                      Icons.warning_amber_rounded,
                      const Color(0xFFEF6C45),
                    ),
                    _StoreKpi(
                      'Stock Value',
                      'Rs. ${data.stockValue.toStringAsFixed(0)}',
                      Icons.account_balance_wallet_rounded,
                      const Color(0xFF8B5CF6),
                      helper:
                          'Potential margin Rs. ${profitValue.toStringAsFixed(0)}',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Store Operations',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14213D),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: compact ? 6 : 14,
                  mainAxisSpacing: compact ? 6 : 14,
                  mainAxisExtent: compact ? 98 : 118,
                  children: [
                    _StoreAction(
                      'Suppliers & Purchases',
                      Icons.local_shipping_rounded,
                      const Color(0xFF246BFD),
                      () => _open(c, const StorePurchasesPage()),
                    ),
                    _StoreAction(
                      'Student Sales',
                      Icons.point_of_sale_rounded,
                      const Color(0xFF0AA47A),
                      () => _open(c, const StoreSalesPage()),
                    ),
                    _StoreAction(
                      'Payments & Outstanding',
                      Icons.payments_rounded,
                      const Color(0xFFF59E0B),
                      () => _open(c, const StorePaymentsPage()),
                    ),
                    _StoreAction(
                      'Reports',
                      Icons.bar_chart_rounded,
                      const Color(0xFF8B5CF6),
                      () => _open(c, const StoreReportsPage()),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Inventory',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF14213D),
                        ),
                      ),
                    ),
                    Text(
                      '${items.length} items',
                      style: TextStyle(color: Colors.blueGrey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StoreFilters(
                  controller: _searchController,
                  category: _category,
                  onSearch: (_) => setState(() {}),
                  onCategory: (value) => setState(() => _category = value),
                  onClear: () => setState(() {
                    _searchController.clear();
                    _category = null;
                  }),
                ),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  const _EmptyInventory()
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: itemColumns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: compact ? 118 : 164,
                    ),
                    itemBuilder: (_, index) => _InventoryCard(
                      item: items[index],
                      onTap: () => _dialog(c, existing: items[index]),
                    ),
                  ),
              ],
            );
          },
        );
      },
    ),
  );

  static void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  static Future<void> _dialog(
    BuildContext context, {
    StoreItemEntity? existing,
  }) async {
    final n = TextEditingController(text: existing?.name ?? '');
    final p = TextEditingController(
      text: existing?.purchasePrice.toString() ?? '',
    );
    final s = TextEditingController(text: existing?.salePrice.toString() ?? '');
    final o = TextEditingController(
      text: existing?.openingStock.toString() ?? '',
    );
    final l = TextEditingController(
      text: existing?.lowStockLevel.toString() ?? '5',
    );
    var category = existing?.category ?? StoreItemCategory.stationery;
    final save = await showDialog<bool>(
      context: context,
      builder: (dc) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(existing == null ? 'Add Item' : 'Edit Item'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: n,
                  decoration: const InputDecoration(labelText: 'Item Name'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<StoreItemCategory>(
                  initialValue: category,
                  items: StoreItemCategory.values
                      .map(
                        (e) => DropdownMenuItem(value: e, child: Text(e.name)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) set(() => category = v);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: p,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Purchase Price',
                    prefixText: 'Rs. ',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: s,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sale Price',
                    prefixText: 'Rs. ',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: o,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Opening Stock'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: l,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Low Stock Level',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dc, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dc, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (save == true && context.mounted) {
      final now = DateTime.now();
      context.read<SchoolStoreBloc>().add(
        SaveStoreItemRequested(
          StoreItemEntity(
            id: existing?.id ?? 'store_item_${now.microsecondsSinceEpoch}',
            name: n.text.trim(),
            category: category,
            purchasePrice: double.tryParse(p.text) ?? 0,
            salePrice: double.tryParse(s.text) ?? 0,
            openingStock: int.tryParse(o.text) ?? 0,
            purchasedQuantity: existing?.purchasedQuantity ?? 0,
            soldQuantity: existing?.soldQuantity ?? 0,
            lowStockLevel: int.tryParse(l.text) ?? 0,
            isActive: true,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
          ),
        ),
      );
    }
    n.dispose();
    p.dispose();
    s.dispose();
    o.dispose();
    l.dispose();
  }
}

class _StoreHero extends StatelessWidget {
  const _StoreHero();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 104 : 136),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 18 : 26,
        vertical: compact ? 16 : 0,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF176BEF), Color(0xFF0B3D91)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30176BEF),
            blurRadius: 25,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 37,
            ),
          ),
          SizedBox(width: compact ? 14 : 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'School Store Command Center',
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 20 : 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Inventory, purchases, student sales and payments in one place.',
                    style: TextStyle(color: Color(0xFFE8F1FF), fontSize: 15),
                  ),
                ],
              ],
            ),
          ),
          if (!compact)
            Icon(
              Icons.shopping_bag_rounded,
              size: 98,
              color: Colors.white.withValues(alpha: .08),
            ),
        ],
      ),
    );
  }
}

class _StoreKpi extends StatelessWidget {
  const _StoreKpi(this.label, this.value, this.icon, this.color, {this.helper});
  final String label, value;
  final IconData icon;
  final Color color;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;
    return Container(
      padding: EdgeInsets.all(compact ? 6 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: color.withValues(alpha: .18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: compact
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 17),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF14213D),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.blueGrey.shade600,
                    fontSize: 7.5,
                    height: 1.05,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF14213D),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        label,
                        style: TextStyle(color: Colors.blueGrey.shade600),
                      ),
                      if (helper != null)
                        Text(
                          helper!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
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
}

class _StoreAction extends StatelessWidget {
  const _StoreAction(this.label, this.icon, this.color, this.onTap);
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;
    return Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: compact ? 98 : 118,
        padding: EdgeInsets.all(compact ? 6 : 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: .22)),
        ),
        child: compact
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 19),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF14213D),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF14213D),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.arrow_forward_rounded, color: color, size: 19),
                ],
              ),
        ),
      ),
    );
  }
}

class _StoreFilters extends StatelessWidget {
  const _StoreFilters({
    required this.controller,
    required this.category,
    required this.onSearch,
    required this.onCategory,
    required this.onClear,
  });
  final TextEditingController controller;
  final StoreItemCategory? category;
  final ValueChanged<String> onSearch;
  final ValueChanged<StoreItemCategory?> onCategory;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE0E7F2)),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 360,
            child: TextField(
              controller: controller,
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: 'Search item, code or category...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF7F9FD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 210,
            child: DropdownButtonFormField<StoreItemCategory?>(
              initialValue: category,
              decoration: InputDecoration(
                labelText: 'Category',
                filled: true,
                fillColor: const Color(0xFFF7F9FD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Categories'),
                ),
                ...StoreItemCategory.values.map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(_categoryLabel(value)),
                  ),
                ),
              ],
              onChanged: onCategory,
            ),
          ),
          if (controller.text.isNotEmpty || category != null)
            const SizedBox(width: 8),
          if (controller.text.isNotEmpty || category != null)
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off_rounded),
              label: const Text('Clear'),
            ),
        ],
      ),
    ),
  );
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.item, required this.onTap});
  final StoreItemEntity item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final low = item.isLowStock;
    final color = low ? const Color(0xFFEF4444) : const Color(0xFF0AA47A);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: color.withValues(alpha: .2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0B173D6B),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF246BFD).withValues(alpha: .11),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: Color(0xFF246BFD),
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF14213D),
                          ),
                        ),
                        Text(
                          _categoryLabel(item.category),
                          style: TextStyle(color: Colors.blueGrey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      low ? 'Low Stock' : 'In Stock',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  _InventoryValue(
                    'Purchase',
                    'Rs. ${item.purchasePrice.toStringAsFixed(0)}',
                  ),
                  _InventoryValue(
                    'Sale',
                    'Rs. ${item.salePrice.toStringAsFixed(0)}',
                  ),
                  _InventoryValue(
                    'Profit',
                    'Rs. ${item.unitProfit.toStringAsFixed(0)}',
                  ),
                  _InventoryValue(
                    'Stock',
                    '${item.currentStock}',
                    accent: color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryValue extends StatelessWidget {
  const _InventoryValue(this.label, this.value, {this.accent});
  final String label, value;
  final Color? accent;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: accent ?? const Color(0xFF33415C),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory();
  @override
  Widget build(BuildContext context) => Container(
    height: 180,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE0E7F2)),
    ),
    child: const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inventory_2_outlined, size: 44, color: Color(0xFF94A3B8)),
        SizedBox(height: 9),
        Text(
          'No inventory items found.',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
      ],
    ),
  );
}

String _categoryLabel(StoreItemCategory category) => switch (category) {
  StoreItemCategory.book => 'Books',
  StoreItemCategory.copy => 'Copies',
  StoreItemCategory.diary => 'Diaries',
  StoreItemCategory.stationery => 'Stationery',
  StoreItemCategory.other => 'Other',
};
