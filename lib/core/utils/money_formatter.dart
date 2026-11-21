import 'package:intl/intl.dart';
import 'currency.dart';

/// [MoneyFormatter] — Currency conversion and formatting for Vatix system.
/// Strict rules:
/// 1. Money is always stored as int in smallest sub-units:
///    - YER: Value as is (decimals: 0).
///    - SAR / USD: Value × 100 (decimals: 2), e.g. 12.50 ➔ 1250, 0.99 ➔ 99.
/// 2. Strict rejection: Negative values, zero (unless explicitly allowed), decimals for YER,
///    more than 2 decimal places for SAR/USD, non-numeric strings, or exceeding safe maximum (1 trillion).
/// 3. Automatic conversion of Eastern Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩).
class MoneyFormatter {
  const MoneyFormatter._();

  /// Maximum safety cap for main unit amounts (1 trillion) to prevent field overflows
  static const int maxMainUnitAmount = 1000000000000;

  // ─────────────────────────────────────────────────────────────────────────
  // Parsing from user input (String) to int in smallest sub-units
  // ─────────────────────────────────────────────────────────────────────────

  /// Safe parse returning null on invalid input or format
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

  /// Parses user input into sub-units (int), throws [FormatException] on invalid input
  static int parseToSubunits(
    String input,
    Currency currency, {
    bool allowZero = false,
  }) {
    String clean = _normalizeDigits(input.trim());

    if (clean.isEmpty) {
      throw const FormatException('المبلغ فارغ');
    }

    // Strictly reject negative signs
    if (clean.contains('-')) {
      throw const FormatException('لا يمكن إدخال مبالغ سالبة');
    }

    // Strip thousands separators (, or ،)
    clean = _cleanThousandsSeparators(clean);

    // Normalize Arabic decimal comma (٫) to period (.)
    clean = clean.replaceAll('٫', '.');

    // Ensure no more than one decimal dot
    final dotCount = '.'.allMatches(clean).length;
    if (dotCount > 1) {
      throw const FormatException('صيغة الرقم غير صحيحة (فواصل عشرية متعددة)');
    }

    // Ensure input contains digits and at most one decimal dot
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
      // ── Yemeni Rial: No decimals allowed ──
      if (fractionalPartStr.isNotEmpty) {
        throw const FormatException('الريال اليمني لا يقبل كسوراً عشرية');
      }
      subunits = integerPart;
    } else {
      // ── Saudi Riyal / USD: Maximum 2 decimal digits ──
      if (fractionalPartStr.length > currency.decimals) {
        throw FormatException(
          'العملة (${currency.code}) لا تقبل أكثر من ${currency.decimals} خانات عشرية',
        );
      }

      // Pad fraction to decimals (e.g. .5 becomes 50)
      final paddedFraction = fractionalPartStr.padRight(currency.decimals, '0');
      final fractionPart = int.parse(paddedFraction);

      subunits = (integerPart * currency.multiplier) + fractionPart;
    }

    // Check zero condition
    if (!allowZero && subunits == 0) {
      throw const FormatException('يجب أن يكون المبلغ أكبر من الصفر');
    }

    return subunits;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Formatting int (sub-units) to display string in UI
  // ─────────────────────────────────────────────────────────────────────────

  /// Formats amount in sub-units into string with thousands separator and symbol
  /// Example:
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
  // Internal helper methods
  // ─────────────────────────────────────────────────────────────────────────

  /// Convert Eastern Arabic-Indic digits (٠-٩) and Persian digits to ASCII (0-9)
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

  /// Clean thousands separators standardly
  static String _cleanThousandsSeparators(String input) {
    // If input contains both comma and dot (e.g. "1,500.50" or "1,000,000")
    if (input.contains(',') && input.contains('.')) {
      return input.replaceAll(',', '');
    }
    // If input contains only commas followed by 3 digits (e.g. "1,500" or "10,000")
    if (RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(input)) {
      return input.replaceAll(',', '');
    }
    // If comma was used as decimal separator (e.g. "12,50") and there is no dot
    if (input.contains(',') && !input.contains('.')) {
      // If 1 or 2 digits after comma ➔ treat as decimal separator
      final parts = input.split(',');
      if (parts.length == 2 && parts[1].length <= 2) {
        return '${parts[0]}.${parts[1]}';
      }
    }
    return input;
  }
}


