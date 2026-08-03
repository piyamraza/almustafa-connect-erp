import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../domain/entities/store_student_payment_entity.dart';
import '../../domain/entities/store_supplier_payment_entity.dart';
import '../bloc/store_payment_bloc.dart';
import '../bloc/store_payment_event.dart';
import '../bloc/store_payment_state.dart';

class StorePaymentsPage extends StatelessWidget {
  const StorePaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StorePaymentBloc>()..add(const LoadStorePayments()),
      child: const _StorePaymentsView(),
    );
  }
}

class _StorePaymentsView extends StatelessWidget {
  const _StorePaymentsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments & Outstanding'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocConsumer<StorePaymentBloc, StorePaymentState>(
        listener: (context, state) {
          if (state is StorePaymentLoaded && state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          if (state is StorePaymentInitial || state is StorePaymentLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StorePaymentFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as StorePaymentLoaded;
          final studentDue = _studentDue(data);
          final supplierDue = _supplierDue(data);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  Chip(
                    label: Text(
                      'Student Due Rs. ${data.studentOutstanding.toStringAsFixed(0)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Supplier Due Rs. ${data.supplierOutstanding.toStringAsFixed(0)}',
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: studentDue.isEmpty
                        ? null
                        : () => _receiveStudent(context, studentDue),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Receive Student Payment'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: supplierDue.isEmpty
                        ? null
                        : () => _paySupplier(context, supplierDue),
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: const Text('Pay Supplier'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Student Outstanding',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ...studentDue.values.map(
                (value) => Card(
                  child: ListTile(
                    title: Text(value.name),
                    subtitle: Text(value.admissionNo),
                    trailing: Text('Rs. ${value.amount.toStringAsFixed(0)}'),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Supplier Outstanding',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ...supplierDue.values.map(
                (value) => Card(
                  child: ListTile(
                    title: Text(value.name),
                    trailing: Text('Rs. ${value.amount.toStringAsFixed(0)}'),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Recent Student Payments',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ...data.studentPayments
                  .take(20)
                  .map(
                    (payment) => Card(
                      child: ListTile(
                        title: Text(payment.studentName),
                        subtitle: Text(payment.receiptNumber),
                        trailing: Text(
                          'Rs. ${payment.amount.toStringAsFixed(0)}',
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 18),
              Text(
                'Recent Supplier Payments',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ...data.supplierPayments
                  .take(20)
                  .map(
                    (payment) => Card(
                      child: ListTile(
                        title: Text(payment.supplierName),
                        subtitle: Text(payment.referenceNumber),
                        trailing: Text(
                          'Rs. ${payment.amount.toStringAsFixed(0)}',
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

  static Map<String, _DueParty> _studentDue(StorePaymentLoaded data) {
    final values = <String, _DueParty>{};

    for (final sale in data.sales) {
      if (sale.outstandingAmount <= 0) continue;

      final existing = values[sale.studentId];

      values[sale.studentId] = _DueParty(
        id: sale.studentId,
        name: sale.studentName,
        admissionNo: sale.admissionNo,
        amount: (existing?.amount ?? 0) + sale.outstandingAmount,
      );
    }

    return values;
  }

  static Map<String, _DueParty> _supplierDue(StorePaymentLoaded data) {
    final values = <String, _DueParty>{};

    for (final purchase in data.purchases) {
      if (purchase.outstandingAmount <= 0) continue;

      final existing = values[purchase.supplierId];

      values[purchase.supplierId] = _DueParty(
        id: purchase.supplierId,
        name: purchase.supplierName,
        amount: (existing?.amount ?? 0) + purchase.outstandingAmount,
      );
    }

    return values;
  }

  static Future<void> _receiveStudent(
    BuildContext context,
    Map<String, _DueParty> values,
  ) async {
    var selected = values.values.first;
    final amountController = TextEditingController();
    final receiptController = TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Receive Student Payment'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<_DueParty>(
                  initialValue: selected,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Student'),
                  items: values.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            '${value.name} - Due Rs. ${value.amount.toStringAsFixed(0)}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selected = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount Received',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: receiptController,
                  decoration: const InputDecoration(
                    labelText: 'Receipt Number',
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
              child: const Text('Receive'),
            ),
          ],
        ),
      ),
    );

    if (save == true && context.mounted) {
      final now = DateTime.now();

      context.read<StorePaymentBloc>().add(
        ReceiveStudentPaymentRequested(
          StoreStudentPaymentEntity(
            id: 'student_payment_${now.microsecondsSinceEpoch}',
            studentId: selected.id,
            studentName: selected.name,
            admissionNo: selected.admissionNo,
            amount: double.tryParse(amountController.text) ?? 0,
            paymentDate: now,
            createdAt: now,
            receiptNumber: receiptController.text.trim(),
          ),
        ),
      );
    }

    amountController.dispose();
    receiptController.dispose();
  }

  static Future<void> _paySupplier(
    BuildContext context,
    Map<String, _DueParty> values,
  ) async {
    var selected = values.values.first;
    final amountController = TextEditingController();
    final referenceController = TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pay Supplier'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<_DueParty>(
                  initialValue: selected,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Supplier'),
                  items: values.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            '${value.name} - Due Rs. ${value.amount.toStringAsFixed(0)}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selected = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount Paid'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Reference Number',
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
              child: const Text('Pay'),
            ),
          ],
        ),
      ),
    );

    if (save == true && context.mounted) {
      final now = DateTime.now();

      context.read<StorePaymentBloc>().add(
        PaySupplierRequested(
          StoreSupplierPaymentEntity(
            id: 'supplier_payment_${now.microsecondsSinceEpoch}',
            supplierId: selected.id,
            supplierName: selected.name,
            amount: double.tryParse(amountController.text) ?? 0,
            paymentDate: now,
            createdAt: now,
            referenceNumber: referenceController.text.trim(),
          ),
        ),
      );
    }

    amountController.dispose();
    referenceController.dispose();
  }
}

class _DueParty {
  const _DueParty({
    required this.id,
    required this.name,
    required this.amount,
    this.admissionNo = '',
  });

  final String id;
  final String name;
  final String admissionNo;
  final double amount;
}
