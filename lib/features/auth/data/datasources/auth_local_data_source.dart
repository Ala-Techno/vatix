import 'package:vatix/core/constants/storage_keys.dart';
import 'package:vatix/core/services/shared_pref_service.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUserId(String uid);
  String? getCachedUserId();
  
  Future<void> cacheToken(String token);
  String? getCachedToken();
  
  Future<void> clearAuthData();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPrefService _sharedPrefService;

  AuthLocalDataSourceImpl(this._sharedPrefService);

  @override
  Future<void> cacheUserId(String uid) async {
    await _sharedPrefService.setData(StorageKeys.userId, uid);
  }

  @override
  String? getCachedUserId() {
    final value = _sharedPrefService.getString(StorageKeys.userId);
    return value.isEmpty ? null : value;
  }

  @override
  Future<void> cacheToken(String token) async {
    await _sharedPrefService.setData(StorageKeys.userToken, token);
  }

  @override
  String? getCachedToken() {
    final value = _sharedPrefService.getString(StorageKeys.userToken);
    return value.isEmpty ? null : value;
  }

  @override
  Future<void> clearAuthData() async {
    await _sharedPrefService.removeData(StorageKeys.userId);
    await _sharedPrefService.removeData(StorageKeys.userToken);
  }
}