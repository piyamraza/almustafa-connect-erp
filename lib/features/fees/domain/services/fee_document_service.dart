import '../entities/fee_document_request_entity.dart';

abstract class FeeDocumentService {
  Future<void> printChallan(FeeChallanDocumentRequest request);

  Future<void> shareChallan(FeeChallanDocumentRequest request);

  Future<void> printReceipt(FeeReceiptDocumentRequest request);

  Future<void> shareReceipt(FeeReceiptDocumentRequest request);
}
