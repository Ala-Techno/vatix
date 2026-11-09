import 'package:flutter_test/flutter_test.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/money_formatter.dart';

void main() {
  group('Currency Enum Tests', () {
    test('Currency codes and properties are correct', () {
      expect(Currency.yer.code, 'YER');
      expect(Currency.yer.decimals, 0);
      expect(Currency.yer.multiplier, 1);
      expect(Currency.yer.symbol, 'ر.ي');

      expect(Currency.sar.code, 'SAR');
      expect(Currency.sar.decimals, 2);
      expect(Currency.sar.multiplier, 100);
      expect(Currency.sar.symbol, 'ر.س');

      expect(Currency.usd.code, 'USD');
      expect(Currency.usd.decimals, 2);
      expect(Currency.usd.multiplier, 100);
      expect(Currency.usd.symbol, '\$');
    });

    test('Currency.fromString parses valid strings', () {
      expect(Currency.fromString('YER'), Currency.yer);
      expect(Currency.fromString('sar'), Currency.sar);
      expect(Currency.fromString(' USD '), Currency.usd);
    });

    test('Currency.fromString throws on unsupported currency', () {
      expect(() => Currency.fromString('EUR'), throwsArgumentError);
      expect(() => Currency.fromString(''), throwsArgumentError);
    });
  });

  group('MoneyFormatter.parseToSubunits Tests', () {
    test('1500 YER ➔ 1500', () {
      final result = MoneyFormatter.parseToSubunits('1500', Currency.yer);
      expect(result, 1500);
    });

    test('12.50 SAR ➔ 1250', () {
      final result = MoneyFormatter.parseToSubunits('12.50', Currency.sar);
      expect(result, 1250);
    });

    test('12.5 SAR ➔ 1250', () {
      final result = MoneyFormatter.parseToSubunits('12.5', Currency.sar);
      expect(result, 1250);
    });

    test('0.99 USD ➔ 99', () {
      final result = MoneyFormatter.parseToSubunits('0.99', Currency.usd);
      expect(result, 99);
    });

    test('12.345 SAR is rejected (more than 2 decimal places)', () {
      expect(
        () => MoneyFormatter.parseToSubunits('12.345', Currency.sar),
        throwsFormatException,
      );
      expect(
        MoneyFormatter.tryParseToSubunits('12.345', Currency.sar),
        isNull,
      );
    });

    test('Fraction on YER is rejected', () {
      expect(
        () => MoneyFormatter.parseToSubunits('1500.5', Currency.yer),
        throwsFormatException,
      );
      expect(
        MoneyFormatter.tryParseToSubunits('1500.25', Currency.yer),
        isNull,
      );
    });

    test('Arabic-Indic digits conversion: "١٥٠٠" YER ➔ 1500, "١٢٫٥٠" SAR ➔ 1250', () {
      final yerResult = MoneyFormatter.parseToSubunits('١٥٠٠', Currency.yer);
      expect(yerResult, 1500);

      final sarResult = MoneyFormatter.parseToSubunits('١٢٫٥٠', Currency.sar);
      expect(sarResult, 1250);
    });

    test('Negative numbers are rejected', () {
      expect(
        () => MoneyFormatter.parseToSubunits('-1500', Currency.yer),
        throwsFormatException,
      );
      expect(
        () => MoneyFormatter.parseToSubunits('-12.50', Currency.sar),
        throwsFormatException,
      );
    });

    test('Zero handling: rejected by default, allowed when allowZero is true', () {
      expect(
        () => MoneyFormatter.parseToSubunits('0', Currency.yer),
        throwsFormatException,
      );
      expect(
        MoneyFormatter.parseToSubunits('0', Currency.yer, allowZero: true),
        0,
      );
      expect(
        MoneyFormatter.parseToSubunits('0.00', Currency.sar, allowZero: true),
        0,
      );
    });

    test('Non-numeric input is rejected', () {
      expect(
        () => MoneyFormatter.parseToSubunits('abc', Currency.yer),
        throwsFormatException,
      );
      expect(
        () => MoneyFormatter.parseToSubunits('12.5.5', Currency.sar),
        throwsFormatException,
      );
    });

    test('Thousands separators in input are handled cleanly', () {
      expect(
        MoneyFormatter.parseToSubunits('1,500', Currency.yer),
        1500,
      );
      expect(
        MoneyFormatter.parseToSubunits('1,000.50', Currency.sar),
        100050,
      );
    });
  });

  group('MoneyFormatter.format Tests', () {
    test('Format YER without decimals', () {
      expect(
        MoneyFormatter.format(1500, Currency.yer),
        '1,500 ر.ي',
      );
      expect(
        MoneyFormatter.format(1000000, Currency.yer),
        '1,000,000 ر.ي',
      );
    });

    test('Format SAR with 2 decimals', () {
      expect(
        MoneyFormatter.format(1250, Currency.sar),
        '12.50 ر.س',
      );
      expect(
        MoneyFormatter.format(5, Currency.sar),
        '0.05 ر.س',
      );
    });

    test('Format USD with 2 decimals', () {
      expect(
        MoneyFormatter.format(99, Currency.usd),
        '0.99 \$',
      );
      expect(
        MoneyFormatter.format(10000, Currency.usd),
        '100.00 \$',
      );
    });

    test('Format without symbol', () {
      expect(
        MoneyFormatter.format(1500, Currency.yer, includeSymbol: false),
        '1,500',
      );
      expect(
        MoneyFormatter.format(1250, Currency.sar, includeSymbol: false),
        '12.50',
      );
    });
  });
}

