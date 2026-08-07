import '../../../../core/services/firebase_firestore_service.dart';
import '../models/school_branding_model.dart';

abstract class SchoolBrandingRemoteDataSource {
  Future<SchoolBrandingModel?> getBranding();

  Future<void> saveBranding(
    SchoolBrandingModel branding,
  );
}

class SchoolBrandingRemoteDataSourceImpl
    implements SchoolBrandingRemoteDataSource {
  const SchoolBrandingRemoteDataSourceImpl(
    this._firestoreService,
  );

  final FirebaseFirestoreService _firestoreService;

  static const String _collectionName =
      'school_branding';

  static const String _documentId =
      'default';

  @override
  Future<SchoolBrandingModel?> getBranding() async {
    final snapshot = await _firestoreService
        .collection(_collectionName)
        .doc(_documentId)
        .get();

    final data = snapshot.data();

    if (data == null) {
      return null;
    }

    return SchoolBrandingModel.fromMap(data);
  }

  @override
  Future<void> saveBranding(
    SchoolBrandingModel branding,
  ) {
    return _firestoreService
        .collection(_collectionName)
        .doc(_documentId)
        .set(
          branding.toMap(),
        );
  }
}
