import '../entities/communication_audit_entry_entity.dart';

abstract class CommunicationAuditRepository {
  Future<List<CommunicationAuditEntryEntity>> getEntries();

  Future<void> saveEntry(CommunicationAuditEntryEntity entry);
}
