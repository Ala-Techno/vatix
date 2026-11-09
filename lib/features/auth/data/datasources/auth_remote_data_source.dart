import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// عقد DataSource للمصادقة عبر Firebase
abstract class AuthRemoteDataSource {
  /// تسجيل الدخول بالبريد وكلمة المرور
  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  /// تسجيل الخروج
  Future<void> signOut();

  /// إرسال رابط إعادة تعيين كلمة المرور
  Future<void> sendPasswordReset(String email);

  /// Stream للمستخدم الحالي من FirebaseAuth
  Stream<User?> watchAuthUser();

  /// Stream لمستند users/{uid} من Firestore
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUserDoc(String uid);

  /// جلب مستند كود الدعوة
  Future<DocumentSnapshot<Map<String, dynamic>>> getInvite(String code);

  /// تسجيل تاجر جديد:
  /// إنشاء Auth ← التحقق من الكود ← كتابة users (أو حذف Auth عند الفشل)
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
