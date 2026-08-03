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

class _View extends StatelessWidget {
  const _View();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('School Store'),
      actions: const [DashboardNavigationButton()],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _dialog(context),
      icon: const Icon(Icons.add),
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
        if (s is SchoolStoreFailure) return Center(child: Text(s.message));
        final d = s as SchoolStoreLoaded;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _card(
                  c,
                  'Items',
                  '${d.items.length}',
                  Icons.inventory_2_outlined,
                ),
                _card(
                  c,
                  'Balance Stock',
                  '${d.totalStock}',
                  Icons.warehouse_outlined,
                ),
                _card(
                  c,
                  'Low Stock',
                  '${d.lowStockItems}',
                  Icons.warning_amber_outlined,
                ),
                _card(
                  c,
                  'Stock Value',
                  'Rs. ${d.stockValue.toStringAsFixed(0)}',
                  Icons.account_balance_wallet_outlined,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(c).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const StorePurchasesPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Suppliers & Purchases'),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(c).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const StoreSalesPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.point_of_sale),
                label: const Text('Student Sales'),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(c).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const StorePaymentsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Payments & Outstanding'),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(c).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const StoreReportsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.bar_chart_outlined),
                label: const Text('Reports'),
              ),
            ),
            const SizedBox(height: 18),
            ...d.items.map(
              (e) => Card(
                child: ListTile(
                  title: Text(e.name),
                  subtitle: Text(
                    '${e.category.name} | Purchase Rs. ${e.purchasePrice.toStringAsFixed(0)} | Sale Rs. ${e.salePrice.toStringAsFixed(0)}',
                  ),
                  trailing: Text('Stock ${e.currentStock}'),
                  onTap: () => _dialog(c, existing: e),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  static Widget _card(BuildContext c, String t, String v, IconData i) =>
      SizedBox(
        width: 220,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(child: Icon(i)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t),
                      Text(
                        v,
                        style: Theme.of(c).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

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
