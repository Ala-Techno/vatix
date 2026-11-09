import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vatix/core/errors/api_error_handler.dart';
import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/utils/unit.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// تنفيذ AuthRepository — يربط DataSource بعقد Domain
/// لا يعتمد على SharedPreferences للجلسة؛ المصدر الحقيقي = FirebaseAuth
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<ApiResult<UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await _remoteDataSource.signIn(
        email: email,
        password: password,
      );
      return Success(userModel);
    } catch (e) {
      return ApiFailure(ApiErrorHandler.handle(e));
    }
  }

  @override
  Future<ApiResult<UserEntity>> registerRetailer({
    required String email,
    required String password,
    required String businessName,
    required String ownerName,
    required String phone,
    required String city,
    required String inviteCode,
  }) async {
    try {
      final userModel = await _remoteDataSource.registerRetailer(
        email: email,
        password: password,
        businessName: businessName,
        ownerName: ownerName,
        phone: phone,
        city: city,
        inviteCode: inviteCode,
      );
      return Success(userModel);
    } catch (e) {
      return ApiFailure(ApiErrorHandler.handle(e));
    }
  }

  @override
  Future<void> signOut() => _remoteDataSource.signOut();

  @override
  Future<ApiResult<Unit>> sendPasswordResetEmail(String email) async {
    try {
      await _remoteDataSource.sendPasswordReset(email);
      return Success(unit);
    } catch (e) {
      return ApiFailure(ApiErrorHandler.handle(e));
    }
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUserDoc(String uid) =>
      _remoteDataSource.watchUserDoc(uid);

  @override
  Stream<User?> watchAuthUser() => _remoteDataSource.watchAuthUser();
}
