import 'package:flutter/material.dart';
import 'package:vatix/app/routing/routes.dart';
import 'package:vatix/features/auth/presentation/gate/auth_gate.dart';
import 'package:vatix/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:vatix/features/auth/presentation/screens/splash_screen.dart';
import 'package:vatix/features/orders/domain/entities/order_entity.dart';
import 'package:vatix/features/orders/presentation/screens/checkout_screen.dart';
import 'package:vatix/features/orders/presentation/screens/order_details_screen.dart';
import 'package:vatix/features/orders/presentation/screens/order_success_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case Routes.gate:
        // AuthGate handles routing based on user state
        return MaterialPageRoute(builder: (_) => const AuthGate());

      case Routes.resetPassword:
        return MaterialPageRoute(
            builder: (_) => const ResetPasswordScreen());

      case Routes.checkout:
        final wholesalerName = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => CheckoutScreen(
            initialWholesalerName: wholesalerName,
          ),
        );

      case Routes.orderSuccess:
        final order = settings.arguments as OrderEntity;
        return MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(order: order),
        );

      case Routes.orderDetails:
        final order = settings.arguments as OrderEntity;
        return MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(initialOrder: order),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('الصفحة غير موجودة')),
          ),
        );
    }
  }
}
