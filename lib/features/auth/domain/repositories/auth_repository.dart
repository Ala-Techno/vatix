import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/utils/unit.dart';
import '../entities/user_entity.dart';

/// [AuthRepository] — Domain contract for all authentication operations.
/// Pure Dart — no dependencies on Data or Presentation layers.
abstract class AuthRepository {
  /// Sign in
  Future<ApiResult<UserEntity>> signIn({
    required String email,
    required String password,
  });

  /// Register new retailer with invite code
  Future<ApiResult<UserEntity>> registerRetailer({
    required String email,
    required String password,
    required String businessName,
    required String ownerName,
    required String phone,
    required String city,
    required String inviteCode,
  });

  /// Sign out
  Future<void> signOut();

  /// Send password reset email
  Future<ApiResult<Unit>> sendPasswordResetEmail(String email);

  /// Stream of users/{uid} document from Firestore (used by AuthProvider)
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUserDoc(String uid);

  /// Stream of Auth state (used by AuthProvider)
  Stream<dynamic> watchAuthUser();
}
