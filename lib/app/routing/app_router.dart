import 'package:flutter/material.dart';
import 'package:vatix/features/auth/presentation/gate/auth_gate.dart';
import 'package:vatix/features/auth/presentation/screens/reset_password_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        // نقطة البداية الوحيدة — AuthGate يتولى كل التوجيه
        return MaterialPageRoute(builder: (_) => const AuthGate());

      case '/resetPassword':
        return MaterialPageRoute(
            builder: (_) => const ResetPasswordScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('الصفحة غير موجودة')),
          ),
        );
    }
  }
}
