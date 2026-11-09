import 'package:intl/intl.dart';
import 'currency.dart';

/// [MoneyFormatter] — تحويل وتنسيق المبالغ المالية لنظام Vatix.
/// القواعد الصارمة:
/// 1. المال يُخزَّن دائماً كـ int بأصغر وحدة (Subunits):
///    - YER: القيمة كما هي (decimals: 0).
///    - SAR / USD: القيمة × 100 (decimals: 2) مثل 12.50 ➔ 1250، 0.99 ➔ 99.
/// 2. الرفض الصارم: السالب، الصفر (إلا بإذن صريح)، الكسور لـ YER، أكثر من خانتين لـ SAR/USD،
///    النصوص غير الرقمية، أو تجاوز الحد الأقصى الآمن (تريليون).
/// 3. دعم الأرقام العربية-الهندية (٠١٢٣٤٥٦٧٨٩) وتحويلها تلقائياً.
class MoneyFormatter {
  const MoneyFormatter._();

  /// سقف أمان أقصى للمبالغ بالوحدة الأساسية (تريليون) لمنع أخطاء الحقول
  static const int maxMainUnitAmount = 1000000000000;

  // ─────────────────────────────────────────────────────────────────────────
  // التحويل من إدخال المستخدم (نص) إلى int بأصغر وحدة
  // ─────────────────────────────────────────────────────────────────────────

  /// تحويل آمن يرجع null عند أي خطأ في الإدخال أو الصيغة
  static int? tryParseToSubunits(
    String? input,
    Currency currency, {
    bool allowZero = false,
  }) {
    if (input == null) return null;
    try {
      return parseToSubunits(input, currency, allowZero: allowZero);
    } catch (_) {
      return null;
    }
  }

  /// تحويل إدخال المستخدم إلى أصغر وحدة (int)، ويرمي [FormatException] عند وجود خطأ
  static int parseToSubunits(
    String input,
    Currency currency, {
    bool allowZero = false,
  }) {
    String clean = _normalizeDigits(input.trim());

    if (clean.isEmpty) {
      throw const FormatException('المبلغ فارغ');
    }

    // رفض الإشارات السالبة قطعياً
    if (clean.contains('-')) {
      throw const FormatException('لا يمكن إدخال مبالغ سالبة');
    }

    // إزالة فواصل الآلاف الشائعة (، أو ,) إذا كانت تفصل خانات الآلاف
    clean = _cleanThousandsSeparators(clean);

    // توحيد الفاصلة العشرية العربية (٫) إلى النقطة الإنجليزية (.)
    clean = clean.replaceAll('٫', '.');

    // التأكد من عدم وجود أكثر من فاصلة عشرية واحدة
    final dotCount = '.'.allMatches(clean).length;
    if (dotCount > 1) {
      throw const FormatException('صيغة الرقم غير صحيحة (فواصل عشرية متعددة)');
    }

    // التأكد أن النص يحتوي فقط على أرقام ونقطة واحدة كحد أقصى
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(clean)) {
      throw const FormatException('المبلغ يحتوي على أحرف أو رموز غير صالحة');
    }

    final parts = clean.split('.');
    final integerPartStr = parts[0];
    final fractionalPartStr = parts.length > 1 ? parts[1] : '';

    final integerPart = int.tryParse(integerPartStr);
    if (integerPart == null || integerPart > maxMainUnitAmount) {
      throw const FormatException('المبلغ يتجاوز الحد الأقصى المسموح به');
    }

    int subunits = 0;

    if (currency.decimals == 0) {
      // ── ريال يمني: ممنوع وجود أي كسر أو خانة عشرية ──
      if (fractionalPartStr.isNotEmpty) {
        throw const FormatException('الريال اليمني لا يقبل كسوراً عشرية');
      }
      subunits = integerPart;
    } else {
      // ── ريال سعودي / دولار: حد أقصى خانتان عشريتان ──
      if (fractionalPartStr.length > currency.decimals) {
        throw FormatException(
          'العملة (${currency.code}) لا تقبل أكثر من ${currency.decimals} خانات عشرية',
        );
      }

      // ضبط الخانات العشرية إلى خانتين (مثلاً .5 تصبح 50)
      final paddedFraction = fractionalPartStr.padRight(currency.decimals, '0');
      final fractionPart = int.parse(paddedFraction);

      subunits = (integerPart * currency.multiplier) + fractionPart;
    }

    // فحص الصفر
    if (!allowZero && subunits == 0) {
      throw const FormatException('يجب أن يكون المبلغ أكبر من الصفر');
    }

    return subunits;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // تنسيق int (أصغر وحدة) إلى نص للعرض في الواجهة
  // ─────────────────────────────────────────────────────────────────────────

  /// تنسيق المبلغ من أصغر وحدة إلى نص بفواصل الآلاف ورمز العملة
  /// مثال:
  /// - 1500 (YER) ➔ "1,500 ر.ي"
  /// - 1250 (SAR) ➔ "12.50 ر.س"
  /// - 99 (USD)   ➔ "0.99 $"
  static String format(
    int amountInSubunits,
    Currency currency, {
    bool includeSymbol = true,
  }) {
    final isNegative = amountInSubunits < 0;
    final absAmount = amountInSubunits.abs();

    String formattedNumber;

    if (currency.decimals == 0) {
      final formatter = NumberFormat('#,##0', 'en_US');
      formattedNumber = formatter.format(absAmount);
    } else {
      final integerPart = absAmount ~/ currency.multiplier;
      final fractionPart = absAmount % currency.multiplier;

      final formatter = NumberFormat('#,##0', 'en_US');
      final integerFormatted = formatter.format(integerPart);
      final fractionFormatted =
          fractionPart.toString().padLeft(currency.decimals, '0');

      formattedNumber = '$integerFormatted.$fractionFormatted';
    }

    if (isNegative) {
      formattedNumber = '-$formattedNumber';
    }

    if (!includeSymbol) {
      return formattedNumber;
    }

    return '$formattedNumber ${currency.symbol}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // دوال مساعدة داخلية
  // ─────────────────────────────────────────────────────────────────────────

  /// تحويل الأرقام العربية-الهندية (٠-٩) والفارسية إلى أرقام ASCII (0-9)
  static String _normalizeDigits(String input) {
    const easternArabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const persianArabic = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    const westernDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    String output = input;
    for (int i = 0; i < 10; i++) {
      output = output.replaceAll(easternArabic[i], westernDigits[i]);
      output = output.replaceAll(persianArabic[i], westernDigits[i]);
    }
    return output;
  }

  /// إزالة فواصل الآلاف عند وجودها بطريقة قياسية
  static String _cleanThousandsSeparators(String input) {
    // إذا احتوى على فاصلة مثل "1,500.50" أو "1,000,000"
    if (input.contains(',') && input.contains('.')) {
      return input.replaceAll(',', '');
    }
    // إذا كان يحتوي فقط على فواصل متبوعة بـ 3 أرقام (مثل "1,500" أو "10,000")
    if (RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(input)) {
      return input.replaceAll(',', '');
    }
    // إذا استخدمت الفاصلة كفاصلة عشرية (مثلاً "12,50") وليس هناك نقطة
    if (input.contains(',') && !input.contains('.')) {
      // إذا كان بعد الفاصلة 1 أو 2 خانات فقط ➔ نعاملها كفاصلة عشرية
      final parts = input.split(',');
      if (parts.length == 2 && parts[1].length <= 2) {
        return '${parts[0]}.${parts[1]}';
      }
    }
    return input;
  }
}

