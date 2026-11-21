import '../entities/order_entity.dart';

/// Representation of a ledger entry resulting from order approval
class LedgerEntryApprovalPlan {
  final String docId; // Deterministic ID: debt_{orderId}_{CUR} or pay_{orderId}_{CUR}
  final String wholesalerId;
  final String retailerId;
  final String type; // 'DEBT' or 'PAYMENT'
  final int amount;
  final String currency;
  final String orderId;
  final String createdBy;
  final String? note;

  const LedgerEntryApprovalPlan({
    required this.docId,
    required this.wholesalerId,
    required this.retailerId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.orderId,
    required this.createdBy,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'wholesalerId': wholesalerId,
      'retailerId': retailerId,
      'type': type,
      'amount': amount,
      'currency': currency,
      'orderId': orderId,
      'createdBy': createdBy,
      if (note != null) 'note': note,
    };
  }
}

/// Representation of cumulative account update in accounts/{wholesalerId}_{retailerId}
class AccountBalanceUpdatePlan {
  final String accountDocId;
  final String wholesalerId;
  final String retailerId;
  final String retailerName;
  final Map<String, int> increments; // Currency -> amount to increment via FieldValue.increment

  const AccountBalanceUpdatePlan({
    required this.accountDocId,
    required this.wholesalerId,
    required this.retailerId,
    required this.retailerName,
    required this.increments,
  });
}

/// Result of pure planning for atomic approval write (Task 4.5.1)
class OrderApprovalWritesPlan {
  final String orderId;
  final PaymentType paymentType;
  final List<LedgerEntryApprovalPlan> ledgerEntries;
  final AccountBalanceUpdatePlan? accountUpdate; // Only present in case of credit payment

  const OrderApprovalWritesPlan({
    required this.orderId,
    required this.paymentType,
    required this.ledgerEntries,
    this.accountUpdate,
  });
}

/// Pure function that builds the write plan for order approval without touching Firestore
/// Allows testing all financial and edge cases via unit tests (Task 4.5.1 & 4.5.5)
OrderApprovalWritesPlan buildApprovalWrites({
  required OrderEntity order,
  required PaymentType paymentType,
  required String currentUid,
}) {
  final entries = <LedgerEntryApprovalPlan>[];

  // 1. Create DEBT entry per currency with deterministic ID debt_{orderId}_{CUR}
  for (final entry in order.totals.entries) {
    final cur = entry.key;
    final amount = entry.value;

    entries.add(
      LedgerEntryApprovalPlan(
        docId: 'debt_${order.id}_${cur.code}',
        wholesalerId: order.wholesalerId,
        retailerId: order.retailerId,
        type: 'DEBT',
        amount: amount,
        currency: cur.code,
        orderId: order.id,
        createdBy: currentUid,
        note: 'دين أمر شراء #${order.shortId}',
      ),
    );

    // 2. If payment is cash: add immediate equal PAYMENT entry pay_{orderId}_{CUR}
    if (paymentType == PaymentType.cash) {
      entries.add(
        LedgerEntryApprovalPlan(
          docId: 'pay_${order.id}_${cur.code}',
          wholesalerId: order.wholesalerId,
          retailerId: order.retailerId,
          type: 'PAYMENT',
          amount: amount,
          currency: cur.code,
          orderId: order.id,
          createdBy: currentUid,
          note: 'نقد عند الموافقة #${order.shortId}',
        ),
      );
    }
  }

  // 3. If payment is credit: prepare account update balances.<CUR> via increment
  AccountBalanceUpdatePlan? accountUpdate;
  if (paymentType == PaymentType.credit) {
    final increments = <String, int>{};
    for (final entry in order.totals.entries) {
      increments[entry.key.code] = entry.value;
    }

    accountUpdate = AccountBalanceUpdatePlan(
      accountDocId: '${order.wholesalerId}_${order.retailerId}',
      wholesalerId: order.wholesalerId,
      retailerId: order.retailerId,
      retailerName: order.retailerName,
      increments: increments,
    );
  }

  return OrderApprovalWritesPlan(
    orderId: order.id,
    paymentType: paymentType,
    ledgerEntries: entries,
    accountUpdate: accountUpdate,
  );
}

