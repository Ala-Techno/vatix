import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';

/// شاشة «تعذّر تحميل بيانات الحساب»
/// تظهر عندما يوجد مستخدم Auth لكن لا مستند users (تسجيل لم يكتمل)
class NoProfileScreen extends StatelessWidget {
  const NoProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'تعذّر تحميل بيانات الحساب',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'لم يتم العثور على بيانات حسابك.\nقد يكون التسجيل لم يكتمل. يرجى تسجيل الخروج والمحاولة مجدداً.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.6),
              ),
              const SizedBox(height: 40),
              OutlinedButton.icon(
                onPressed: () => context.read<AuthProvider>().logout(),
                icon: const Icon(Icons.logout),
                label: const Text('تسجيل الخروج'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

