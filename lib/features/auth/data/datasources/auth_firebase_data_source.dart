import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:vatix/core/errors/exceptions.dart';
import 'package:vatix/features/auth/data/models/user_model.dart';
import 'package:vatix/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:vatix/features/auth/domain/entities/user_entity.dart';

/// DataSource implementation using Firebase Auth + Firestore
class AuthFirebaseDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthFirebaseDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  // ─── Centralized Error Handling Function ─────────────────────────────────
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException {
      rethrow; // Translated to an Arabic user message in ApiErrorHandler
    } on FirebaseException {
      rethrow;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  // ─── Sign In ────────────────────────────────────────────────────────────
  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    return _guard(() async {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        throw const ServerException(message: 'فشل العثور على معرف المستخدم');
      }
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists || userDoc.data() == null) {
        throw const ServerException(
            message: 'بيانات المستخدم غير موجودة في قاعدة البيانات');
      }
      return UserModel.fromFirestore(userDoc);
    });
  }

  // ─── Sign Out ───────────────────────────────────────────────────────────
  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // ─── Password Reset ─────────────────────────────────────────────────────
  @override
  Future<void> sendPasswordReset(String email) async {
    return _guard(() async {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    });
  }

  // ─── Auth State Stream ──────────────────────────────────────────────────
  @override
  Stream<User?> watchAuthUser() => _firebaseAuth.authStateChanges();

  // ─── users/{uid} Document Stream ────────────────────────────────────────
  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUserDoc(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // ─── Fetch Invite Code ──────────────────────────────────────────────────
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> getInvite(String code) async {
    return _firestore.collection('invites').doc(code.toUpperCase().trim()).get();
  }

  // ─── Register New Retailer ─────────────────────────────────────────────
  /// Professional flow:
  /// 1. Verify invite code first before touching Firebase Auth
  /// 2. Create Firebase Auth account once code validity is confirmed
  /// 3. Save retailer data in users collection
  /// 4. Delete account immediately as compensation if writing data to users fails
  @override
  Future<UserModel> registerRetailer({
    required String email,
    required String password,
    required String businessName,
    required String ownerName,
    required String phone,
    required String city,
    required String inviteCode,
  }) async {
    final cleanInviteCode = inviteCode.toUpperCase().trim();

    if (cleanInviteCode.isEmpty) {
      throw const ServerException(message: 'يرجى إدخال كود الدعوة');
    }

    if (kDebugMode) {
      debugPrint('VATIX_REGISTER: Checking invite code -> [$cleanInviteCode]');
    }

    // 1. Pre-verify existence and validity of invite code in Firestore
    final inviteDoc = await _firestore
        .collection('invites')
        .doc(cleanInviteCode)
        .get();

    if (kDebugMode) {
      debugPrint('VATIX_REGISTER: Invite document exists? -> ${inviteDoc.exists}');
      if (inviteDoc.exists) {
        debugPrint('VATIX_REGISTER: Invite document data -> ${inviteDoc.data()}');
      }
    }

    if (!inviteDoc.exists || inviteDoc.data() == null) {
      throw const ServerException(
        message: 'كود الدعوة غير صحيح، تأكد من صحة الكود والمحاولة مجدداً',
      );
    }

    final inviteData = inviteDoc.data()!;
    final isActive = inviteData['isActive'] as bool? ?? false;
    if (!isActive) {
      throw const ServerException(
        message: 'كود الدعوة منتهي الصلاحية أو تم إيقافه من قبل المورد',
      );
    }

    final wholesalerId = inviteData['wholesalerId']?.toString() ?? '';
    if (wholesalerId.isEmpty) {
      throw const ServerException(
        message: 'كود الدعوة غير مرتبط بأي حساب مورد صالح',
      );
    }

    // 2. Code is 100% valid -> Create user account in Firebase Auth
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    final uid = user?.uid;

    if (uid == null) {
      throw const ServerException(message: 'فشل إنشاء حساب المستخدم في النظام');
    }

    try {
      // 3. Write user document in users collection
      final userMap = UserModel.toFirestoreForRegistration(
        uid: uid,
        businessName: businessName,
        ownerName: ownerName,
        phone: phone,
        city: city,
        email: email,
        wholesalerId: wholesalerId,
        inviteCode: cleanInviteCode,
      );

      await _firestore.collection('users').doc(uid).set(userMap);

      if (kDebugMode) {
        debugPrint('VATIX_REGISTER: User document successfully created in users/$uid');
      }

      // 4. Construct entity directly without consuming additional read operations
      final now = DateTime.now();
      return UserModel(
        id: uid,
        role: UserRole.retailer,
        status: RetailerStatus.pending,
        businessName: businessName,
        ownerName: ownerName,
        phone: phone,
        city: city,
        email: email,
        wholesalerId: wholesalerId,
        inviteCode: cleanInviteCode,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      // Compensation: Delete Auth account if writing users data fails to prevent dangling accounts
      if (kDebugMode) {
        debugPrint('VATIX_REGISTER: Failed to save user doc, compensating by deleting Auth user: $e');
      }
      try {
        await user?.delete();
      } catch (deleteErr) {
        if (kDebugMode) {
          debugPrint('VATIX_REGISTER: Failed to delete Auth user: $deleteErr');
        }
      }
      rethrow;
    }
  }
}
