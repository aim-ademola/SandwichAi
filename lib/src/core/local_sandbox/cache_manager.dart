import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:sandwich_ai/src/features/auth/data/models/login_model.dart';

class AuthCacheHelper {
  static final AuthCacheHelper _instance = AuthCacheHelper._internal();
  static AuthCacheHelper get instance => _instance;

  AuthCacheHelper._internal();

  static const String _authBox = 'auth_box';

  // Initialize secure storage for sensitive data
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Cache keys for Hive (non-sensitive data)
  static const String _keyAccessToken = 'access_token';
  static const String _keyUserData = 'user_data';
  static const String _keyLoginTimestamp = 'login_timestamp';
  static const String _keyBranchId = 'branch_id';
  static const String _keyOrgId = 'org_id';
  static const String _keyOrgCode = 'org_code';
  static const String _keyOrgName = 'org_name';
  static const String _keyDptName = 'department_name';
  static const String _keyEmpId = 'employee_id';
  static const String _keyBranchName = 'branch_name';
  static const String _keyRememberMe = 'remember_me';
  static const String _userId = 'user_id';

  // Secure storage keys (sensitive data)
  static const String _secureKeyEmail = 'secure_email';
  static const String _secureKeyPassword = 'secure_password';
  static const String _secureKeyOrgCode = 'secure_org_code';

  Box<dynamic> get _box => Hive.box(_authBox);

  /// Store remembered credentials securely
  Future<void> storeRememberedCredentials({
    required String email,
    required String password,
    required String organizationCode,
    required bool rememberMe,
  }) async {
    try {
      await _box.put(_keyRememberMe, rememberMe);

      if (rememberMe) {
        // Store sensitive data in secure storage
        await _secureStorage.write(key: _secureKeyEmail, value: email);
        await _secureStorage.write(key: _secureKeyPassword, value: password);
        await _secureStorage.write(
          key: _secureKeyOrgCode,
          value: organizationCode,
        );
      } else {
        // Clear credentials if remember me is false
        await clearRememberedCredentials();
      }
    } catch (e) {
      throw Exception('Failed to store remembered credentials: $e');
    }
  }

  /// Get remembered email
  Future<String?> getRememberedEmail() async {
    try {
      return await _secureStorage.read(key: _secureKeyEmail);
    } catch (e) {
      return null;
    }
  }

  /// Get remembered password
  Future<String?> getRememberedPassword() async {
    try {
      return await _secureStorage.read(key: _secureKeyPassword);
    } catch (e) {
      return null;
    }
  }

  /// Get remembered organization code
  Future<String?> getRememberedOrgCode() async {
    try {
      return await _secureStorage.read(key: _secureKeyOrgCode);
    } catch (e) {
      return null;
    }
  }

  /// Clear remembered credentials
  Future<void> clearRememberedCredentials() async {
    try {
      await _secureStorage.delete(key: _secureKeyEmail);
      await _secureStorage.delete(key: _secureKeyPassword);
      await _secureStorage.delete(key: _secureKeyOrgCode);
      await _box.delete(_keyRememberMe);
    } catch (e) {
      throw Exception('Failed to clear remembered credentials: $e');
    }
  }

  /// Store authentication data
  Future<void> storeAuthData(LoginResponse response) async {
    try {
      await _box.put(_keyAccessToken, response.accessToken);
      await _box.put(_keyBranchId, response.user.branchId ?? '');
      await _box.put(_keyOrgId, response.user.organizationId ?? '');
      await _box.put(_keyOrgCode, response.user.organizationCode ?? '');
      await _box.put(_keyOrgName, response.user.organizationName ?? '');
      await _box.put(_keyEmpId, response.user.employeeId ?? '');
      await _box.put(_keyBranchName, response.user.branch?.name ?? '');
      await _box.put(_keyUserData, jsonEncode(response.user.toJson()));
      await _box.put(_keyDptName, response.user.department ?? '');
      await _box.put(_keyLoginTimestamp, DateTime.now().toIso8601String());
      await _box.put(_userId, response.user.id);
    } catch (e) {
      throw Exception('Failed to store authentication data: $e');
    }
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return _box.get(_keyAccessToken);
  }

