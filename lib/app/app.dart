import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/di/dependency_injection.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import 'routing/app_router.dart';

class VatixApp extends StatelessWidget {
  final AppRouter appRouter;
  final String initialRoute;

  const VatixApp({
    super.key,
    required this.appRouter,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // M1: يصبح مصدر الحقيقة للمستخدم والدور والحالة.
        ChangeNotifierProvider(create: (_) => getIt<AuthProvider>()),
      ],
      child: MaterialApp(
        navigatorKey: AppRouter.navigatorKey,
        title: 'Vatix',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: AppTheme.lightTheme,
        initialRoute: initialRoute,
        onGenerateRoute: appRouter.generateRoute,
      ),
    );
  }
}
