import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/entities/user_account_entity.dart';
import '../../domain/services/user_account_service.dart';

class UserAccountServiceImpl implements UserAccountService {
  UserAccountServiceImpl({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  @override
  Future<void> bootstrapAdministration() async {
    await _functions.httpsCallable('bootstrapUserAccountAdministration').call();
  }

  @override
  Future<List<UserAccountEntity>> listAccounts() async {
    final callable = _functions.httpsCallable('listUserAccounts');
    final response = await callable.call<Map<String, dynamic>>({
      'pageSize': 500,
    });

    final data = Map<String, dynamic>.from(response.data);
    final rawUsers = data['users'] as List<dynamic>? ?? const [];

    return rawUsers
        .map(
          (item) =>
              UserAccountEntity.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false)
      ..sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
  }

  @override
  Future<CreatedUserAccount> createAccount({
    required String displayName,
    required String login,
    required String password,
    required String roleId,
    required String roleName,
    required String branchId,
    String linkedEntityType = '',
    String linkedEntityId = '',
  }) async {
    final callable = _functions.httpsCallable('createUserAccount');
    final response = await callable.call<Map<String, dynamic>>({
      'displayName': displayName,
      'login': login,
      'password': password,
      'roleId': roleId,
      'roleName': roleName,
      'branchId': branchId,
      'linkedEntityType': linkedEntityType,
      'linkedEntityId': linkedEntityId,
    });

    final data = Map<String, dynamic>.from(response.data);

    return CreatedUserAccount(
      uid: data['uid']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      username: data['username']?.toString() ?? '',
      displayName: data['displayName']?.toString() ?? '',
      roleName: data['roleName']?.toString() ?? roleName,
    );
  }

  @override
  Future<void> setDisabled({
    required String uid,
    required bool disabled,
  }) async {
    await _functions.httpsCallable('setUserAccountDisabled').call({
      'uid': uid,
      'disabled': disabled,
    });
  }

  @override
  Future<void> updateRole({
    required String uid,
    required String roleId,
    required String roleName,
    required String branchId,
  }) async {
    await _functions.httpsCallable('updateUserAccountRole').call({
      'uid': uid,
      'roleId': roleId,
      'roleName': roleName,
      'branchId': branchId,
    });
  }

  @override
  Future<String> generatePasswordResetLink(String email) async {
    final response = await _functions
        .httpsCallable('generateUserPasswordResetLink')
        .call<Map<String, dynamic>>({'email': email});

    return response.data['link']?.toString() ?? '';
  }
}
