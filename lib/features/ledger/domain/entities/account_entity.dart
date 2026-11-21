import 'package:vatix/core/utils/currency.dart';

/// [AccountEntity] — Retailer account with wholesaler entity (Domain Layer)
///
/// Represents current balance summary for a retailer with a wholesaler.
/// Balances are stored as Map of [Currency] to int (in smallest currency subunit).
/// Positive value = debt on retailer, negative value = credit balance for retailer.
class AccountEntity {
  /// Wholesaler UID
  final String wholesalerId;

  /// Retailer UID
  final String retailerId;

  /// Retailer display name
  final String retailerName;

  /// Balances per currency (subunits)
  /// e.g.: { Currency.yer: 500000, Currency.sar: 25000 }
  final Map<Currency, int> balances;

  /// Last account update timestamp
  final DateTime updatedAt;

  const AccountEntity({
    required this.wholesalerId,
    required this.retailerId,
    required this.retailerName,
    required this.balances,
    required this.updatedAt,
  });

  /// Composite document ID used in Firestore: {wholesalerId}_{retailerId}
  String get documentId => '${wholesalerId}_$retailerId';

  /// Balance for specific currency (defaults to 0 if not present)
  int balanceFor(Currency currency) => balances[currency] ?? 0;

  /// Whether there is outstanding debt in any currency
  bool get hasDebt => balances.values.any((v) => v > 0);

  /// Whether the account is fully settled across all currencies
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
