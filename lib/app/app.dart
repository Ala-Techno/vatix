import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/di/dependency_injection.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/cart/presentation/providers/cart_provider.dart';
import '../features/orders/presentation/providers/retailer_orders_provider.dart';
import 'routing/app_router.dart';

class VatixApp extends StatelessWidget {
  final AppRouter appRouter;

  const VatixApp({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Single AuthProvider at root — source of truth for session and role
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => getIt<AuthProvider>(),
        ),
        // CartProvider at root — shopping cart available across all app routes
        ChangeNotifierProvider<CartProvider>(
          create: (_) => getIt<CartProvider>(),
        ),
        // RetailerOrdersProvider at root — retailer orders list and real-time updates
        ChangeNotifierProvider<RetailerOrdersProvider>(
          create: (_) => getIt<RetailerOrdersProvider>(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: AppRouter.navigatorKey,
        title: 'Vatix',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        onGenerateRoute: appRouter.generateRoute,
      ),
    );
  }
}
