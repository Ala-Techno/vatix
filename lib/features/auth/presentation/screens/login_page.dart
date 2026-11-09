import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';
import 'package:vatix/features/auth/presentation/screens/register_screen.dart';
import 'package:vatix/features/auth/presentation/screens/reset_password_screen.dart';

/// [LoginPage] — شاشة تسجيل الدخول المحدثة بتصميم Material 3 مخصص للأعمال B2B
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final provider = context.read<AuthProvider>();
    await provider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    final error = context.read<AuthProvider>().errorMessage;
    if (error != null) _showError(error);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.statusBlocked,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── شعار وهوية التطبيق ────────────────────────
                  _buildBrandHeader(theme),
                  const SizedBox(height: 36),

                  // ─── بطاقة تسجيل الدخول ─────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderSubtle),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowColor,
                          blurRadius: 20,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'تسجيل الدخول',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'أدخل بيانات حسابك للمتابعة إلى لوحة التحكم',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // حقل البريد الإلكتروني
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            hintText: 'name@business.com',
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
                        const SizedBox(height: 16),

                        // حقل كلمة المرور
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: SizedBox(
                              width: 48,
                              height: 48,
                              child: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'يرجى إدخال كلمة المرور';
                            }
                            if (v.length < 6) {
                              return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                            }
                            return null;
                          },
                        ),

                        // نسيت كلمة المرور
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ResetPasswordScreen(),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('نسيت كلمة المرور؟'),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // زر تسجيل الدخول
                        Consumer<AuthProvider>(
                          builder: (_, provider, __) => SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: provider.isLoading ? null : _handleLogin,
                              child: provider.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text('دخول'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── رابط إنشاء حساب تاجر جديد ───────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'هل أنت تاجر تجزئة وتريد الانضمام؟',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterRetailerScreen(),
                          ),
                        ),
                        child: const Text('تسجيل بكود دعوة'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryLight, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.hub_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Vatix',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: 1,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'شبكة التوزيع المباشر بين المورد وتجاره',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
