import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';

/// [RegisterRetailerScreen] — شاشة تسجيل التاجر بكود الدعوة
class RegisterRetailerScreen extends StatefulWidget {
  const RegisterRetailerScreen({super.key});

  @override
  State<RegisterRetailerScreen> createState() => _RegisterRetailerScreenState();
}

class _RegisterRetailerScreenState extends State<RegisterRetailerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final provider = context.read<AuthProvider>();
    final success = await provider.registerRetailer(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      businessName: _businessNameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      phone: _phoneController.text.trim(),
      city: _cityController.text.trim(),
      inviteCode: _inviteCodeController.text.trim().toUpperCase(),
    );

    if (!mounted) return;

    if (success) {
      // إغلاق شاشة التسجيل للعودة للـ AuthGate التي ستعرض شاشة PendingApprovalScreen تلقائياً
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      final error = context.read<AuthProvider>().errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(error)),
          ]),
          backgroundColor: Colors.redAccent.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب تاجر'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('أنشئ حساب منشأتك',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('تحتاج كود دعوة من المورد للتسجيل',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey.shade600)),
                const SizedBox(height: 28),

                _field(_businessNameController,
                    label: 'اسم المنشأة / الشركة',
                    icon: Icons.store_outlined,
                    action: TextInputAction.next),
                const SizedBox(height: 16),
                _field(_ownerNameController,
                    label: 'اسم المالك / المسؤول',
                    icon: Icons.person_outline,
                    action: TextInputAction.next),
                const SizedBox(height: 16),
                _field(_emailController,
                    label: 'البريد الإلكتروني',
                    hint: 'example@domain.com',
                    icon: Icons.email_outlined,
                    type: TextInputType.emailAddress,
                    action: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'يرجى إدخال البريد الإلكتروني';
                      }
                      if (!v.contains('@') || !v.contains('.')) {
                        return 'بريد إلكتروني غير صالح';
                      }
                      return null;
                    }),
                const SizedBox(height: 16),
                _field(_phoneController,
                    label: 'رقم الهاتف',
                    hint: '777xxxxxx',
                    icon: Icons.phone_outlined,
                    type: TextInputType.phone,
                    action: TextInputAction.next),
                const SizedBox(height: 16),
                _field(_cityController,
                    label: 'المدينة',
                    icon: Icons.location_city_outlined,
                    action: TextInputAction.next),
                const SizedBox(height: 16),

                // كلمة المرور
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: _deco(
                    label: 'كلمة المرور',
                    icon: Icons.lock_outline,
                    suffix: _eyeBtn(
                        _obscurePassword,
                        () => setState(
                            () => _obscurePassword = !_obscurePassword)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'يرجى إدخال كلمة المرور';
                    if (v.length < 6) {
                      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // تأكيد كلمة المرور
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.next,
                  decoration: _deco(
                    label: 'تأكيد كلمة المرور',
                    icon: Icons.lock_outline,
                    suffix: _eyeBtn(
                        _obscureConfirm,
                        () => setState(
                            () => _obscureConfirm = !_obscureConfirm)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'يرجى تأكيد كلمة المرور';
                    }
                    if (v != _passwordController.text) {
                      return 'كلمتا المرور غير متطابقتين';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // كود الدعوة (يُحوَّل لأحرف كبيرة تلقائياً)
                TextFormField(
                  controller: _inviteCodeController,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9a-z]')),
                    _UpperCaseTextFormatter()
                  ],
                  decoration: _deco(
                    label: 'كود الدعوة',
                    hint: 'VATX2K3M',
                    icon: Icons.vpn_key_outlined,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'يرجى إدخال كود الدعوة';
                    }
                    if (v.trim().length < 4) {
                      return 'كود الدعوة قصير جداً';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // زر التسجيل
                Consumer<AuthProvider>(
                  builder: (_, provider, __) => SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: provider.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('إنشاء الحساب',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller, {
    required String label,
    String? hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      textInputAction: action,
      decoration: _deco(label: label, hint: hint, icon: icon),
      validator: validator ??
          (v) => (v == null || v.trim().isEmpty) ? 'حقل مطلوب' : null,
    );
  }

  InputDecoration _deco({
    required String label,
    String? hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  IconButton _eyeBtn(bool obscure, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
      onPressed: onPressed,
    );
  }
}

/// محوّل إدخال — يجعل كود الدعوة دائماً بأحرف كبيرة
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