  /// Get branch id
  Future<String?> getBranchID() async {
    return _box.get(_keyBranchId);
  }

  /// Get branch name
  Future<String?> getBranchName() async {
    return _box.get(_keyBranchName);
  }

  /// Switch the locally active branch used by branch-scoped modules.
  Future<void> switchActiveBranch({
    required String branchId,
    required String branchName,
    String? branchCode,
    String? city,
  }) async {
    await _box.put(_keyBranchId, branchId);
    await _box.put(_keyBranchName, branchName);

    final encoded = _box.get(_keyUserData);
    if (encoded == null) return;

    try {
      final jsonData = jsonDecode(encoded) as Map<String, dynamic>;
      jsonData['branchId'] = branchId;
      jsonData['branch'] = {
        'id': branchId,
        'name': branchName,
        'branch_code': ?branchCode,
        'branchCode': ?branchCode,
        'city': ?city,
      };
      await _box.put(_keyUserData, jsonEncode(jsonData));
    } catch (_) {
      // Keep the direct branch cache update even if legacy user JSON is invalid.
    }
  }

  Future<String?> userID() async {
    return _box.get(_userId);
  }

  /// Get employee id
  Future<String?> getEmpID() async {
    return _box.get(_keyEmpId);
  }

  /// Get org id
  Future<String?> getOrgId() async {
    return _box.get(_keyOrgId);
  }

  /// Get organization code
  Future<String?> getOrgCode() async {
    return _box.get(_keyOrgCode);
  }

  /// Get organization name
  Future<String?> getOrgName() async {
    return _box.get(_keyOrgName);
  }

  /// Get department name
  Future<String?> getDepartmentName() async {
    return _box.get(_keyDptName);
  }

  /// Get user data
  Future<UserModel?> getUserData() async {
    try {
      final encoded = _box.get(_keyUserData);
      if (encoded == null) return null;

      final jsonData = jsonDecode(encoded) as Map<String, dynamic>;
      return UserModel.fromJson(jsonData);
    } catch (_) {
      return null;
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = _box.get(_keyAccessToken);
    return token != null && token.toString().isNotEmpty;
  }

  /// Set remember me
  Future<void> setRememberMe(bool value) async {
    await _box.put(_keyRememberMe, value);
  }

  /// Get remember me
  Future<bool> getRememberMe() async {
    return _box.get(_keyRememberMe, defaultValue: false);
  }

  /// Get login timestamp
  Future<DateTime?> getLoginTimestamp() async {
    final ts = _box.get(_keyLoginTimestamp);
    if (ts == null) return null;

    try {
      return DateTime.parse(ts);
    } catch (_) {
      return null;
    }
  }

  /// Clear all authentication data
  Future<void> clearAuthData() async {
    try {
      // Clear Hive data
      await _box.delete(_keyAccessToken);
      await _box.delete(_keyUserData);
      await _box.delete(_keyLoginTimestamp);
      await _box.delete(_keyBranchId);
      await _box.delete(_keyBranchName);
      await _box.delete(_keyOrgId);
      await _box.delete(_keyOrgCode);
      await _box.delete(_keyOrgName);
      await _box.delete(_keyEmpId);
      await _box.delete(_keyDptName);

      // Note: Don't clear remembered credentials on logout
      // Only clear them if user explicitly unchecks remember me
    } catch (e) {
      throw Exception('Failed to clear authentication data: $e');
    }
  }

  /// Check if session is expired
  Future<bool> isSessionExpired() async {
    try {
      final loginTime = await getLoginTimestamp();
      if (loginTime == null) return true;

      final diff = DateTime.now().difference(loginTime);
      return diff.inHours > 24;
    } catch (e) {
      return true;
    }
  }
}
