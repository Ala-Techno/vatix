import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';

/// [ResetPasswordScreen] — شاشة إعادة تعيين كلمة المرور — Material 3
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final provider = context.read<AuthProvider>();
    final success =
        await provider.sendPasswordResetEmail(_emailController.text.trim());

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني بنجاح',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.statusActive,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  provider.errorMessage ?? 'حدث خطأ، يرجى المحاولة لاحقاً',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.statusBlocked,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('استعادة كلمة المرور'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: AppColors.primaryLight,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'أدخل بريدك الإلكتروني المسجل وسنرسل لك رابطاً مباشراً لتعيين كلمة مرور جديدة.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      hintText: 'name@domain.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'يرجى إدخال البريد الإلكتروني';
                      }
                      if (!v.contains('@') || !v.contains('.')) {
                        return 'بريد إلكتروني غير صالح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Consumer<AuthProvider>(
                    builder: (_, provider, __) => SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: provider.isLoading ? null : _submit,
                        child: provider.isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('إرسال رابط الاستعادة'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
