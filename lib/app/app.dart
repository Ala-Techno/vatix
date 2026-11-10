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
        // AuthProvider واحد في الجذر — مصدر الحقيقة للجلسة والدور
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => getIt<AuthProvider>(),
        ),
        // CartProvider في الجذر — سلة المشتريات متاحة عبر كامل مسارات التطبيق
        ChangeNotifierProvider<CartProvider>(
          create: (_) => getIt<CartProvider>(),
        ),
        // RetailerOrdersProvider في الجذر — قائمة طلبات التاجر والتحديثات اللحظية
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
