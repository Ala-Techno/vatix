import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vatix/core/utils/currency.dart';
import '../../domain/entities/ledger_entry_entity.dart';
import '../../domain/usecases/payment_writes_builder.dart';
import '../../domain/usecases/reconcile_ledger_use_case.dart';
import '../models/account_model.dart';
import '../models/ledger_entry_model.dart';

/// Page result for ledger statement data from Firestore
class LedgerStatementPageData {
  final List<LedgerEntryModel> entries;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  const LedgerStatementPageData({
    required this.entries,
    this.lastDocument,
    required this.hasMore,
  });
}

/// [LedgerRemoteDataSource] — Data source contract for ledger and accounts
abstract class LedgerRemoteDataSource {
  /// Real-time stream of accounts for the wholesaler (max 100)
  Stream<List<AccountModel>> watchAccounts({
    required String wholesalerId,
    int limit = 100,
  });

  /// Real-time stream of a specific account
  Stream<AccountModel?> watchAccount({
    required String wholesalerId,
    required String retailerId,
  });

  /// Fetches a page of account statement (newest first, optional currency filter)
  Future<LedgerStatementPageData> getStatement({
    required String wholesalerId,
    required String retailerId,
    Currency? currency,
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  });

  /// Records payment (cash/transfer/cheque) atomically via WriteBatch
  Future<void> recordPayment({
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

  /// Reconciles retailer entries against account balances (dev only Task 5.7)
  Future<ReconciliationReport> reconcileAccount({
    required String wholesalerId,
    required String retailerId,
    required String retailerName,
    required Map<Currency, int> accountBalances,
  });
}

/// Remote data source implementation backed by Firebase Firestore
class LedgerRemoteDataSourceImpl implements LedgerRemoteDataSource {
  final FirebaseFirestore _firestore;

  LedgerRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _accountsRef =>
      _firestore.collection('accounts');

  CollectionReference<Map<String, dynamic>> get _ledgerRef =>
      _firestore.collection('ledger');

  @override
  Stream<List<AccountModel>> watchAccounts({
    required String wholesalerId,
    int limit = 100,
  }) {
    return _accountsRef
        .where('wholesalerId', isEqualTo: wholesalerId)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AccountModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Stream<AccountModel?> watchAccount({
    required String wholesalerId,
    required String retailerId,
  }) {
    final docId = '${wholesalerId}_$retailerId';
    return _accountsRef.doc(docId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AccountModel.fromFirestore(doc);
    });
  }

  @override
  Future<LedgerStatementPageData> getStatement({
    required String wholesalerId,
    required String retailerId,
    Currency? currency,
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    Query<Map<String, dynamic>> query = _ledgerRef
        .where('wholesalerId', isEqualTo: wholesalerId)
        .where('retailerId', isEqualTo: retailerId);

    if (currency != null) {
      query = query.where('currency', isEqualTo: currency.code);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    if (startAfterDocument != null) {
      query = query.startAfterDocument(startAfterDocument);
    }

    final snapshot = await query.get();

    final entries = snapshot.docs
        .map((doc) => LedgerEntryModel.fromFirestore(doc))
        .toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    final hasMore = snapshot.docs.length >= limit;

    return LedgerStatementPageData(
      entries: entries,
      lastDocument: lastDoc,
      hasMore: hasMore,
    );
  }

  @override
  Future<void> recordPayment({
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
    final newDoc = _ledgerRef.doc();

    final plan = buildPaymentWrites(
      wholesalerId: wholesalerId,
      retailerId: retailerId,
      retailerName: retailerName,
      amount: amount,
      currency: currency,
      method: method,
      reference: reference,
      note: note,
      createdBy: createdBy,
      ledgerDocId: newDoc.id,
    );

    final batch = _firestore.batch();

    // 1. PAYMENT entry in ledger collection
    final ledgerData = plan.toLedgerData();
    ledgerData['createdAt'] = FieldValue.serverTimestamp();
    batch.set(newDoc, ledgerData);

    // 2. Update balance in accounts document via increment(-amount)
    final accountDoc = _accountsRef.doc(plan.accountDocId);
    batch.set(
      accountDoc,
      {
        'wholesalerId': plan.wholesalerId,
        'retailerId': plan.retailerId,
        'retailerName': plan.retailerName,
        'balances': {
          plan.currency.code: FieldValue.increment(plan.balanceDecrement),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // E3: Unawaited commit to avoid blocking the UI during network issues
    unawaited(batch.commit());
  }

  @override
  Future<ReconciliationReport> reconcileAccount({
    required String wholesalerId,
    required String retailerId,
    required String retailerName,
    required Map<Currency, int> accountBalances,
  }) async {
    final snapshot = await _ledgerRef
        .where('wholesalerId', isEqualTo: wholesalerId)
        .where('retailerId', isEqualTo: retailerId)
        .get();

    final entries = snapshot.docs
        .map((doc) => LedgerEntryModel.fromFirestore(doc))
        .toList();

    return computeReconciliation(
      retailerId: retailerId,
      retailerName: retailerName,
      entries: entries,
      accountBalances: accountBalances,
    );
  }
}

