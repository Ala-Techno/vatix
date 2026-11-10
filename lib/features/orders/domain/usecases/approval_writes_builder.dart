import '../entities/order_entity.dart';

/// تمثيل قيد محاسبي في الـ Ledger ناتج عن اعتماد الطلب
class LedgerEntryApprovalPlan {
  final String docId; // المعرف الحتمي: debt_{orderId}_{CUR} أو pay_{orderId}_{CUR}
  final String wholesalerId;
  final String retailerId;
  final String type; // 'DEBT' أو 'PAYMENT'
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

/// تمثيل تحديث الحساب التراكمي في accounts/{wholesalerId}_{retailerId}
class AccountBalanceUpdatePlan {
  final String accountDocId;
  final String wholesalerId;
  final String retailerId;
  final String retailerName;
  final Map<String, int> increments; // العملة -> المبلغ لزيادته عبر FieldValue.increment

  const AccountBalanceUpdatePlan({
    required this.accountDocId,
    required this.wholesalerId,
    required this.retailerId,
    required this.retailerName,
    required this.increments,
  });
}

/// نتيجة التخطيط النقي لكتابة الاعتماد الذرية (Task 4.5.1)
class OrderApprovalWritesPlan {
  final String orderId;
  final PaymentType paymentType;
  final List<LedgerEntryApprovalPlan> ledgerEntries;
  final AccountBalanceUpdatePlan? accountUpdate; // موجود فقط في حالة الدفع الآجل (credit)

  const OrderApprovalWritesPlan({
    required this.orderId,
    required this.paymentType,
    required this.ledgerEntries,
    this.accountUpdate,
  });
}

/// دالة نقية (Pure Function) تبني خطة الكتابة لعملية اعتماد الطلب دون لمس Firestore
/// تسمح باختبار كافة الحالات المالية والحدّية عبر Unit Tests (Task 4.5.1 & 4.5.5)
OrderApprovalWritesPlan buildApprovalWrites({
  required OrderEntity order,
  required PaymentType paymentType,
  required String currentUid,
}) {
  final entries = <LedgerEntryApprovalPlan>[];

  // 1. إنشاء قيد DEBT لكل عملة بمعرف حتمي debt_{orderId}_{CUR}
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

    // 2. إذا كان نوع الدفع نقدي (cash): نضيف قيد PAYMENT مساوي فوري pay_{orderId}_{CUR}
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

  // 3. إذا كان نوع الدفع آجل (credit): نجهز تحديث الحساب balances.<CUR> بـ increment
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

