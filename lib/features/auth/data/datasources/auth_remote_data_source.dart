import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// DataSource contract for authentication via Firebase
abstract class AuthRemoteDataSource {
  /// Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  /// Sign out
  Future<void> signOut();

  /// Send password reset link
  Future<void> sendPasswordReset(String email);

  /// Stream of current user from FirebaseAuth
  Stream<User?> watchAuthUser();

  /// Stream of users/{uid} document from Firestore
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUserDoc(String uid);

  /// Fetch invite code document
  Future<DocumentSnapshot<Map<String, dynamic>>> getInvite(String code);

  /// Register a new retailer:
  /// Create Auth -> Verify code -> Write users doc (or rollback Auth on failure)
  Future<UserModel> registerRetailer({
    required String email,
    required String password,
    required String businessName,
    required String ownerName,
    required String phone,
    required String city,
    required String inviteCode,
  });
}
