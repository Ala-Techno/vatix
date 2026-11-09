import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/customer_entity.dart';
import '../providers/customers_provider.dart';

/// [CustomerCard] — بطاقة عرض بيانات التاجر مع الإجراءات المناسبة حسب حالته
class CustomerCard extends StatelessWidget {
  final CustomerEntity customer;

  const CustomerCard({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomersProvider>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _getStatusColor(customer).withValues(alpha: 0.1),
                child: Icon(
                  Icons.storefront_rounded,
                  color: _getStatusColor(customer),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.businessName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'المالك: ${customer.ownerName}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(customer),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // تفاصيل الهاتف والمدينة
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                customer.phone,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 14),
                tooltip: 'نسخ رقم الهاتف',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: customer.phone));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم نسخ رقم الهاتف'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const Spacer(),
              Icon(Icons.location_on_outlined,
                  size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                customer.city,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // أزرار الإجراءات حسب الحالة
          if (customer.isPending) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.isActionLoading
                        ? null
                        : () => provider.acceptCustomer(customer.id),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('قبول وتفعيل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: provider.isActionLoading
                        ? null
                        : () => _confirmBlock(context, provider, isReject: true),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('رفض'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (customer.isActive) ...[
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: provider.isActionLoading
                    ? null
                    : () => _confirmBlock(context, provider, isReject: false),
                icon: const Icon(Icons.block_rounded, size: 16, color: Colors.red),
                label: const Text('إيقاف / حظر التاجر',
                    style: TextStyle(color: Colors.red, fontSize: 13)),
              ),
            ),
          ] else if (customer.isBlocked) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: provider.isActionLoading
                        ? null
                        : () => provider.unblockCustomer(customer.id),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('إلغاء الحظر وإعادة التفعيل'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                      side: BorderSide(color: Colors.green.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _confirmBlock(
    BuildContext context,
    CustomersProvider provider, {
    required bool isReject,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isReject ? 'رفض طلب الانضمام' : 'حظر التاجر'),
        content: Text(
          isReject
              ? 'هل أنت متأكد من رفض طلب انضمام منشأة "${customer.businessName}"؟ سيتم تحويل حالته إلى موقوف.'
              : 'هل أنت متأكد من إيقاف منشأة "${customer.businessName}"؟ لن يتمكن من تصفح المنتجات أو إرسال طلبات جديدة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.blockCustomer(customer.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isReject ? 'تأكيد الرفض' : 'تأكيد الحظر'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(CustomerEntity customer) {
    String text;
    Color color;

    if (customer.isPending) {
      text = 'بانتظار الموافقة';
      color = Colors.orange;
    } else if (customer.isActive) {
      text = 'مفعّل';
      color = Colors.green;
    } else {
      text = 'موقوف';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(CustomerEntity customer) {
    if (customer.isPending) return Colors.orange;
    if (customer.isActive) return Colors.green;
    return Colors.red;
  }
}

