abstract class Routes {
  const Routes._();

  /// Splash screen
  static const String splash = '/';

  /// Central routing gate
  static const String gate = '/gate';

  /// Reset password (opened from LoginPage)
  static const String resetPassword = '/resetPassword';

  /// Purchase order checkout
  static const String checkout = '/checkout';

  /// Purchase order success
  static const String orderSuccess = '/orderSuccess';

  /// Purchase order details
  static const String orderDetails = '/orderDetails';
}
