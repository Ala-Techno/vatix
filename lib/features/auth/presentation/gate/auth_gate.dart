import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';
import 'package:vatix/features/auth/presentation/screens/login_page.dart';
import 'package:vatix/features/auth/presentation/screens/no_profile_screen.dart';
import 'package:vatix/features/auth/presentation/screens/pending_approval_screen.dart';
import 'package:vatix/features/auth/presentation/screens/blocked_screen.dart';
import 'package:vatix/features/shell/retailer_shell.dart';
import 'package:vatix/features/shell/wholesaler_shell.dart';

/// [AuthGate] — Central routing gate.
/// Listens to AuthProvider and displays the appropriate screen for each state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    switch (status) {
      case AuthStatus.unknown:
        // Checking session
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );

      case AuthStatus.signedOut:
        return const LoginPage();

      case AuthStatus.noProfile:
        return const NoProfileScreen();

      case AuthStatus.wholesaler:
        return const WholesalerShell();

      case AuthStatus.retailerPending:
        return const PendingApprovalScreen();

      case AuthStatus.retailerActive:
        return const RetailerShell();

      case AuthStatus.retailerBlocked:
        return const BlockedScreen();
    }
  }
}

