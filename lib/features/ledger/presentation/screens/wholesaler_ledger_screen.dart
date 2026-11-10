import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/money_formatter.dart';
import 'package:vatix/core/widgets/empty_state_widget.dart';
import 'package:vatix/core/widgets/error_state_widget.dart';
import 'package:vatix/core/widgets/shimmer_loading.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/account_entity.dart';
import '../providers/wholesaler_ledger_provider.dart';
import 'retailer_statement_screen.dart';

/// [WholesalerLedgerScreen] — شاشة دفتر ديون المورد وحسابات التجار (Task 5.2)
class WholesalerLedgerScreen extends StatefulWidget {
  const WholesalerLedgerScreen({super.key});

  @override
  State<WholesalerLedgerScreen> createState() => _WholesalerLedgerScreenState();
}

class _WholesalerLedgerScreenState extends State<WholesalerLedgerScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<WholesalerLedgerProvider>().init(user.id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WholesalerLedgerProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          provider.retry();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. ترويسة إجمالي الذمم والديون المستحقة لكل عملة (Task 5.2.3)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: _buildReceivablesHeader(provider),
              ),
            ),

            // 2. شريط البحث والفلترة (Task 5.2.2)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: provider.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'بحث باسم التاجر أو البقالة...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: LedgerFilterMode.values.map((mode) {
                        final isSelected = provider.filterMode == mode;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ChoiceChip(
                            label: Text(
                              mode.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surface,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                            onSelected: (val) {
                              if (val) provider.setFilterMode(mode);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 12),
            ),

            // 3. قائمة حسابات التجار
            _buildAccountsList(provider),

            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }

  /// ترويسة إجمالي الذمم والديون المستحقة لكل عملة (Task 5.2.3)
  Widget _buildReceivablesHeader(WholesalerLedgerProvider provider) {
    if (provider.isLoading && provider.accounts.isEmpty) {
      return const ShimmerLoading(
        child: ShimmerBox(
          width: double.infinity,
          height: 110,
          borderRadius: 16,
        ),
      );
    }

    final totals = provider.totalReceivables;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
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
                'إجمالي الذمم والديون القائمة على التجار',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
              ),
              const Spacer(),
              Text(
                '${provider.accounts.length} تاجر',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHeaderTotalItem(
                  'ريال يمني',
                  totals[Currency.yer] ?? 0,
                  Currency.yer,
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white24),
              Expanded(
                child: _buildHeaderTotalItem(
                  'ريال سعودي',
                  totals[Currency.sar] ?? 0,
                  Currency.sar,
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white24),
              Expanded(
                child: _buildHeaderTotalItem(
                  'دولار أمريكي',
                  totals[Currency.usd] ?? 0,
                  Currency.usd,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTotalItem(String label, int amount, Currency currency) {
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
        const SizedBox(height: 2),
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

  /// محتوى قائمة الحسابات
  Widget _buildAccountsList(WholesalerLedgerProvider provider) {
    if (provider.isLoading && provider.accounts.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: ShimmerLoading(
                child: ShimmerBox(
                  width: double.infinity,
                  height: 96,
                  borderRadius: 14,
                ),
              ),
            ),
            childCount: 4,
          ),
        ),
      );
    }

    if (provider.errorMessage != null && provider.accounts.isEmpty) {
      return SliverToBoxAdapter(
        child: ErrorStateWidget(
          title: 'تعذّر جلب حسابات الدفتر',
          message: provider.errorMessage!,
          onRetry: provider.retry,
        ),
      );
    }

    final accounts = provider.filteredAccounts;

    if (accounts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: EmptyStateWidget(
            icon: Icons.book_outlined,
            title: provider.searchQuery.isNotEmpty
                ? 'لا توجد نتائج بحث مطابقة'
                : 'دفتر الحسابات فارغ',
            subtitle: provider.searchQuery.isNotEmpty
                ? 'لم يتم العثور على أي تاجر باسم "${provider.searchQuery}"'
                : 'تنشأ حسابات التجار تلقائياً فور اعتماد أول أمر شراء آجل.',
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final account = accounts[index];
            return _buildAccountTile(account);
          },
          childCount: accounts.length,
        ),
      ),
    );
  }

  /// بطاقة التاجر في قائمة الدفتر (Task 5.2.1)
  Widget _buildAccountTile(AccountEntity account) {
    final hasDebt = account.hasDebt;
    final user = context.read<AuthProvider>().user;
    final wholesalerId = user?.id ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RetailerStatementScreen(
                wholesalerId: wholesalerId,
                retailerId: account.retailerId,
                initialAccount: account,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: hasDebt
                        ? AppColors.statusPendingBg
                        : AppColors.statusActiveBg,
                    child: Icon(
                      hasDebt
                          ? Icons.person_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 20,
                      color: hasDebt
                          ? AppColors.statusPending
                          : AppColors.statusActive,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      account.retailerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasDebt
                          ? AppColors.statusPendingBg
                          : AppColors.statusActiveBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      hasDebt ? 'عليه دين' : 'مصفّر',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: hasDebt
                            ? AppColors.statusPending
                            : AppColors.statusActive,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                ],
              ),
              const Divider(height: 20),

              // عرض الأرصدة لكل عملة (Task 5.2.1)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: account.balances.entries.map((entry) {
                  final cur = entry.key;
                  final bal = entry.value;
                  final isDue = bal > 0;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDue
                          ? AppColors.statusPendingBg
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDue
                            ? AppColors.statusPending.withValues(alpha: 0.3)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${cur.arabicName}: ',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Text(
                          MoneyFormatter.format(bal, cur),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDue
                                ? AppColors.statusPending
                                : AppColors.textPrimary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

