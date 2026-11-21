import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/foundation.dart';
import 'package:vatix/core/errors/failures.dart';

import 'exceptions.dart';

/// Converts any error (Firebase / app) into a [Failure] with an appropriate Arabic user message.
/// Does not leak technical details to the user; details are printed in debug mode only.
class ApiErrorHandler {
  const ApiErrorHandler._();

  static Failure handle(Object error) {
    if (kDebugMode) debugPrint('ApiErrorHandler: $error');

    if (error is ServerException) {
      return ServerFailure(
        error.message ?? 'حدث خطأ في الخادم',
        statusCode: error.statusCode,
      );
    }
    if (error is CacheException) {
      return CacheFailure(error.message ?? 'حدث خطأ في الذاكرة المؤقتة');
    }
    // FirebaseAuthException extends FirebaseException => must be checked first.
    if (error is FirebaseAuthException) return _fromAuth(error);
    if (error is FirebaseException) return _fromFirebase(error);
    if (error is FormatException) {
      return const ServerFailure('خطأ في معالجة البيانات القادمة من الخادم');
    }
    if (error is TypeError) {
      return const ServerFailure('حدث خطأ في تنسيق البيانات');
    }
    return const ServerFailure('حدث خطأ غير متوقع، حاول مجدداً');
  }

  static Failure _fromAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return const ServerFailure('البريد الإلكتروني غير صالح');
      case 'user-disabled':
        return const ServerFailure('هذا الحساب موقوف');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const ServerFailure('البريد الإلكتروني أو كلمة المرور غير صحيحة');
      case 'email-already-in-use':
        return const ServerFailure('هذا البريد الإلكتروني مستخدم مسبقاً');
      case 'weak-password':
        return const ServerFailure('كلمة المرور ضعيفة (6 أحرف على الأقل)');
      case 'too-many-requests':
        return const ServerFailure('محاولات كثيرة، حاول لاحقاً');
      case 'operation-not-allowed':
        return const ServerFailure('طريقة تسجيل الدخول هذه غير مفعّلة');
      case 'network-request-failed':
        return const NetworkFailure('لا يوجد اتصال بالإنترنت، تحقق من شبكتك');
      default:
        return ServerFailure(e.message ?? 'حدث خطأ في المصادقة');
    }
  }

  static Failure _fromFirebase(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const ServerFailure('ليس لديك صلاحية لتنفيذ هذه العملية');
      case 'unauthenticated':
        return const ServerFailure('يجب تسجيل الدخول أولاً');
      case 'unavailable':
        return const NetworkFailure('تعذّر الاتصال بالخادم، تحقق من شبكتك');
      case 'deadline-exceeded':
        return const ServerFailure('انتهت مهلة الاتصال، حاول لاحقاً');
      case 'not-found':
        return const ServerFailure('العنصر المطلوب غير موجود');
      case 'resource-exhausted':
        return const ServerFailure('تم تجاوز الحد المسموح للاستخدام حالياً، حاول لاحقاً');
      default:
        return ServerFailure(e.message ?? 'حدث خطأ في قاعدة البيانات');
    }
  }
}
