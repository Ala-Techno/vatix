import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/money_formatter.dart';
import 'package:vatix/core/widgets/confirmation_dialog.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/ledger_entry_entity.dart';
import '../providers/retailer_statement_provider.dart';

/// [RecordPaymentBottomSheet] — Modal bottom sheet for recording payment/settlement (Tasks 5.3.2 & 5.4)
class RecordPaymentBottomSheet extends StatefulWidget {
  final AccountEntity account;

  const RecordPaymentBottomSheet({
    super.key,
    required this.account,
  });

static Future<bool?> show(BuildContext context, AccountEntity account) {
    // 1. Capture Provider from current screen context
    final statementProvider = context.read<RetailerStatementProvider>();

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        // 2. Inject Provider to make it accessible inside modal bottom sheet
        child: ChangeNotifierProvider.value(
          value: statementProvider,
          child: RecordPaymentBottomSheet(account: account),
        ),
      ),
    );
  }

  @override
  State<RecordPaymentBottomSheet> createState() =>
      _RecordPaymentBottomSheetState();
}

class _RecordPaymentBottomSheetState extends State<RecordPaymentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _noteController = TextEditingController();

  late Currency _selectedCurrency;
  PaymentMethod _selectedMethod = PaymentMethod.cash;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pick the first currency that has a positive debt, or default
    final currenciesWithDebt = widget.account.balances.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList();

    _selectedCurrency = currenciesWithDebt.isNotEmpty
        ? currenciesWithDebt.first
        : (widget.account.balances.keys.firstOrNull ?? Currency.yer);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int get _currentBalance => widget.account.balanceFor(_selectedCurrency);

  @override
  Widget build(BuildContext context) {
    final availableCurrencies = widget.account.balances.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.payments_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تسجيل دفعة نقدية / سداد',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Text(
                          widget.account.retailerName,
                          style: const TextStyle(
                            fontSize: 13,
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
              const Divider(height: 24),

              if (availableCurrencies.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'لا توجد ديون مستحقة على هذا التاجر بأي عملة حالياً.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ] else ...[
                // 1. Currency selection
                const Text(
                  'العملة المراد سدادها',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: availableCurrencies.map((c) {
                    final isSelected = c == _selectedCurrency;
                    final bal = widget.account.balanceFor(c);
                    return ChoiceChip(
                      label: Text(
                        '${c.arabicName} (${MoneyFormatter.format(bal, c)})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceVariant,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCurrency = c;
                            _amountController.clear();
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Selected currency balance
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.statusPendingBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.statusPending.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 20,
                        color: AppColors.statusPending,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'الدين القائم المستحق:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        MoneyFormatter.format(_currentBalance, _selectedCurrency),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.statusPending,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Amount input
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'مبلغ السداد',
                    hintText: _selectedCurrency.decimals > 0 ? '0.00' : '0',
                    suffixText: _selectedCurrency.symbol,
                    prefixIcon: const Icon(Icons.attach_money_rounded),
                    helperText:
                        'الحد الأقصى: ${MoneyFormatter.format(_currentBalance, _selectedCurrency)}',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال مبلغ السداد';
                    }
                    try {
                      final subunits = MoneyFormatter.parseToSubunits(
                        value,
                        _selectedCurrency,
                      );
                      if (subunits <= 0) {
                        return 'يجب أن يكون المبلغ أكبر من صفر';
                      }
                      if (subunits > _currentBalance) {
                        return 'المبلغ يتجاوز الرصيد المستحق على التاجر';
                      }
                      return null;
                    } catch (e) {
                      return 'صيغة المبلغ غير صحيحة';
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 3. Payment method
                const Text(
                  'طريقة السداد',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: PaymentMethod.values.map((method) {
                    final isSelected = method == _selectedMethod;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _selectedMethod = method);
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 42),
                            backgroundColor: isSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.surfaceVariant,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text(
                            method.arabicLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 4. Reference / receipt number (optional)
                TextFormField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: 'رقم السند أو الإيصال أو الحوالة (اختياري)',
                    prefixIcon: Icon(Icons.receipt_long_rounded),
                  ),
                ),
                const SizedBox(height: 12),

                // 5. Note (optional)
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة (اختياري)',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: 24),

                // Confirm and save payment button
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _handleConfirmPayment,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(_isSubmitting ? 'جاري الحفظ...' : 'تأكيد وحفظ الدفعة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleConfirmPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final amountSubunits = MoneyFormatter.parseToSubunits(
      _amountController.text,
      _selectedCurrency,
    );
    final remainingBalance = _currentBalance - amountSubunits;

    // Confirmation before saving showing balance before and after (Task 5.3.4)
    final confirm = await showAppConfirmationDialog(
      context: context,
      title: 'تأكيد تسجيل السداد',
      message:
          '• الرصيد القائم: ${MoneyFormatter.format(_currentBalance, _selectedCurrency)}\n'
          '• مبلغ السداد: ${MoneyFormatter.format(amountSubunits, _selectedCurrency)}\n'
          '• الرصيد بعد السداد: ${MoneyFormatter.format(remainingBalance, _selectedCurrency)}\n\n'
          'هل تريد المتابعة وحفظ السند؟',
      confirmLabel: 'تأكيد السداد',
      confirmColor: AppColors.primary,
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSubmitting = true);

    final authProvider = context.read<AuthProvider>();
    final statementProvider = context.read<RetailerStatementProvider>();
    final currentUid = authProvider.user?.id ?? '';
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final success = await statementProvider.recordPayment(
      amount: amountSubunits,
      currency: _selectedCurrency,
      method: _selectedMethod,
      reference: _referenceController.text.trim(),
      note: _noteController.text.trim(),
      createdBy: currentUid,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      navigator.pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'تم تسجيل سداد بمبلغ ${MoneyFormatter.format(amountSubunits, _selectedCurrency)} بنجاح.',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.statusActive,
        ),
      );
    } else {
      final err = statementProvider.paymentError ?? 'حدث خطأ أثناء حفظ السداد';
      messenger.showSnackBar(
        SnackBar(
          content: Text(err, style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.statusBlocked,
        ),
      );
    }
  }
}

