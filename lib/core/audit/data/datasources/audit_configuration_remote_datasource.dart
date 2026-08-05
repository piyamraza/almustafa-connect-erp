import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/audit_configuration_entity.dart';
import '../models/audit_configuration_model.dart';

abstract class AuditConfigurationRemoteDataSource {
  Future<AuditConfigurationModel> getConfiguration();

  Stream<AuditConfigurationModel> watchConfiguration();

  Future<void> saveConfiguration(AuditConfigurationEntity configuration);
}

class AuditConfigurationRemoteDataSourceImpl
    implements AuditConfigurationRemoteDataSource {
  AuditConfigurationRemoteDataSourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _collectionName = 'system_settings';
  static const String _documentId = 'audit_configuration';

  DocumentReference<Map<String, dynamic>> get _document {
    return _firestore.collection(_collectionName).doc(_documentId);
  }

  @override
  Future<AuditConfigurationModel> getConfiguration() async {
    final snapshot = await _document.get();

    if (!snapshot.exists || snapshot.data() == null) {
      final defaultConfiguration =
          AuditConfigurationEntity.defaultConfiguration();

      await saveConfiguration(defaultConfiguration);

      return AuditConfigurationModel.fromEntity(defaultConfiguration);
    }

    return AuditConfigurationModel.fromMap(snapshot.data()!);
  }

  @override
  Stream<AuditConfigurationModel> watchConfiguration() {
    return _document.snapshots().map((snapshot) {
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return AuditConfigurationModel.fromEntity(
          AuditConfigurationEntity.defaultConfiguration(),
        );
      }

      return AuditConfigurationModel.fromMap(data);
    });
  }

  @override
  Future<void> saveConfiguration(AuditConfigurationEntity configuration) async {
    final model = AuditConfigurationModel.fromEntity(
      configuration.copyWith(updatedAt: DateTime.now()),
    );

    await _document.set(model.toMap(), SetOptions(merge: true));
  }
}
