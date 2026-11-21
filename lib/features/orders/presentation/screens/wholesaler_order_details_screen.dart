import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/di/dependency_injection.dart';
import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/utils/money_formatter.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/usecases/approve_order_usecase.dart';
import '../../domain/usecases/reject_and_deliver_order_usecases.dart';
import '../widgets/order_approval_bottom_sheet.dart';

/// [WholesalerOrderDetailsScreen] — Incoming order details for the wholesaler (Task 4.3.2)
/// Includes:
/// 1. Retailer info (name, phone with copy action)
/// 2. Items snapshot (names, quantities, unit prices)
/// 3. Per-currency totals
/// 4. Order note (if any)
/// 5. Status badge
/// 6. Action buttons based on status (Task 4.3.3):
///    - pending: Approve button (opens bottom sheet) + Reject button
///    - approved: Confirm delivery button
class WholesalerOrderDetailsScreen extends StatefulWidget {
  final OrderEntity order;

  const WholesalerOrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  State<WholesalerOrderDetailsScreen> createState() =>
      _WholesalerOrderDetailsScreenState();
}

class _WholesalerOrderDetailsScreenState
    extends State<WholesalerOrderDetailsScreen> {
  late OrderEntity _currentOrder;

  // Stock availability check state
  bool _isCheckingStock = false;
  final List<String> _stockDeficitMessages = [];
  bool get _hasStockDeficit => _stockDeficitMessages.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    if (_currentOrder.status == OrderStatus.pending) {
      _checkStockAvailability();
    }
  }

  /// Checks real-time stock availability for each item in the order
  Future<void> _checkStockAvailability() async {
    setState(() => _isCheckingStock = true);
    _stockDeficitMessages.clear();

    try {
      final firestore = FirebaseFirestore.instance;
      for (final item in _currentOrder.items) {
        final pid = item.productId.trim();
        if (pid.isEmpty) continue;

        final doc = await firestore.collection('products').doc(pid).get();
        if (doc.exists) {
          final data = doc.data() ?? {};
          final currentStock = (data['stockQuantity'] as num?)?.toInt();
          final isAvailable = data['isAvailable'] as bool? ?? true;

          if (currentStock != null && currentStock < item.quantity) {
            _stockDeficitMessages.add(
              'الصنف "${item.name}": المطلوب (${item.quantity} ${item.unit}) والمتوفر في المخزون ($currentStock فقط).',
            );
          } else if (!isAvailable && (currentStock == null || currentStock <= 0)) {
            _stockDeficitMessages.add(
              'الصنف "${item.name}": تم إيقافه ونفذت الكمية بالكامل من المستودع.',
            );
          }
        }
      }
    } catch (_) {
      // Silently ignore network errors during proactive stock check
    }

    if (mounted) {
      setState(() => _isCheckingStock = false);
    }
  }

  void _copyPhone(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم نسخ رقم الهاتف إلى الحافظة',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openApprovalSheet() {
    final authUser = context.read<AuthProvider>().user;
    if (authUser == null) return;

    OrderApprovalBottomSheet.show(
      context: context,
      order: _currentOrder,
      onConfirm: (paymentType) async {
        final approveUseCase = getIt<ApproveOrderUseCase>();
        final params = ApproveOrderParams(
          order: _currentOrder,
          paymentType: paymentType,
          wholesalerUid: authUser.id,
        );

        final result = await approveUseCase(params);

        if (!mounted) return;

        switch (result) {
          case Success():
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'تم اعتماد أمر الشراء بنجاح (${paymentType.label})',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: AppColors.statusActive,
              ),
            );
            // Stream updates the list automatically — navigate back immediately
            Navigator.of(context).pop();
            break;
          case ApiFailure(failure: final failure):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  failure.message,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: AppColors.statusBlocked,
              ),
            );
            break;
        }
      },
    );
  }

  void _openRejectDialog() {
    final defaultReason = _hasStockDeficit
        ? 'نعتذر، نفذت كمية المخزون لبعض الأصناف المطلوبة بعد اعتماد طلبات سابقة.'
        : '';
    final reasonController = TextEditingController(text: defaultReason);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'رفض أمر الشراء',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            color: AppColors.statusBlocked,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'يرجى كتابة سبب رفض هذا الطلب (3 أحرف على الأقل):',
              style: TextStyle(fontSize: 13, fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'مثال: نقص في كمية المخزون، أو تجاوز سقف الدين...',
                hintStyle: const TextStyle(fontSize: 12, fontFamily: 'Cairo'),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.length < 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'يجب إدخال سبب رفض لا يقل عن 3 أحرف',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                    backgroundColor: AppColors.statusBlocked,
                  ),
                );
                return;
              }

              Navigator.of(ctx).pop();

              final rejectUseCase = getIt<RejectOrderUseCase>();
              final result = await rejectUseCase(
                orderId: _currentOrder.id,
                rejectionReason: reason,
              );

              if (!mounted) return;

              switch (result) {
                case Success():
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'تم تسجيل رفض أمر الشراء وتوضيح السبب للتاجر.',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                      backgroundColor: AppColors.statusBlocked,
                    ),
                  );
                  // Stream updates the list automatically — navigate back immediately
                  Navigator.of(context).pop();
                  break;
                case ApiFailure(failure: final failure):
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        failure.message,
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      backgroundColor: AppColors.statusBlocked,
                    ),
                  );
                  break;
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusBlocked,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'تأكيد الرفض',
              style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeliverOrder() async {
    final deliverUseCase = getIt<DeliverOrderUseCase>();
    final result = await deliverUseCase(orderId: _currentOrder.id);

    if (!mounted) return;

    switch (result) {
      case Success():
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تأكيد تسليم البضاعة للتاجر بنجاح.',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.primaryLight,
          ),
        );
        // Stream updates the list automatically — navigate back immediately
        Navigator.of(context).pop();
        break;
      case ApiFailure(failure: final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failure.message,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.statusBlocked,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortId = _currentOrder.id.length > 8
        ? _currentOrder.id.substring(0, 8)
        : _currentOrder.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'أمر شراء #$shortId',
          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Retailer info card
                _buildRetailerCard(),

                const SizedBox(height: 16),

                // 2. Order status card
                _buildStatusCard(),

                const SizedBox(height: 16),

                // 3. Requested items snapshot
                _buildItemsCard(),

                if (_currentOrder.note != null &&
                    _currentOrder.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildNotesCard(),
                ],

                const SizedBox(height: 16),

                // 4. Per-currency totals card
                _buildTotalsCard(),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // 5. Bottom action bar (Task 4.3.3)
          _buildActionBottomBar(),
        ],
      ),
    );
  }

  Widget _buildRetailerCard() {
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
                  Icons.storefront_rounded,
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
                      'الجهة الطالبة',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      _currentOrder.retailerName.isNotEmpty
                          ? _currentOrder.retailerName
                          : 'تاجر التجزئة',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'نسخ رقم الهاتف',
                icon: const Icon(Icons.copy_rounded, size: 20),
                color: AppColors.primaryLight,
                onPressed: () => _copyPhone('رقم التاجر المسجل'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'حالة الطلب الحالية:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currentOrder.status.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: _currentOrder.status.color,
                ),
              ),
            ],
          ),
          if (_currentOrder.paymentType != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                'السداد: ${_currentOrder.paymentType!.label}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
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
                '${_currentOrder.items.length} أصناف (${_currentOrder.totalItemCount} وحدة)',
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
            itemCount: _currentOrder.items.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final item = _currentOrder.items[index];
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
      width: double.infinity,
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
              Icon(Icons.speaker_notes_outlined, size: 18, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text(
                'ملاحظة التاجر:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currentOrder.note!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard() {
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
          ..._currentOrder.totals.entries.map((entry) {
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

  Widget _buildActionBottomBar() {
    // 1. Pending order => approve / reject with stock availability check
    if (_currentOrder.status == OrderStatus.pending) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Warning banner if there is a stock deficit or unavailable items
            if (_hasStockDeficit) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.statusBlockedBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.statusBlocked.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.statusBlocked,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تنبيه: لا يمكن اعتماد الطلب (عجز في المخزون)',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w800,
                              color: AppColors.statusBlocked,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ..._stockDeficitMessages.map(
                      (msg) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '• $msg',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'تم اعتماد طلبات أخرى استنفذت المخزون المتاح. يُرجى رفض هذا الطلب مع إشعار التاجر.',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            Row(
              children: [
                // Rejection button (always available, best option when out of stock)
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: _openRejectDialog,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: AppColors.statusBlocked,
                      side: const BorderSide(color: AppColors.statusBlocked, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'رفض الطلب',
                      style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Approval button (automatically disabled if stock deficit exists)
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: (_hasStockDeficit || _isCheckingStock)
                        ? null
                        : _openApprovalSheet,
                    icon: _isCheckingStock
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _hasStockDeficit
                                ? Icons.block_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 20,
                          ),
                    label: Text(
                      _isCheckingStock
                          ? 'جاري فحص المخزون...'
                          : _hasStockDeficit
                              ? 'المخزون غير كافٍ'
                              : 'اعتماد الطلب',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: AppColors.statusActive,
                      disabledBackgroundColor: const Color(0xFFCBD5E1),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: const Color(0xFF64748B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 2. Approved order => Confirm delivery button (Task 4.3.3)
    if (_currentOrder.status == OrderStatus.approved) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _handleDeliverOrder,
            icon: const Icon(Icons.local_shipping_outlined, size: 20),
            label: const Text(
              'تأكيد تسليم البضاعة للتاجر',
              style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      );
    }

    // In other statuses (delivered, cancelled, rejected), no action buttons
    return const SizedBox.shrink();
  }
}
