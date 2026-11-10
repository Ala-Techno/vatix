abstract class Routes {
  const Routes._();

  /// نقطة البداية — AuthGate يتولى التوجيه من هنا
  static const String gate = '/';

  /// إعادة تعيين كلمة المرور (تُفتح من LoginPage)
  static const String resetPassword = '/resetPassword';

  /// تأكيد أمر الشراء
  static const String checkout = '/checkout';

  /// نجاح إرسال أمر الشراء
  static const String orderSuccess = '/orderSuccess';

  /// تفاصيل أمر الشراء
  static const String orderDetails = '/orderDetails';
}
