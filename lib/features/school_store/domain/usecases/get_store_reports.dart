import '../entities/store_item_entity.dart';
import '../entities/store_purchase_entity.dart';
import '../entities/store_report_entity.dart';
import '../entities/store_sale_entity.dart';
import '../repositories/school_store_repository.dart';
import '../repositories/store_payment_repository.dart';
import '../repositories/store_purchase_repository.dart';
import '../repositories/store_sale_repository.dart';

class GetStoreReports {
  const GetStoreReports({
    required this._storeRepository,
    required this._purchaseRepository,
    required this._saleRepository,
    required this._paymentRepository,
  });

  final SchoolStoreRepository _storeRepository;
  final StorePurchaseRepository _purchaseRepository;
  final StoreSaleRepository _saleRepository;
  final StorePaymentRepository _paymentRepository;

  Future<StoreReportEntity> call() async {
    final values = await Future.wait<Object>([
      _storeRepository.getItems(),
      _purchaseRepository.getPurchases(),
      _saleRepository.getSales(),
      _paymentRepository.getStudentPayments(),
      _paymentRepository.getSupplierPayments(),
    ]);

    final items = values[0] as List<StoreItemEntity>;
    final purchases = values[1] as List<StorePurchaseEntity>;
    final sales = values[2] as List<StoreSaleEntity>;

    final totalSales = sales.fold<double>(
      0,
      (sum, sale) => sum + sale.netAmount,
    );

    final totalPurchases = purchases.fold<double>(
      0,
      (sum, purchase) => sum + purchase.totalAmount,
    );

    final totalProfit = sales.fold<double>(
      0,
      (sum, sale) => sum + sale.profitAmount,
    );

    final stockValue = items.fold<double>(
      0,
      (sum, item) => sum + item.stockValue,
    );

    final studentReceivable = sales.fold<double>(
      0,
      (sum, sale) => sum + sale.outstandingAmount,
    );

    final supplierPayable = purchases.fold<double>(
      0,
      (sum, purchase) => sum + purchase.outstandingAmount,
    );

    final itemMovements = items.map((item) {
      final itemSales = sales.where((sale) => sale.itemId == item.id);

      return StoreItemMovementEntity(
        itemId: item.id,
        itemName: item.name,
        openingStock: item.openingStock,
        purchasedQuantity: item.purchasedQuantity,
        soldQuantity: item.soldQuantity,
        currentStock: item.currentStock,
        stockValue: item.stockValue,
        salesAmount: itemSales.fold<double>(
          0,
          (sum, sale) => sum + sale.netAmount,
        ),
        profitAmount: itemSales.fold<double>(
          0,
          (sum, sale) => sum + sale.profitAmount,
        ),
      );
    }).toList()..sort((a, b) => b.soldQuantity.compareTo(a.soldQuantity));

    final studentMap = <String, StorePartyBalanceEntity>{};

    for (final sale in sales) {
      final existing = studentMap[sale.studentId];

      studentMap[sale.studentId] = StorePartyBalanceEntity(
        id: sale.studentId,
        name: sale.studentName,
        reference: sale.admissionNo,
        totalAmount: (existing?.totalAmount ?? 0) + sale.netAmount,
        paidAmount: (existing?.paidAmount ?? 0) + sale.paidAmount,
        outstandingAmount:
            (existing?.outstandingAmount ?? 0) + sale.outstandingAmount,
      );
    }

    final supplierMap = <String, StorePartyBalanceEntity>{};

    for (final purchase in purchases) {
      final existing = supplierMap[purchase.supplierId];

      supplierMap[purchase.supplierId] = StorePartyBalanceEntity(
        id: purchase.supplierId,
        name: purchase.supplierName,
        reference: '',
        totalAmount: (existing?.totalAmount ?? 0) + purchase.totalAmount,
        paidAmount: (existing?.paidAmount ?? 0) + purchase.paidAmount,
        outstandingAmount:
            (existing?.outstandingAmount ?? 0) + purchase.outstandingAmount,
      );
    }

    final studentBalances = studentMap.values.toList()
      ..sort((a, b) => b.outstandingAmount.compareTo(a.outstandingAmount));

    final supplierBalances = supplierMap.values.toList()
      ..sort((a, b) => b.outstandingAmount.compareTo(a.outstandingAmount));

    return StoreReportEntity(
      totalSales: totalSales,
      totalPurchases: totalPurchases,
      totalProfit: totalProfit,
      stockValue: stockValue,
      studentReceivable: studentReceivable,
      supplierPayable: supplierPayable,
      lowStockCount: items.where((item) => item.isLowStock).length,
      itemMovements: itemMovements,
      studentBalances: studentBalances,
      supplierBalances: supplierBalances,
    );
  }
}
