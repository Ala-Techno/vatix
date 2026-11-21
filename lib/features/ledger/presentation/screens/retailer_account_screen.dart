import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/money_formatter.dart';
import 'package:vatix/core/widgets/empty_state_widget.dart';
import 'package:vatix/core/widgets/error_state_widget.dart';
import 'package:vatix/core/widgets/shimmer_loading.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/ledger_entry_entity.dart';
import '../providers/retailer_account_provider.dart';

/// [RetailerAccountScreen] — Retailer "My Account" screen (Task 5.5)
///
/// Includes:
/// - Balance cards per currency (read-only, real-time updated Task 5.5.1)
/// - Paginated statement list with currency filters (Task 5.5.2)
/// - Account info and logout action (Task 5.5.3)
class RetailerAccountScreen extends StatefulWidget {
  const RetailerAccountScreen({super.key});

  @override
  State<RetailerAccountScreen> createState() => _RetailerAccountScreenState();
}

class _RetailerAccountScreenState extends State<RetailerAccountScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null && user.wholesalerId != null) {
        context.read<RetailerAccountProvider>().init(
              wholesalerId: user.wholesalerId!,
              retailerId: user.id,
            );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<RetailerAccountProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final provider = context.watch<RetailerAccountProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => provider.loadInitialStatement(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Account and facility info card (Task 5.5.3)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: _buildAccountInfoCard(context, user),
              ),
            ),

            // 2. Balance cards per currency (Task 5.5.1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildBalancesCard(provider.account),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // 3. Statement header and filter (Task 5.5.2)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'كشف الحركات المالية',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => provider.loadInitialStatement(),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text(
                        'تحديث',
                        style: TextStyle(fontSize: 12, fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Currency filter bar
            SliverToBoxAdapter(
              child: _buildCurrencyFilters(provider),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // 4. Statement transaction list
            _buildStatementList(provider),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  /// Account and business info card
  Widget _buildAccountInfoCard(BuildContext context, dynamic user) {
    if (user == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryLight,
                      AppColors.primaryLight.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryLight.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.businessName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Cairo',
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.ownerName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: const Text(
                  'حساب نشط',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryLight,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 16, color: AppColors.primaryLight),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          user.phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 18,
                  color: AppColors.borderSubtle,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          user.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Balance cards per currency (Task 5.5.1)
  Widget _buildBalancesCard(AccountEntity? account) {
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: Offset(0, 4),
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
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'الرصيد المستحق للمورد (لحظي)',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
              ),
              const Spacer(),
              if (account.isSettled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'الحساب مصفّر',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildBalanceColumn(
                  'ريال يمني',
                  balances[Currency.yer] ?? 0,
                  Currency.yer,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _buildBalanceColumn(
                  'ريال سعودي',
                  balances[Currency.sar] ?? 0,
                  Currency.sar,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _buildBalanceColumn(
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

  Widget _buildBalanceColumn(String label, int amount, Currency currency) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          MoneyFormatter.format(amount, currency),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  /// Currency filter bar
  Widget _buildCurrencyFilters(RetailerAccountProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildChip(
            label: 'جميع العملات',
            isSelected: provider.selectedCurrency == null,
            onTap: () => provider.setCurrencyFilter(null),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'ريال يمني',
            isSelected: provider.selectedCurrency == Currency.yer,
            onTap: () => provider.setCurrencyFilter(Currency.yer),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'ريال سعودي',
            isSelected: provider.selectedCurrency == Currency.sar,
            onTap: () => provider.setCurrencyFilter(Currency.sar),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'دولار أمريكي',
            isSelected: provider.selectedCurrency == Currency.usd,
            onTap: () => provider.setCurrencyFilter(Currency.usd),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
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

  /// Paginated statement transactions list (Task 5.5.2)
  Widget _buildStatementList(RetailerAccountProvider provider) {
    if (provider.isLoadingEntries && provider.entries.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: ShimmerLoading(
                child: ShimmerBox(
                  width: double.infinity,
                  height: 80,
                  borderRadius: 14,
                ),
              ),
            ),
            childCount: 4,
          ),
        ),
      );
    }

    if (provider.statementError != null && provider.entries.isEmpty) {
      return SliverToBoxAdapter(
        child: ErrorStateWidget(
          title: 'تعذّر جلب كشف الحساب',
          message: provider.statementError!,
          onRetry: provider.loadInitialStatement,
        ),
      );
    }

    if (provider.entries.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: EmptyStateWidget(
            icon: Icons.receipt_long_outlined,
            title: 'لا توجد حركات مالية مسجلة',
            subtitle: 'تظهر هنا جميع طلباتك الآجلة وسندات السداد المقيدة.',
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
            return _buildEntryItem(entry);
          },
          childCount: provider.entries.length + (provider.hasMore ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildEntryItem(LedgerEntryEntity entry) {
    final isDebt = entry.type == LedgerEntryType.debt;
    final badgeColor = isDebt ? AppColors.statusPending : AppColors.statusActive;
    final badgeBg = isDebt ? AppColors.statusPendingBg : AppColors.statusActiveBg;
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDebt ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
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
                if (!isDebt && entry.method != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            const SizedBox(height: 8),
            if (isDebt && entry.orderId.isNotEmpty)
              Text(
                'طلب شراء #${entry.orderId.substring(0, entry.orderId.length > 8 ? 8 : entry.orderId.length).toUpperCase()}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
            if (!isDebt && entry.reference != null && entry.reference!.isNotEmpty)
              Text(
                'سند / إشعار سداد: ${entry.reference}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
            if (entry.note != null && entry.note!.isNotEmpty)
              Text(
                entry.note!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
            const SizedBox(height: 4),
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

