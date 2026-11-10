import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vatix/core/theme/app_theme.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/features/cart/presentation/widgets/cart_summary_bar.dart';

void main() {
  testWidgets('CartSummaryBar renders without layout exception under AppTheme',
      (WidgetTester tester) async {
    bool checkoutCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme, // ثيم التطبيق الذي يحتوي على minimumSize = double.infinity
        home: Scaffold(
          body: Column(
            children: [
              const Expanded(child: Placeholder()),
              CartSummaryBar(
                totalsByCurrency: const {
                  Currency.yer: 37000,
                  Currency.sar: 5200,
                },
                onCheckout: () {
                  checkoutCalled = true;
                },
              ),
            ],
          ),
        ),
      ),
    );

    // Verify it renders the currencies and labels
    expect(find.text('إجمالي السلة:'), findsOneWidget);
    expect(find.text('متابعة الطلب'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);

    // Tap the button
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(checkoutCalled, isTrue);
  });
}

