import 'package:vatix/core/utils/currency.dart';

/// [LedgerEntryType] — Ledger entry classification type
enum LedgerEntryType {
  /// Debt: generated when a purchase order is approved on credit
  debt('DEBT', 'دين'),

  /// Payment: payment made by retailer
  payment('PAYMENT', 'دفعة');

  final String code;
  final String arabicLabel;

  const LedgerEntryType(this.code, this.arabicLabel);

  /// Parse string from Firestore to [LedgerEntryType]
  static LedgerEntryType fromString(String value) {
    return LedgerEntryType.values.firstWhere(
      (t) => t.code == value.toUpperCase(),
      orElse: () => throw ArgumentError('Unsupported ledger entry type: $value'),
    );
  }

  /// Safe conversion returning null on error
  static LedgerEntryType? tryFromString(String? value) {
    if (value == null) return null;
    try {
      return fromString(value);
    } catch (_) {
      return null;
    }
  }
}

/// [PaymentMethod] — Financial settlement method (cash / transfer / check)
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
      orElse: () => throw ArgumentError('Unsupported payment method: $value'),
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

/// [LedgerEntryEntity] — Ledger entry entity (Domain Layer)
///
/// Represents a single transaction entry in retailer/wholesaler account:
/// - DEBT: automatically recorded upon approving an order on credit
/// - PAYMENT: recorded when wholesaler receives cash/transfer/check payment
class LedgerEntryEntity {
  /// Unique document ID in Firestore
  final String id;

  /// Wholesaler UID
  final String wholesalerId;

  /// Retailer UID
  final String retailerId;

  /// Entry type: DEBT or PAYMENT
  final LedgerEntryType type;

  /// Amount in smallest currency subunits — always non-negative
  final int amount;

  /// Currency
  final Currency currency;

  /// Related purchase order ID (empty for manual payment entries)
  final String orderId;

  /// Creator UID (from Firebase Auth)
  final String createdBy;

  /// Payment method in case of PAYMENT
  final PaymentMethod? method;

  /// Reference / receipt / transfer number
  final String? reference;

  /// Optional note
  final String? note;

  /// Entry creation timestamp
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
  }) : assert(amount >= 0, 'Amount must be non-negative');

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
