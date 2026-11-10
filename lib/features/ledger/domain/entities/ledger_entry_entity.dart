import 'package:vatix/core/utils/currency.dart';

/// [LedgerEntryType] — نوع قيد دفتر الأستاذ
enum LedgerEntryType {
  /// دين: نشأ من اعتماد أمر شراء بالأجل
  debt('DEBT', 'دين'),

  /// دفعة: سداد من التاجر
  payment('PAYMENT', 'دفعة');

  final String code;
  final String arabicLabel;

  const LedgerEntryType(this.code, this.arabicLabel);

  /// تحويل النص القادم من Firestore إلى [LedgerEntryType]
  static LedgerEntryType fromString(String value) {
    return LedgerEntryType.values.firstWhere(
      (t) => t.code == value.toUpperCase(),
      orElse: () => throw ArgumentError('نوع قيد غير مدعوم: $value'),
    );
  }

  /// تحويل آمن يرجع null عند الخطأ
  static LedgerEntryType? tryFromString(String? value) {
    if (value == null) return null;
    try {
      return fromString(value);
    } catch (_) {
      return null;
    }
  }
}

/// [PaymentMethod] — طريقة السداد المالي (نقد / حوالة / شيك)
enum PaymentMethod {
  cash('CASH', 'نقد'),
  transfer('TRANSFER', 'حوالة'),
  check('CHECK', 'شيك');

  final String code;
  final String arabicLabel;

  const PaymentMethod(this.code, this.arabicLabel);

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (m) => m.code == value.toUpperCase(),
      orElse: () => throw ArgumentError('طريقة سداد غير مدعومة: $value'),
    );
  }

  static PaymentMethod? tryFromString(String? value) {
    if (value == null) return null;
    try {
      return fromString(value);
    } catch (_) {
      return null;
    }
  }
}

/// [LedgerEntryEntity] — كيان قيد دفتر الأستاذ (Domain Layer)
///
/// يمثل حركة واحدة في حساب تاجر/جملة:
/// - DEBT: نشأ تلقائياً عند اعتماد أمر شراء بالأجل
/// - PAYMENT: تسجيل عند استلام الجملة دفعةً نقدية/حوالة/شيك
class LedgerEntryEntity {
  /// المعرف الفريد للقيد في Firestore
  final String id;

  /// معرف الجملة (wholesaler)
  final String wholesalerId;

  /// معرف التاجر (retailer)
  final String retailerId;

  /// نوع القيد: DEBT أو PAYMENT
  final LedgerEntryType type;

  /// المبلغ بأصغر وحدة نقدية (subunits) — دائماً موجب
  final int amount;

  /// العملة
  final Currency currency;

  /// معرف أمر الشراء المرتبط (فارغ لقيود الدفع اليدوية)
  final String orderId;

  /// معرف مُنشئ القيد (UID من Firebase Auth)
  final String createdBy;

  /// طريقة السداد (نقد، حوالة، شيك) في حالة PAYMENT
  final PaymentMethod? method;

  /// رقم المرجع أو الحوالة أو السند
  final String? reference;

  /// ملاحظة اختيارية
  final String? note;

  /// تاريخ إنشاء القيد
  final DateTime createdAt;

  const LedgerEntryEntity({
    required this.id,
    required this.wholesalerId,
    required this.retailerId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.orderId,
    required this.createdBy,
    this.method,
    this.reference,
    this.note,
    required this.createdAt,
  }) : assert(amount >= 0, 'المبلغ يجب أن يكون موجباً أو صفراً');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerEntryEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'LedgerEntryEntity(id: $id, type: ${type.code}, amount: $amount ${currency.code})';
}
