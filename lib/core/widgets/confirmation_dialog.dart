import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// [showAppConfirmationDialog] — حوار تأكيد موحد للإجراءات الحساسة
Future<bool?> showAppConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'تأكيد',
  String cancelLabel = 'إلغاء',
  IconData icon = Icons.warning_amber_rounded,
  Color confirmColor = AppColors.statusBlocked,
  bool isDestructive = true,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: confirmColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: confirmColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(90, 42),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

