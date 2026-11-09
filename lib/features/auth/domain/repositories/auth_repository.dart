import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/utils/unit.dart';
import '../entities/user_entity.dart';

/// [AuthRepository] — عقد Domain لكل عمليات المصادقة.
/// Pure Dart — لا اعتماد على Data أو Presentation.
abstract class AuthRepository {
  /// تسجيل الدخول
  Future<ApiResult<UserEntity>> signIn({
    required String email,
    required String password,
  });

  /// تسجيل تاجر جديد بكود دعوة
  Future<ApiResult<UserEntity>> registerRetailer({
    required String email,
    required String password,
    required String businessName,
    required String ownerName,
    required String phone,
    required String city,
    required String inviteCode,
  });

  /// تسجيل الخروج
  Future<void> signOut();

  /// إرسال رابط إعادة تعيين كلمة المرور
  Future<ApiResult<Unit>> sendPasswordResetEmail(String email);

  /// Stream لمستند users/{uid} من Firestore (يستخدمه AuthProvider)
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUserDoc(String uid);

  /// Stream لحالة Auth (يستخدمه AuthProvider)
  Stream<dynamic> watchAuthUser();
}
