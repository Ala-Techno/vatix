import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/di/dependency_injection.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/money_formatter.dart';
import 'package:vatix/core/widgets/empty_state_widget.dart';
import 'package:vatix/core/widgets/error_state_widget.dart';
import 'package:vatix/core/widgets/shimmer_loading.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/ledger_entry_entity.dart';
import '../providers/retailer_statement_provider.dart';
import '../widgets/reconciliation_dialog.dart';
import '../widgets/record_payment_bottom_sheet.dart';

/// [RetailerStatementScreen] — شاشة كشف حساب التاجر وقائمة القيود وتسجيل السداد (Task 5.3)
class RetailerStatementScreen extends StatelessWidget {
  final String wholesalerId;
  final String retailerId;
  final AccountEntity? initialAccount;

  const RetailerStatementScreen({
    super.key,
    required this.wholesalerId,
    required this.retailerId,
    this.initialAccount,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RetailerStatementProvider>(
      create: (_) {
        final provider = getIt<RetailerStatementProvider>();
        provider.init(
          wholesalerId: wholesalerId,
          retailerId: retailerId,
          initialAccount: initialAccount,
        );
        return provider;
      },
      child: const _RetailerStatementContent(),
    );
  }
}

class _RetailerStatementContent extends StatefulWidget {
  const _RetailerStatementContent();

  @override
  State<_RetailerStatementContent> createState() =>
      _RetailerStatementContentState();
}

class _RetailerStatementContentState extends State<_RetailerStatementContent> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<RetailerStatementProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RetailerStatementProvider>();
    final account = provider.account;
    final retailerName = account?.retailerName.isNotEmpty == true
        ? account!.retailerName
        : 'كشف الحساب';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              retailerName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Cairo',
              ),
            ),
            const Text(
              'كشف الحساب وحركات الدفتر',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
        actions: [
          if (kDebugMode && account != null)
            IconButton(
              tooltip: 'أداة المطابقة (Debug)',
              icon: const Icon(Icons.balance_rounded, color: Colors.amber),
              onPressed: () => ReconciliationDialog.show(context, account),
            ),
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.loadInitialStatement(),
          ),
        ],
      ),
      floatingActionButton: account != null && account.hasDebt
          ? FloatingActionButton.extended(
              onPressed: () => RecordPaymentBottomSheet.show(context, account),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_card_rounded, color: Colors.white),
              label: const Text(
                'تسجيل دفعة / سداد',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                ),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => provider.loadInitialStatement(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. ترويسة الأرصدة القائمة
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildBalancesHeader(account),
              ),
            ),

            // 2. شريط فلترة العملات
            SliverToBoxAdapter(
              child: _buildCurrencyFilters(provider),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 8),
            ),

            // 3. محتوى قائمة القيود
            _buildStatementBody(provider),

            // مسافة سفلية لحساب الـ FloatingActionButton
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }

  /// ترويسة أرصدة التاجر الحالية لكل عملة (Task 5.3.1)
  Widget _buildBalancesHeader(AccountEntity? account) {
    if (account == null) {
      return const ShimmerLoading(
        child: ShimmerBox(
          width: double.infinity,
          height: 120,
          borderRadius: 16,
        ),
      );
    }

    final balances = account.balances;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'الأرصدة والذمم القائمة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                ),
              ),
              const Spacer(),
              if (account.isSettled)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.statusActiveBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'الحساب مصفّر',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.statusActive,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                  'ريال يمني',
                  balances[Currency.yer] ?? 0,
                  Currency.yer,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(
                child: _buildBalanceItem(
                  'ريال سعودي',
                  balances[Currency.sar] ?? 0,
                  Currency.sar,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(
                child: _buildBalanceItem(
                  'دولار أمريكي',
                  balances[Currency.usd] ?? 0,
                  Currency.usd,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String title, int amount, Currency currency) {
    final hasDebt = amount > 0;
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          MoneyFormatter.format(amount, currency),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: hasDebt ? AppColors.statusPending : AppColors.textPrimary,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  /// شريط تصفية القيود بالعملة
  Widget _buildCurrencyFilters(RetailerStatementProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'جميع العملات',
            isSelected: provider.selectedCurrency == null,
            onTap: () => provider.setCurrencyFilter(null),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'ريال يمني',
            isSelected: provider.selectedCurrency == Currency.yer,
            onTap: () => provider.setCurrencyFilter(Currency.yer),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'ريال سعودي',
            isSelected: provider.selectedCurrency == Currency.sar,
            onTap: () => provider.setCurrencyFilter(Currency.sar),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'دولار أمريكي',
            isSelected: provider.selectedCurrency == Currency.usd,
            onTap: () => provider.setCurrencyFilter(Currency.usd),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }

  /// جسم كشف الحساب
  Widget _buildStatementBody(RetailerStatementProvider provider) {
    if (provider.isLoadingEntries) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: List.generate(
              4,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: ShimmerLoading(
                  child: ShimmerBox(
                    width: double.infinity,
                    height: 90,
                    borderRadius: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (provider.statementError != null) {
      return SliverToBoxAdapter(
        child: ErrorStateWidget(
          title: 'تعذّر تحميل كشف الحساب',
          message: provider.statementError!,
          onRetry: () => provider.loadInitialStatement(),
        ),
      );
    }

    if (provider.entries.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: EmptyStateWidget(
            icon: Icons.receipt_long_outlined,
            title: 'لا توجد حركات مقيدة',
            subtitle:
                'لم يتم تسجيل أي طلبات آجلة أو دفعات مالية لهذا التاجر حتى الآن.',
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == provider.entries.length) {
              return provider.isLoadingMore
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const SizedBox.shrink();
            }

            final entry = provider.entries[index];
            return _buildLedgerEntryCard(entry);
          },
          childCount: provider.entries.length + (provider.hasMore ? 1 : 0),
        ),
      ),
    );
  }

  /// بطاقة قيد الدفتر الواحدة
  Widget _buildLedgerEntryCard(LedgerEntryEntity entry) {
    final isDebt = entry.type == LedgerEntryType.debt;
    final badgeColor = isDebt ? AppColors.statusPending : AppColors.statusActive;
    final badgeBg =
        isDebt ? AppColors.statusPendingBg : AppColors.statusActiveBg;
    final dateFormat = DateFormat('yyyy/MM/dd  •  hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // شارة النوع
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDebt
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 14,
                        color: badgeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        entry.type.arabicLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // تفاصيل الطريقة إن وجدت
                if (!isDebt && entry.method != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entry.method!.arabicLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),

                const Spacer(),

                // المبلغ
                Text(
                  '${isDebt ? '+' : '-'}${MoneyFormatter.format(entry.amount, entry.currency)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // معلومات إضافية
            if (isDebt && entry.orderId.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'طلب شراء: #${entry.orderId.substring(0, entry.orderId.length > 8 ? 8 : entry.orderId.length).toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),

            if (!isDebt &&
                entry.reference != null &&
                entry.reference!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'مرجع / سند: ${entry.reference}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),

            if (entry.note != null && entry.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  entry.note!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),

            // التاريخ
            Text(
              dateFormat.format(entry.createdAt),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

