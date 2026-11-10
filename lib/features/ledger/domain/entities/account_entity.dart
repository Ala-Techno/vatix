import 'package:vatix/core/utils/currency.dart';

/// [AccountEntity] — كيان حساب التاجر مع الجملة (Domain Layer)
///
/// يمثل ملخص الرصيد الحالي لتاجر معين عند جملة معينة.
/// الأرصدة مخزنة كـ Map من [Currency] إلى int (بأصغر وحدة نقدية).
/// قيمة موجبة = دين على التاجر، قيمة سالبة = رصيد لصالح التاجر.
class AccountEntity {
  /// معرف الجملة
  final String wholesalerId;

  /// معرف التاجر
  final String retailerId;

  /// اسم التاجر (للعرض في الواجهة)
  final String retailerName;

  /// الأرصدة حسب العملة (subunits)
  /// مثال: { Currency.yer: 500000, Currency.sar: 25000 }
  final Map<Currency, int> balances;

  /// آخر تحديث للحساب
  final DateTime updatedAt;

  const AccountEntity({
    required this.wholesalerId,
    required this.retailerId,
    required this.retailerName,
    required this.balances,
    required this.updatedAt,
  });

  /// المعرف المركب المستخدم في Firestore: {wholesalerId}_{retailerId}
  String get documentId => '${wholesalerId}_$retailerId';

  /// رصيد عملة محددة (يرجع 0 إذا لم تكن موجودة)
  int balanceFor(Currency currency) => balances[currency] ?? 0;

  /// هل هناك دين مستحق بأي عملة؟
  bool get hasDebt => balances.values.any((v) => v > 0);

  /// هل الحساب صفري تماماً لجميع العملات؟
  bool get isSettled => balances.values.every((v) => v == 0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountEntity &&
          runtimeType == other.runtimeType &&
          wholesalerId == other.wholesalerId &&
          retailerId == other.retailerId;

  @override
  int get hashCode => wholesalerId.hashCode ^ retailerId.hashCode;

  @override
  String toString() =>
      'AccountEntity($wholesalerId/$retailerId, balances: $balances)';
}

