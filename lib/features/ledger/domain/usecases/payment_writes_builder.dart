import 'package:vatix/core/utils/currency.dart';
import '../entities/ledger_entry_entity.dart';

/// [PaymentWritesPlan] — خطة نقية لكتابة السداد الذرية في Firestore (Task 5.4.1 & 5.4.4)
class PaymentWritesPlan {
  final String ledgerDocId;
  final String wholesalerId;
  final String retailerId;
  final String retailerName;
  final int amount;
  final Currency currency;
  final PaymentMethod method;
  final String? reference;
  final String? note;
  final String createdBy;
  final String accountDocId;
  final int balanceDecrement; // القيمة السالبة للـ FieldValue.increment (-amount)

  const PaymentWritesPlan({
    required this.ledgerDocId,
    required this.wholesalerId,
    required this.retailerId,
    required this.retailerName,
    required this.amount,
    required this.currency,
    required this.method,
    this.reference,
    this.note,
    required this.createdBy,
    required this.accountDocId,
    required this.balanceDecrement,
  });

  /// تحويل بيانات قيد الـ PAYMENT لـ Firestore
  Map<String, dynamic> toLedgerData() {
    return {
      'wholesalerId': wholesalerId,
      'retailerId': retailerId,
      'type': LedgerEntryType.payment.code,
      'amount': amount,
      'currency': currency.code,
      'orderId': '',
      'createdBy': createdBy,
      'method': method.code,
      if (reference != null && reference!.trim().isNotEmpty)
        'reference': reference!.trim(),
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
    };
  }
}

/// دالة نقية 100% لبناء خطة السداد دون لمس Firestore لتسهيل اختبار الوحدة (Task 5.4.4)
PaymentWritesPlan buildPaymentWrites({
  required String wholesalerId,
  required String retailerId,
  required String retailerName,
  required int amount,
  required Currency currency,
  required PaymentMethod method,
  String? reference,
  String? note,
  required String createdBy,
  required String ledgerDocId,
}) {
  if (amount <= 0) {
    throw ArgumentError('مبلغ السداد يجب أن يكون أكبر من الصفر');
  }
  if (wholesalerId.trim().isEmpty) {
    throw ArgumentError('معرف الجملة مطلوب');
  }
  if (retailerId.trim().isEmpty) {
    throw ArgumentError('معرف التاجر مطلوب');
  }
  if (createdBy.trim().isEmpty) {
    throw ArgumentError('معرف المستخدم المنشئ مطلوب');
  }

  final accountDocId = '${wholesalerId.trim()}_${retailerId.trim()}';

  final cleanRef = reference?.trim();
  final cleanNote = note?.trim();

  return PaymentWritesPlan(
    ledgerDocId: ledgerDocId,
    wholesalerId: wholesalerId.trim(),
    retailerId: retailerId.trim(),
    retailerName: retailerName.trim(),
    amount: amount,
    currency: currency,
    method: method,
    reference: (cleanRef != null && cleanRef.isNotEmpty) ? cleanRef : null,
    note: (cleanNote != null && cleanNote.isNotEmpty) ? cleanNote : null,
    createdBy: createdBy.trim(),
    accountDocId: accountDocId,
    balanceDecrement: -amount,
  );
}

