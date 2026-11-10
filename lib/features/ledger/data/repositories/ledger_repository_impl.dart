import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/errors/failures.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/unit.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/ledger_entry_entity.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../../domain/usecases/reconcile_ledger_use_case.dart';
import '../datasources/ledger_remote_data_source.dart';

/// [LedgerRepositoryImpl] — تنفيذ مستودع دفتر الأستاذ والأرصدة مع معالجة الأخطاء
class LedgerRepositoryImpl implements LedgerRepository {
  final LedgerRemoteDataSource _remoteDataSource;

  LedgerRepositoryImpl({required LedgerRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Stream<List<AccountEntity>> watchAccounts({
    required String wholesalerId,
    int limit = 100,
  }) {
    return _remoteDataSource.watchAccounts(
      wholesalerId: wholesalerId,
      limit: limit,
    );
  }

  @override
  Stream<AccountEntity?> watchAccount({
    required String wholesalerId,
    required String retailerId,
  }) {
    return _remoteDataSource.watchAccount(
      wholesalerId: wholesalerId,
      retailerId: retailerId,
    );
  }

  @override
  Stream<AccountEntity?> watchMyAccount({
    required String wholesalerId,
    required String retailerId,
  }) {
    return watchAccount(wholesalerId: wholesalerId, retailerId: retailerId);
  }

  @override
  Future<ApiResult<LedgerStatementPageResult>> getStatement({
    required String wholesalerId,
    required String retailerId,
    Currency? currency,
    int limit = 20,
    dynamic startAfterDocument,
  }) async {
    try {
      final pageData = await _remoteDataSource.getStatement(
        wholesalerId: wholesalerId,
        retailerId: retailerId,
        currency: currency,
        limit: limit,
        startAfterDocument:
            startAfterDocument as DocumentSnapshot<Map<String, dynamic>>?,
      );

      return Success(
        LedgerStatementPageResult(
          entries: pageData.entries,
          lastDocument: pageData.lastDocument,
          hasMore: pageData.hasMore,
        ),
      );
    } on FirebaseException catch (e) {
      return ApiFailure(ServerFailure(_mapFirebaseError(e)));
    } catch (e) {
      return ApiFailure(ServerFailure('تعذّر جلب كشف الحساب: $e'));
    }
  }

  @override
  Future<ApiResult<LedgerStatementPageResult>> getMyStatement({
    required String wholesalerId,
    required String retailerId,
    Currency? currency,
    int limit = 20,
    dynamic startAfterDocument,
  }) {
    return getStatement(
      wholesalerId: wholesalerId,
      retailerId: retailerId,
      currency: currency,
      limit: limit,
      startAfterDocument: startAfterDocument,
    );
  }

  @override
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
  }) async {
    try {
      await _remoteDataSource.recordPayment(
        wholesalerId: wholesalerId,
        retailerId: retailerId,
        retailerName: retailerName,
        amount: amount,
        currency: currency,
        method: method,
        reference: reference,
        note: note,
        createdBy: createdBy,
      );
      return const Success(unit);
    } on FirebaseException catch (e) {
      return ApiFailure(ServerFailure(_mapFirebaseError(e)));
    } catch (e) {
      return ApiFailure(ServerFailure('تعذّر تسجيل الدفعة: $e'));
    }
  }

  @override
  Future<ApiResult<ReconciliationReport>> reconcileAccount({
    required String wholesalerId,
    required String retailerId,
    required String retailerName,
    required Map<Currency, int> accountBalances,
  }) async {
    try {
      final report = await _remoteDataSource.reconcileAccount(
        wholesalerId: wholesalerId,
        retailerId: retailerId,
        retailerName: retailerName,
        accountBalances: accountBalances,
      );
      return Success(report);
    } on FirebaseException catch (e) {
      return ApiFailure(ServerFailure(_mapFirebaseError(e)));
    } catch (e) {
      return ApiFailure(ServerFailure('تعذّر إجراء المطابقة: $e'));
    }
  }

  String _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'ليس لديك صلاحية لتنفيذ هذه العملية المالية.';
      case 'unavailable':
        return 'الخدمة غير متوفرة حالياً، يرجى المحاولة لاحقاً.';
      case 'not-found':
        return 'السجل المطلوب غير موجود.';
      default:
        return 'خطأ في الاتصال بقاعدة البيانات (${e.code})';
    }
  }
}

