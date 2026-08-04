import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../domain/entities/store_item_entity.dart';
import '../../domain/entities/store_sale_entity.dart';
import '../../domain/entities/store_student_option_entity.dart';
import '../bloc/store_sale_bloc.dart';
import '../bloc/store_sale_event.dart';
import '../bloc/store_sale_state.dart';

class StoreSalesPage extends StatelessWidget {
  const StoreSalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StoreSaleBloc>()..add(const LoadStoreSales()),
      child: const _StoreSalesView(),
    );
  }
}

class _StoreSalesView extends StatelessWidget {
  const _StoreSalesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Sales'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocConsumer<StoreSaleBloc, StoreSaleState>(
        listener: (context, state) {
          if (state is StoreSaleLoaded && state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          if (state is StoreSaleInitial || state is StoreSaleLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StoreSaleFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as StoreSaleLoaded;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  Chip(
                    label: Text(
                      'Sales Rs. ${data.totalSales.toStringAsFixed(0)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Received Rs. ${data.totalReceived.toStringAsFixed(0)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Credit Rs. ${data.totalOutstanding.toStringAsFixed(0)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Profit Rs. ${data.totalProfit.toStringAsFixed(0)}',
                    ),
                  ),
                  FilledButton.icon(
                    onPressed:
                        data.students.isEmpty ||
                            data.items
                                .where(
                                  (item) =>
                                      item.currentStock > 0 && item.isActive,
                                )
                                .isEmpty
                        ? null
                        : () => _showSaleDialog(context, data),
                    icon: const Icon(Icons.point_of_sale),
                    label: const Text('New Student Sale'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Student Outstanding',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ..._studentLedgers(data.sales).entries.map(
                (entry) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.school_outlined),
                    ),
                    title: Text(entry.value.name),
                    subtitle: Text(
                      entry.value.admissionNo.isEmpty
                          ? 'Student Ledger'
                          : entry.value.admissionNo,
                    ),
                    trailing: Text(
                      'Due Rs. ${entry.value.outstanding.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Sales History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (data.sales.isEmpty)
                const Card(
                  child: ListTile(title: Text('No student sales found.')),
                ),
              ...data.sales.map(
                (sale) => Card(
                  child: ListTile(
                    title: Text(sale.itemName),
                    subtitle: Text(
                      '${sale.studentName} - '
                      '${sale.admissionNo} - '
                      'Qty ${sale.quantity} - '
                      '${sale.paymentStatus.name}',
                    ),
                    trailing: Text(
                      'Due Rs. ${sale.outstandingAmount.toStringAsFixed(0)}',
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

  static Map<String, _StudentLedger> _studentLedgers(
    List<StoreSaleEntity> sales,
  ) {
    final values = <String, _StudentLedger>{};

    for (final sale in sales) {
      if (sale.outstandingAmount <= 0) continue;

      final existing = values[sale.studentId];

      values[sale.studentId] = _StudentLedger(
        name: sale.studentName,
        admissionNo: sale.admissionNo,
        outstanding: (existing?.outstanding ?? 0) + sale.outstandingAmount,
      );
    }

    return values;
  }

  static Future<void> _showSaleDialog(
    BuildContext context,
    StoreSaleLoaded data,
  ) async {
    var student = data.students.first;
    final studentController = TextEditingController(text: student.name);
    final availableItems = data.items
        .where((item) => item.currentStock > 0 && item.isActive)
        .toList();
    var item = availableItems.first;

    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController(
      text: item.salePrice.toString(),
    );
    final discountController = TextEditingController(text: '0');
    final paidController = TextEditingController(text: '0');

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Student Sale'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: studentController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Student',
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    onTap: () async {
                      final selected = await _selectStudent(
                        dialogContext,
                        data.students,
                        selected: student,
                      );
                      if (selected != null) {
                        setDialogState(() {
                          student = selected;
                          studentController.text = selected.name;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<StoreItemEntity>(
                    initialValue: item,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Item'),
                    items: availableItems
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(
                              '${value.name} - Stock ${value.currentStock}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          item = value;
                          priceController.text = value.salePrice.toString();
                        });
                      }
                    },
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
                      labelText: 'Unit Sale Price',
                      prefixText: 'Rs. ',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Discount',
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
                      helperText: 'Enter 0 for full credit sale.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save Sale'),
            ),
          ],
        ),
      ),
    );

    if (save == true && context.mounted) {
      final now = DateTime.now();

      context.read<StoreSaleBloc>().add(
        SaveStoreSaleRequested(
          StoreSaleEntity(
            id: 'store_sale_${now.microsecondsSinceEpoch}',
            studentId: student.id,
            studentName: student.name,
            admissionNo: student.admissionNo,
            classId: student.classId,
            sectionId: student.sectionId,
            itemId: item.id,
            itemName: item.name,
            quantity: int.tryParse(quantityController.text) ?? 0,
            unitSalePrice: double.tryParse(priceController.text) ?? 0,
            unitPurchasePrice: item.purchasePrice,
            discount: double.tryParse(discountController.text) ?? 0,
            paidAmount: double.tryParse(paidController.text) ?? 0,
            saleDate: now,
            createdAt: now,
            updatedAt: now,
          ),
        ),
      );
    }

    quantityController.dispose();
    studentController.dispose();
    priceController.dispose();
    discountController.dispose();
    paidController.dispose();
  }

  static Future<StoreStudentOptionEntity?> _selectStudent(
    BuildContext context,
    List<StoreStudentOptionEntity> students, {
    required StoreStudentOptionEntity selected,
  }) {
    final searchController = TextEditingController();
    var query = '';
    return showDialog<StoreStudentOptionEntity>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final normalizedQuery = query.trim().toLowerCase();
          final filtered = students
              .where((student) {
                final searchable = [
                  student.name,
                  student.fatherName,
                  student.className,
                  student.rollNumber,
                ].join(' ').toLowerCase();
                return searchable.contains(normalizedQuery);
              })
              .toList(growable: false);

          return AlertDialog(
            title: const Text('Select Student'),
            content: SizedBox(
              width: 600,
              height: 500,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Search by student name',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setDialogState(() => query = value),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No student found.'))
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final student = filtered[index];
                              return ListTile(
                                selected: student.id == selected.id,
                                title: Text(student.name),
                                subtitle: Text(
                                  'Father: ${student.fatherName.isEmpty ? '-' : student.fatherName}\n'
                                  'Class: ${student.className.isEmpty ? '-' : student.className}    '
                                  'Roll No: ${student.rollNumber.isEmpty ? '-' : student.rollNumber}',
                                ),
                                isThreeLine: true,
                                onTap: () =>
                                    Navigator.pop(dialogContext, student),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(searchController.dispose);
  }
}

class _StudentLedger {
  const _StudentLedger({
    required this.name,
    required this.admissionNo,
    required this.outstanding,
  });

  final String name;
  final String admissionNo;
  final double outstanding;
}
