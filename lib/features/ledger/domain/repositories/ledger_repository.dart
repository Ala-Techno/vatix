import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/unit.dart';
import '../entities/account_entity.dart';
import '../entities/ledger_entry_entity.dart';
import '../usecases/reconcile_ledger_use_case.dart';

/// [LedgerStatementPageResult] — نتيجة صفحة كشف الحساب مع دعم الـ Pagination
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

/// [LedgerRepository] — عقد إدارة دفتر الأستاذ والأرصدة والسداد
abstract class LedgerRepository {
  // ─── Wholesaler Methods ──────────────────────────────────────────────────

  /// استماع حيّ لأرصدة جميع عملاء الجملة (بحد أقصى 100 عميل)
  Stream<List<AccountEntity>> watchAccounts({
    required String wholesalerId,
    int limit = 100,
  });

  /// كشف حساب تاجر معين بصفحات (الأحدث أولاً، مع إمكانية التصفية بالعملة)
  Future<ApiResult<LedgerStatementPageResult>> getStatement({
    required String wholesalerId,
    required String retailerId,
    Currency? currency,
    int limit = 20,
    dynamic startAfterDocument,
  });

  // ─── Retailer Methods ────────────────────────────────────────────────────

  /// استماع حيّ لحساب ورصيد التاجر مع مورد محدد
  Stream<AccountEntity?> watchMyAccount({
    required String wholesalerId,
    required String retailerId,
  });

  /// كشف حركات التاجر الخاصة بصفحات
  Future<ApiResult<LedgerStatementPageResult>> getMyStatement({
    required String wholesalerId,
    required String retailerId,
    Currency? currency,
    int limit = 20,
    dynamic startAfterDocument,
  });

  // ─── Shared / Actions ────────────────────────────────────────────────────

  /// استماع مباشر لحساب تاجر محدد (يستخدمه المورد والتاجر)
  Stream<AccountEntity?> watchAccount({
    required String wholesalerId,
    required String retailerId,
  });

  /// تسجيل سداد نقدي/حوالة/شيك وتحديث الرصيد ذرياً (WriteBatch)
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

  /// مطابقة القيود مع الرصيد المسجل (للتطوير فقط Task 5.7)
  Future<ApiResult<ReconciliationReport>> reconcileAccount({
    required String wholesalerId,
    required String retailerId,
    required String retailerName,
    required Map<Currency, int> accountBalances,
  });
}

