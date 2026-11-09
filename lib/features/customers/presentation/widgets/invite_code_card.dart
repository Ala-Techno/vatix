import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/customers_provider.dart';

/// [InviteCodeCard] — بطاقة عرض كود الدعوة النشط للمورد مع إمكانية النسخ والتدوير
class InviteCodeCard extends StatelessWidget {
  const InviteCodeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomersProvider>();
    final activeInvite = provider.activeInvite;
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.vpn_key_rounded, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'كود دعوة التجار',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (activeInvite != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'نشط ومفعّل',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (activeInvite == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'لا يوجد كود دعوة نشط حالياً. اضغط لإنشاء كود.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      activeInvite.code,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'نسخ الكود',
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: activeInvite.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم نسخ كود الدعوة: ${activeInvite.code}'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: provider.isLoadingRotation
                      ? null
                      : () => _confirmRotate(context),
                  icon: provider.isLoadingRotation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.autorenew_rounded, size: 18),
                  label: const Text('تدوير الكود (إنشاء كود جديد)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmRotate(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تدوير كود الدعوة'),
        content: const Text(
          'هل أنت متأكد من تدوير الكود؟\n\n'
          '⚠️ تنبيه: سيتم تعطيل الكود القديم فوراً ولن يتمكن أي تاجر جديد من التسجيل به. التجار المسجلون مسبقاً لن يتأثروا.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final newCode =
                  await context.read<CustomersProvider>().rotateInvite();
              if (context.mounted && newCode != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم توليد الكود الجديد بنجاح: $newCode'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد التدوير'),
          ),
        ],
      ),
    );
  }
}

