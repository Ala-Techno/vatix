import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';

/// [RegisterRetailerScreen] — Retailer registration with invite code — Material 3 B2B
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
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      final error = context.read<AuthProvider>().errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    error,
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
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تسجيل منشأة جديدة'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Invite code section first for high priority ──
                _buildInviteCodeSection(),
                const SizedBox(height: 20),

                // ── Business and owner info card ────────────────
                _buildCardSection(
                  title: 'بيانات المنشأة والمالك',
                  icon: Icons.storefront_rounded,
                  children: [
                    _field(
                      _businessNameController,
                      label: 'اسم المنشأة / المحل التجاري',
                      hint: 'مثال: سوبرماركت البركة',
                      icon: Icons.store_outlined,
                      action: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      _ownerNameController,
                      label: 'اسم المسؤول / التاجر',
                      hint: 'مثال: أحمد محمد',
                      icon: Icons.person_outline_rounded,
                      action: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _field(
                            _phoneController,
                            label: 'رقم الهاتف',
                            hint: '7xxxxxxxx',
                            icon: Icons.phone_outlined,
                            type: TextInputType.phone,
                            action: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _field(
                            _cityController,
                            label: 'المدينة',
                            hint: 'صنعاء، عدن...',
                            icon: Icons.location_city_outlined,
                            action: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Login credentials card ──────────────────
                _buildCardSection(
                  title: 'بيانات تسجيل الدخول',
                  icon: Icons.lock_person_rounded,
                  children: [
                    _field(
                      _emailController,
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
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
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
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleRegister(),
                      decoration: InputDecoration(
                        labelText: 'تأكيد كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: SizedBox(
                          width: 48,
                          height: 48,
                          child: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
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
                  ],
                ),
                const SizedBox(height: 28),

                // Create account button
                Consumer<AuthProvider>(
                  builder: (_, provider, __) => SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : _handleRegister,
                      child: provider.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('إرسال طلب الانضمام'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInviteCodeSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.statusPending.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.statusPendingBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.vpn_key_rounded,
                  color: AppColors.statusPending,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'كود دعوة المورد',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'مطلوب للربط مع المورد المعتمد',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _inviteCodeController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              fontFamily: 'monospace',
              color: AppColors.primary,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9a-z]')),
              _UpperCaseTextFormatter(),
            ],
            decoration: InputDecoration(
              hintText: 'VATX2K3M',
              hintStyle: TextStyle(
                fontSize: 18,
                letterSpacing: 4,
                color: AppColors.textHint.withValues(alpha: 0.6),
                fontFamily: 'monospace',
              ),
              fillColor: AppColors.surfaceVariant,
              prefixIcon: const Icon(
                Icons.tag_rounded,
                color: AppColors.statusPending,
              ),
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
          const SizedBox(height: 12),
          // Button to request invite code from wholesaler
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _showRequestCodeBottomSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.statusPendingBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.statusPending.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.contact_support_outlined,
                    size: 16,
                    color: AppColors.statusPending,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ليس لديك كود؟ اطلب كود الدعوة من المورد',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                      color: AppColors.statusPending,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestCodeBottomSheet() {
    final phoneController = TextEditingController(text: _phoneController.text);
    final storeController = TextEditingController(text: _businessNameController.text);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.vpn_key_rounded,
                    color: AppColors.primaryLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'طلب كود انضمام من المورد',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Cairo',
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'تواصل مباشرة مع المورد المعتمد للحصول على كود الدعوة',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: storeController,
              decoration: const InputDecoration(
                labelText: 'اسم منشأتك أو متجرك',
                prefixIcon: Icon(Icons.storefront_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم هاتفك للتواصل',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final store = storeController.text.trim();
                final phone = phoneController.text.trim();

                final storeName = store.isNotEmpty ? store : 'متجر تجزئة';
                final contactPhone = phone.isNotEmpty ? phone : 'غير محدد';

                // Prepare structured WhatsApp request message
                final message = '''
السلام عليكم ورحمة الله وبركاته،
عزيزي المورد المعتمد،

أود الانضمام إلى شبكتكم التجارية والبدء بإرسال طلبات الشراء عبر تطبيق *Vatix*.

📋 *بيانات المنشأة:*
• اسم المتجر: $storeName
• رقم التواصل: $contactPhone

يرجى التكرم بتزويدي بـ *كود الدعوة* الخاص بكم لإتمام التسجيل.
شاكرين ومقدّرين حسن تعاونكم.
'''.trim();
                
                final encodedText = Uri.encodeComponent(message);

                // 1. Direct custom scheme for WhatsApp app
                final whatsappAppUri = Uri.parse('whatsapp://send?text=$encodedText');
                // 2. Web fallback link
                final whatsappWebUri = Uri.parse('https://api.whatsapp.com/send?text=$encodedText');

                bool launched = false;

                // 1. Attempt direct custom scheme without canLaunchUrl to bypass Android 11+ package queries limitation
                try {
                  launched = await launchUrl(
                    whatsappAppUri,
                    mode: LaunchMode.externalApplication,
                  );
                } catch (_) {}

                // 2. If scheme fails, open via external web link
                if (!launched) {
                  try {
                    launched = await launchUrl(
                      whatsappWebUri,
                      mode: LaunchMode.externalNonBrowserApplication,
                    );
                  } catch (_) {}
                }

                if (!launched) {
                  try {
                    launched = await launchUrl(
                      whatsappWebUri,
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (_) {}
                }

                if (!launched) {
                  // Fallback: Copy message to clipboard if launching fails
                  Clipboard.setData(ClipboardData(text: message));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'تعذر فتح تطبيق واتساب. تم نسخ نص الرسالة إلى الحافظة.',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                        backgroundColor: AppColors.statusBlocked,
                      ),
                    );
                  }
                }

                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text(
                'فتح واتساب وإرسال الطلب للمورد',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366), // لون واتساب الرسمي
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryLight),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
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
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      validator: validator ??
          (v) => (v == null || v.trim().isEmpty) ? 'حقل مطلوب' : null,
    );
  }
}

/// Input formatter — forces invite code characters to uppercase
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
