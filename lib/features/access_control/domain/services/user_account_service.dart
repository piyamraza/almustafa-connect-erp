import '../entities/user_account_entity.dart';

class CreatedUserAccount {
  const CreatedUserAccount({
    required this.uid,
    required this.email,
    required this.username,
    required this.displayName,
    required this.roleName,
  });

  final String uid;
  final String email;
  final String username;
  final String displayName;
  final String roleName;
}

abstract class UserAccountService {
  Future<void> bootstrapAdministration();

  Future<List<UserAccountEntity>> listAccounts();

  Future<List<UserAccountEntity>> listChatParticipants();

  Future<CreatedUserAccount> createAccount({
    required String displayName,
    required String login,
    required String password,
    required String roleId,
    required String roleName,
    required String branchId,
    String linkedEntityType,
    String linkedEntityId,
  });

  Future<void> setDisabled({required String uid, required bool disabled});

  Future<void> deleteAccount({required String uid});

  Future<void> updateAccount({
    required String uid,
    required String displayName,
    required String login,
    required String branchId,
    required String linkedEntityType,
    required String linkedEntityId,
  });

  Future<void> updateRole({
    required String uid,
    required List<String> roleIds,
    required String primaryRoleId,
    required String branchId,
  });

  Future<String> generatePasswordResetLink(String email);
}
