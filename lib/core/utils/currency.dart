/// [Currency] — Supported currencies in Vatix B2B system.
/// Three currencies only: Yemeni Rial (YER), Saudi Riyal (SAR), US Dollar (USD).
/// Amounts are always stored as int in smallest sub-units based on decimals.
enum Currency {
  yer, // Yemeni Rial (decimals = 0)
  sar, // Saudi Riyal (decimals = 2)
  usd; // US Dollar (decimals = 2)

  /// Standard currency code stored in Firestore
  String get code {
    switch (this) {
      case Currency.yer:
        return 'YER';
      case Currency.sar:
        return 'SAR';
      case Currency.usd:
        return 'USD';
    }
  }

  /// Arabic display name of the currency
  String get arabicName {
    switch (this) {
      case Currency.yer:
        return 'ريال يمني';
      case Currency.sar:
        return 'ريال سعودي';
      case Currency.usd:
        return 'دولار أمريكي';
    }
  }

  /// Short currency symbol for UI display
  String get symbol {
    switch (this) {
      case Currency.yer:
        return 'ر.ي';
      case Currency.sar:
        return 'ر.س';
      case Currency.usd:
        return '\$';
    }
  }

  /// Decimal places for the currency
  int get decimals {
    switch (this) {
      case Currency.yer:
        return 0;
      case Currency.sar:
      case Currency.usd:
        return 2;
    }
  }

  /// Multiplier to convert between main unit and smallest sub-unit (10^decimals)
  int get multiplier {
    switch (this) {
      case Currency.yer:
        return 1;
      case Currency.sar:
      case Currency.usd:
        return 100;
    }
  }

  /// Parse currency code from Firestore / API string into [Currency]
  static Currency fromString(String value) {
    switch (value.trim().toUpperCase()) {
      case 'YER':
        return Currency.yer;
      case 'SAR':
        return Currency.sar;
      case 'USD':
        return Currency.usd;
      default:
        throw ArgumentError('عملة غير مدعومة: $value');
    }
  }

  /// Safe parse returning null on invalid code
  static Currency? tryFromString(String? value) {
    if (value == null) return null;
    try {
      return fromString(value);
    } catch (_) {
      return null;
    }
  }

  /// Format as uppercase code for Firestore storage
  String toFirestoreString() => code;
}

