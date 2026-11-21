import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/unit.dart';
import '../entities/account_entity.dart';
import '../entities/ledger_entry_entity.dart';
import '../usecases/reconcile_ledger_use_case.dart';

/// [LedgerStatementPageResult] — Paginated ledger statement result
class LedgerStatementPageResult {
  final List<LedgerEntryEntity> entries;
  final dynamic lastDocument;
  final bool hasMore;

  const LedgerStatementPageResult({
    required this.entries,
    this.lastDocument,
    required this.hasMore,
  });
}

/// [LedgerRepository] — Contract for ledger accounts, statements, and payments
abstract class LedgerRepository {
  // ─── Wholesaler Methods ──────────────────────────────────────────────────

  /// Real-time stream for all wholesaler client accounts (up to limit)
  Stream<List<AccountEntity>> watchAccounts({
    required String wholesalerId,
    int limit = 100,
  });

  /// Paginated statement for a specific retailer (newest first, optional currency filter)
  Future<ApiResult<LedgerStatementPageResult>> getStatement({
    required String wholesalerId,
    required String retailerId,
    Currency? currency,
    int limit = 20,
    dynamic startAfterDocument,
  });

  // ─── Retailer Methods ────────────────────────────────────────────────────

  /// Real-time stream for retailer account and balance with specific wholesaler
  Stream<AccountEntity?> watchMyAccount({
    required String wholesalerId,
    required String retailerId,
  });

  /// Paginated statement for the retailer's own transactions
  Future<ApiResult<LedgerStatementPageResult>> getMyStatement({
    required String wholesalerId,
    required String retailerId,
    Currency? currency,
    int limit = 20,
    dynamic startAfterDocument,
  });

  // ─── Shared / Actions ────────────────────────────────────────────────────

  /// Real-time stream for specific retailer account (used by both sides)
  Stream<AccountEntity?> watchAccount({
    required String wholesalerId,
    required String retailerId,
  });

  /// Records cash/transfer/check payment and atomically updates account balance (WriteBatch)
  Future<ApiResult<Unit>> recordPayment({
    required String wholesalerId,
    required String retailerId,
    required String retailerName,
    required int amount,
    required Currency currency,
    required PaymentMethod method,
    String? reference,
    String? note,
    required String createdBy,
  });

  /// Reconciles ledger entries against account balance (debug only, Task 5.7)
  Future<ApiResult<ReconciliationReport>> reconcileAccount({
    required String wholesalerId,
    required String retailerId,
    required String retailerName,
    required Map<Currency, int> accountBalances,
  });
}
