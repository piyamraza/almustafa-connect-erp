import 'package:cloud_firestore/cloud_firestore.dart';

class AccessControlMigrationResult {
  const AccessControlMigrationResult({
    required this.scanned,
    required this.migrated,
    required this.skipped,
    required this.deletedLegacy,
  });

  final int scanned;
  final int migrated;
  final int skipped;
  final int deletedLegacy;
}

class AccessControlMigrationService {
  const AccessControlMigrationService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<AccessControlMigrationResult>
  migrateUserRoleDocumentsToUidIds() async {
    final collection = _firestore.collection('user_roles');
    final snapshot = await collection.get();

    var migrated = 0;
    var skipped = 0;
    var deletedLegacy = 0;

    for (final document in snapshot.docs) {
      final data = document.data();
      final userId = data['userId']?.toString().trim() ?? '';

      if (userId.isEmpty) {
        skipped++;
        continue;
      }

      if (document.id == userId) {
        skipped++;
        continue;
      }

      await _firestore.runTransaction((transaction) async {
        final canonical = collection.doc(userId);
        final canonicalSnapshot = await transaction.get(canonical);

        if (!canonicalSnapshot.exists) {
          transaction.set(canonical, data);
        } else {
          transaction.set(canonical, data, SetOptions(merge: true));
        }

        transaction.delete(document.reference);
      });

      migrated++;
      deletedLegacy++;
    }

    return AccessControlMigrationResult(
      scanned: snapshot.docs.length,
      migrated: migrated,
      skipped: skipped,
      deletedLegacy: deletedLegacy,
    );
  }

  Future<List<String>> validateProductionReadiness() async {
    final issues = <String>[];

    final roles = await _firestore.collection('app_roles').get();
    if (roles.docs.isEmpty) {
      issues.add('No app_roles documents found.');
    }

    final assignments = await _firestore.collection('user_roles').get();

    if (assignments.docs.isEmpty) {
      issues.add('No user_roles assignments found.');
    }

    for (final document in assignments.docs) {
      final data = document.data();
      final userId = data['userId']?.toString().trim() ?? '';
      final roleId = data['roleId']?.toString().trim() ?? '';

      if (userId.isEmpty) {
        issues.add('Assignment ${document.id} has no Firebase userId.');
      } else if (document.id != userId) {
        issues.add(
          'Assignment ${document.id} is not stored as user_roles/$userId.',
        );
      }

      if (roleId.isEmpty) {
        issues.add('Assignment ${document.id} has no roleId.');
      } else {
        final role = await _firestore.collection('app_roles').doc(roleId).get();
        if (!role.exists) {
          issues.add(
            'Assignment ${document.id} references missing role $roleId.',
          );
        }
      }
    }

    final superAdmins = assignments.docs.where((document) {
      final data = document.data();
      return data['roleId'] == 'super_admin' && data['isActive'] == true;
    });

    if (superAdmins.isEmpty) {
      issues.add(
        'No active Super Admin assignment found. Do not deploy rules.',
      );
    }

    return issues;
  }
}
