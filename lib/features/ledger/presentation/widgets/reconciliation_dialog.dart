import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vatix/core/di/dependency_injection.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/money_formatter.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../../domain/usecases/reconcile_ledger_use_case.dart';

/// [ReconciliationDialog] — أداة مطابقة القيود مع الرصيد (Task 5.7 — للتطوير فقط)
class ReconciliationDialog extends StatefulWidget {
  final AccountEntity account;

  const ReconciliationDialog({super.key, required this.account});

  static Future<void> show(BuildContext context, AccountEntity account) {
    if (!kDebugMode) return Future.value(); // تعمل في وضع التطوير فقط

    return showDialog(
      context: context,
      builder: (_) => ReconciliationDialog(account: account),
    );
  }

  @override
  State<ReconciliationDialog> createState() => _ReconciliationDialogState();
}

class _ReconciliationDialogState extends State<ReconciliationDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  ReconciliationReport? _report;

  @override
  void initState() {
    super.initState();
    _runReconciliation();
  }

  Future<void> _runReconciliation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = getIt<LedgerRepository>();
    final result = await repo.reconcileAccount(
      wholesalerId: widget.account.wholesalerId,
      retailerId: widget.account.retailerId,
      retailerName: widget.account.retailerName,
      accountBalances: widget.account.balances,
    );

    if (!mounted) return;

    result.when(
      success: (report) {
        setState(() {
          _report = report;
          _isLoading = false;
        });
      },
      failure: (failure) {
        setState(() {
          _errorMessage = failure.message;
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. عنوان الأداة
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.balance_rounded,
                      color: Colors.amber,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'أداة مطابقة القيود والأرصدة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Text(
                          widget.account.retailerName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 2. تحذير صريح: «تقرأ كل القيود، للتطوير فقط» (Task 5.7.2)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: Colors.amber,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تنبيه: هذه الأداة تقرأ كل القيود دون تجزئة، وتعمل في وضع التطوير (Debug) فقط لمطابقة الدفتر.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB45309), // Amber dark
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),

              // 3. المحتوى
              if (_isLoading) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'جاري قراءة كافة القيود وحساب المطابقة...',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (_errorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.statusBlocked,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _runReconciliation,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ] else if (_report != null) ...[
                _buildReportContent(_report!),
              ],

              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent(ReconciliationReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // نتيجة المطابقة الإجمالية
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: report.isAllMatched
                ? AppColors.statusActiveBg
                : AppColors.statusBlockedBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: report.isAllMatched
                  ? AppColors.statusActive.withValues(alpha: 0.3)
                  : AppColors.statusBlocked.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                report.isAllMatched
                    ? Icons.check_circle_rounded
                    : Icons.error_rounded,
                color: report.isAllMatched
                    ? AppColors.statusActive
                    : AppColors.statusBlocked,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.isAllMatched
                          ? 'الحساب متطابق 100% لجميع العملات'
                          : 'يوجد عدم تطابق بين القيود والأرصدة!',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: report.isAllMatched
                            ? AppColors.statusActive
                            : AppColors.statusBlocked,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      'إجمالي القيود التي تم فحصها: ${report.totalEntriesCount} قيد',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // بطاقات المطابقة لكل عملة
        ...Currency.values.map((currency) {
          final item = report.items[currency];
          if (item == null) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      currency.arabicName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: item.isMatch
                            ? AppColors.statusActiveBg
                            : AppColors.statusBlockedBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.isMatch ? 'متطابق ✅' : 'فرق: ${item.difference}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: item.isMatch
                              ? AppColors.statusActive
                              : AppColors.statusBlocked,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'مجموع القيود: ${MoneyFormatter.format(item.ledgerSum, currency)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      'رصيد الحساب: ${MoneyFormatter.format(item.accountBalance, currency)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

