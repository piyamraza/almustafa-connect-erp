import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../domain/entities/store_item_entity.dart';
import '../../domain/entities/store_purchase_entity.dart';
import '../../domain/entities/store_supplier_entity.dart';
import '../bloc/store_purchase_bloc.dart';
import '../bloc/store_purchase_event.dart';
import '../bloc/store_purchase_state.dart';

class StorePurchasesPage extends StatelessWidget {
  const StorePurchasesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StorePurchaseBloc>()..add(const LoadStorePurchases()),
      child: const _StorePurchasesView(),
    );
  }
}

class _StorePurchasesView extends StatelessWidget {
  const _StorePurchasesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers & Purchases'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocConsumer<StorePurchaseBloc, StorePurchaseState>(
        listener: (context, state) {
          if (state is StorePurchaseLoaded && state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          if (state is StorePurchaseInitial || state is StorePurchaseLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StorePurchaseFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as StorePurchaseLoaded;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  Chip(label: Text('Suppliers: ${data.suppliers.length}')),
                  Chip(
                    label: Text(
                      'Purchases: Rs. ${data.totalPurchases.toStringAsFixed(0)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Paid: Rs. ${data.totalPaid.toStringAsFixed(0)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Due: Rs. ${data.outstanding.toStringAsFixed(0)}',
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _showSupplierDialog(context),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add Supplier'),
                  ),
                  FilledButton.icon(
                    onPressed: data.suppliers.isEmpty || data.items.isEmpty
                        ? null
                        : () => _showPurchaseDialog(context, data),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('New Purchase'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Supplier Ledger',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ...data.suppliers.map((supplier) {
                final purchases = data.purchases.where(
                  (item) => item.supplierId == supplier.id,
                );

                final total = purchases.fold<double>(
                  0,
                  (sum, item) => sum + item.totalAmount,
                );

                final paid = purchases.fold<double>(
                  0,
                  (sum, item) => sum + item.paidAmount,
                );

                return Card(
                  child: ListTile(
                    title: Text(supplier.name),
                    subtitle: Text(
                      'Purchase Rs. ${total.toStringAsFixed(0)} - '
                      'Paid Rs. ${paid.toStringAsFixed(0)}',
                    ),
                    trailing: Text(
                      'Due Rs. ${(total - paid).toStringAsFixed(0)}',
                    ),
                  ),
                );
              }),
              const SizedBox(height: 18),
              Text(
                'Purchase History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (data.purchases.isEmpty)
                const Card(child: ListTile(title: Text('No purchases found.'))),
              ...data.purchases.map(
                (purchase) => Card(
                  child: ListTile(
                    title: Text(purchase.itemName),
                    subtitle: Text(
                      '${purchase.supplierName} - '
                      'Qty ${purchase.quantity} - '
                      '${purchase.invoiceNumber}',
                    ),
                    trailing: Text(
                      'Rs. ${purchase.totalAmount.toStringAsFixed(0)}',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _showSupplierDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Supplier Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: mobileController,
              decoration: const InputDecoration(labelText: 'Mobile Number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (save == true && context.mounted) {
      final now = DateTime.now();

      context.read<StorePurchaseBloc>().add(
        SaveStoreSupplierRequested(
          StoreSupplierEntity(
            id: 'supplier_${now.microsecondsSinceEpoch}',
            name: nameController.text.trim(),
            mobileNumber: mobileController.text.trim(),
            createdAt: now,
            updatedAt: now,
          ),
        ),
      );
    }

    nameController.dispose();
    mobileController.dispose();
  }

  static Future<void> _showPurchaseDialog(
    BuildContext context,
    StorePurchaseLoaded data,
  ) async {
    var supplier = data.suppliers.first;
    var item = data.items.first;

    final invoiceController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController(
      text: item.purchasePrice.toString(),
    );
    final paidController = TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Purchase'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<StoreSupplierEntity>(
                  initialValue: supplier,
                  items: data.suppliers
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => supplier = value);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Supplier'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<StoreItemEntity>(
                  initialValue: item,
                  items: data.items
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        item = value;
                        priceController.text = value.purchasePrice.toString();
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Item'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: invoiceController,
                  decoration: const InputDecoration(
                    labelText: 'Invoice Number',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Unit Price',
                    prefixText: 'Rs. ',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: paidController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Paid Amount',
                    prefixText: 'Rs. ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (save == true && context.mounted) {
      final now = DateTime.now();

      context.read<StorePurchaseBloc>().add(
        SaveStorePurchaseRequested(
          StorePurchaseEntity(
            id: 'purchase_${now.microsecondsSinceEpoch}',
            supplierId: supplier.id,
            supplierName: supplier.name,
            itemId: item.id,
            itemName: item.name,
            invoiceNumber: invoiceController.text.trim(),
            quantity: int.tryParse(quantityController.text) ?? 0,
            unitPrice: double.tryParse(priceController.text) ?? 0,
            paidAmount: double.tryParse(paidController.text) ?? 0,
            purchaseDate: now,
            createdAt: now,
            updatedAt: now,
          ),
        ),
      );
    }

    invoiceController.dispose();
    quantityController.dispose();
    priceController.dispose();
    paidController.dispose();
  }
}
