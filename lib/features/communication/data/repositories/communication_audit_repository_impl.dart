import '../../domain/entities/communication_audit_entry_entity.dart';
import '../../domain/repositories/communication_audit_repository.dart';
import '../datasources/communication_audit_remote_datasource.dart';

class CommunicationAuditRepositoryImpl implements CommunicationAuditRepository {
  const CommunicationAuditRepositoryImpl(this._source);

  final CommunicationAuditRemoteDataSource _source;

  @override
  Future<List<CommunicationAuditEntryEntity>> getEntries() {
    return _source.getEntries();
  }

  @override
  Future<void> saveEntry(CommunicationAuditEntryEntity entry) {
    return _source.saveEntry(entry);
  }
}
