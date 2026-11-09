/// [Currency] — العملات المعتمدة في نظام Vatix (B2B).
/// ثلاث عملات فقط: ريال يمني (YER)، ريال سعودي (SAR)، دولار أمريكي (USD).
/// يُخزَّن المبلغ دائماً كـ int بأصغر وحدة نقدية حسب عدد الخانات العشرية (decimals).
enum Currency {
  yer, // ريال يمني (decimals = 0)
  sar, // ريال سعودي (decimals = 2)
  usd; // دولار أمريكي (decimals = 2)

  /// كود العملة القياسي المعتمد للتخزين في Firestore
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

  /// الاسم العربي للعملة
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

  /// رمز العملة المختصر للعرض في الواجهة
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

  /// عدد الخانات العشرية للعملة
  int get decimals {
    switch (this) {
      case Currency.yer:
        return 0;
      case Currency.sar:
      case Currency.usd:
        return 2;
    }
  }

  /// المعامل الحسابي للتحويل بين الوحدة الأساسية والأصغر (10^decimals)
  int get multiplier {
    switch (this) {
      case Currency.yer:
        return 1;
      case Currency.sar:
      case Currency.usd:
        return 100;
    }
  }

  /// تحويل النص القادم من Firestore أو الـ API إلى [Currency]
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

  /// تحويل آمن يرجع null عند الخطأ
  static Currency? tryFromString(String? value) {
    if (value == null) return null;
    try {
      return fromString(value);
    } catch (_) {
      return null;
    }
  }

  /// تحويل إلى نص كبير للتخزين في Firestore
  String toFirestoreString() => code;
}

