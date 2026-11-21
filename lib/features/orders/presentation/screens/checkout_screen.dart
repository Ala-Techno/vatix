import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/di/dependency_injection.dart';
import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/utils/money_formatter.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';
import 'package:vatix/features/cart/presentation/providers/cart_provider.dart';
import 'package:vatix/features/orders/domain/usecases/place_order_use_case.dart';
import '../providers/retailer_orders_provider.dart';
import 'order_success_screen.dart';

/// [CheckoutScreen] — Review and confirm purchase order screen before submission
class CheckoutScreen extends StatefulWidget {
  final String? initialWholesalerName;

  const CheckoutScreen({
    super.key,
    this.initialWholesalerName,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;
  String? _wholesalerBusinessName;
  bool _isLoadingWholesaler = false;

  @override
  void initState() {
    super.initState();
    _wholesalerBusinessName = widget.initialWholesalerName;
    _fetchWholesalerNameIfNeeded();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchWholesalerNameIfNeeded() async {
    if (_wholesalerBusinessName != null &&
        _wholesalerBusinessName!.trim().isNotEmpty) {
      return;
    }

    final authUser = context.read<AuthProvider>().user;
    final wholesalerId = authUser?.wholesalerId;
    if (wholesalerId == null || wholesalerId.isEmpty) return;

    setState(() => _isLoadingWholesaler = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(wholesalerId)
          .get();

      if (mounted && doc.exists) {
        final data = doc.data();
        setState(() {
          _wholesalerBusinessName =
              data?['businessName'] as String? ?? 'المورد المعتمد';
          _isLoadingWholesaler = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingWholesaler = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingWholesaler = false);
    }
  }

  Future<void> _handleSubmitOrder() async {
    // 1. Guard against double-tap
    if (_isSubmitting) return;

    final cart = context.read<CartProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'سلة المشتريات فارغة، لا يمكن إرسال أمر الشراء.',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.statusBlocked,
        ),
      );
      return;
    }

    if (user == null || user.wholesalerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حساب التاجر غير مكتمل أو غير مرتبط بمورد معتمد.',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.statusBlocked,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Retain navigator reference prior to async operations
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final ordersProvider = context.read<RetailerOrdersProvider>();

      // Use PlaceOrderUseCase directly from DI
      final placeOrderUseCase = getIt<PlaceOrderUseCase>();
      final wholesalerName = _wholesalerBusinessName?.trim().isNotEmpty == true
          ? _wholesalerBusinessName!.trim()
          : 'المورد المعتمد';

      final params = PlaceOrderParams(
        cartItems: cart.items,
        retailerUser: user,
        wholesalerName: wholesalerName,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      final result = await placeOrderUseCase(params);

      switch (result) {
        case Success(data: final createdOrder):
          // Clear cart successfully after creating order
          cart.clear();

          // Immediately add order locally so it displays without delay
          ordersProvider.addOrderLocally(createdOrder);

          // Route to success screen using retained navigator reference
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (_) => OrderSuccessScreen(order: createdOrder),
            ),
          );
          return;

        case ApiFailure(failure: final failure):
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                failure.message,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: AppColors.statusBlocked,
              duration: const Duration(seconds: 4),
            ),
          );
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ غير متوقع: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.statusBlocked,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final authUser = context.watch<AuthProvider>().user;

    final wholesalerTitle = _isLoadingWholesaler
        ? 'جارِ تحميل بيانات المورد...'
        : (_wholesalerBusinessName ?? 'المورد المعتمد');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'تأكيد أمر الشراء',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: cart.isEmpty
          ? const Center(
              child: Text(
                'سلة المشتريات فارغة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 1. Wholesaler info card
                      _buildWholesalerCard(wholesalerTitle, authUser?.businessName),

                      const SizedBox(height: 16),

                      // 2. Initial order status banner card
                      _buildStatusInfoBanner(),

                      const SizedBox(height: 16),

                      // 3. Items summary list
                      _buildItemsSummaryCard(cart),

                      const SizedBox(height: 16),

                      // 4. Additional order notes field
                      _buildNotesCard(),

                      const SizedBox(height: 16),

                      // 5. Totals breakdown card per currency
                      _buildTotalsBreakdownCard(cart),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Bottom persistent submit bar
                _buildBottomSubmitBar(),
              ],
            ),
    );
  }

  Widget _buildWholesalerCard(String wholesalerTitle, String? retailerName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.store_rounded,
                  color: AppColors.primaryLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'أمر شراء موجه إلى',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      wholesalerTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.statusActiveBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'مورد معتمد',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusActive,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          if (retailerName != null && retailerName.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'الجهة الطالبة: $retailerName',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.statusPendingBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.statusPending.withValues(alpha: 0.3),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: AppColors.statusPending,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'سيرسل هذا الطلب بحالة "قيد الانتظار". سيتولى المورد مراجعته واعتماده إما كأمر بيع آجل (دين) أو نقدي (كاش).',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontFamily: 'Cairo',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSummaryCard(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الأصناف المطلوبة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                '${cart.items.length} أصناف (${cart.itemCount} وحدة)',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cart.items.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final item = cart.items[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.quantity} ${item.unit} × ${item.formattedUnitPrice}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.formattedLineTotal,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Cairo',
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 8),
              Text(
                'ملاحظات إضافية للمورد (اختياري)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _noteController,
            maxLines: 3,
            maxLength: 300,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'اكتب أي توجيهات خاصة بالتوصيل أو التعبئة هنا...',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
                fontFamily: 'Cairo',
              ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryLight),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsBreakdownCard(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إجمالي أمر الشراء',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...cart.totalsByCurrency.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المجموع بـ ${entry.key.arabicName}:',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Text(
                    MoneyFormatter.format(entry.value, entry.key),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Cairo',
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomSubmitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.borderSubtle),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmitOrder,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 52),
            backgroundColor: AppColors.primaryLight,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: _isSubmitting
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'جارِ إرسال أمر الشراء...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'إرسال أمر الشراء',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
