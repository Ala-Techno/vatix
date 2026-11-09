abstract class Routes {
  const Routes._();

  /// نقطة البداية — AuthGate يتولى التوجيه من هنا
  static const String gate = '/';

  /// إعادة تعيين كلمة المرور (تُفتح من LoginPage)
  static const String resetPassword = '/resetPassword';

  // M2+ يُضاف هنا:
  // static const String productDetails = '/productDetails';
  // static const String orderDetails = '/orderDetails';
}
