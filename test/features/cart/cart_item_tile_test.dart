import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vatix/core/theme/app_theme.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/features/cart/domain/entities/cart_item_entity.dart';
import 'package:vatix/features/cart/presentation/widgets/cart_item_tile.dart';

void main() {
  const itemQty1 = CartItemEntity(
    productId: 'prod_1',
    wholesalerId: 'w1',
    name: 'حليب مكثف محلى ممتاز 390 جم طويل الاسم لتجربة الـ Overflow',
    unit: 'كرتون (48 حبة)',
    unitPrice: 18500,
    currency: Currency.yer,
    quantity: 1,
    sku: 'MLK-01',
  );

  const itemQty3 = CartItemEntity(
    productId: 'prod_2',
    wholesalerId: 'w1',
    name: 'زيت دوار الشمس صافي 1.5 لتر',
    unit: 'كرتون',
    unitPrice: 5200,
    currency: Currency.sar,
    quantity: 3,
  );

  testWidgets(
      'CartItemTile renders cleanly without any overflow even on narrow 320px screen',
      (WidgetTester tester) async {
    // Set a very narrow screen size: 320 x 600
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    bool incrementCalled = false;
    bool decrementCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ListView(
            children: [
              CartItemTile(
                item: itemQty1,
                onIncrement: () => incrementCalled = true,
                onDecrement: () => decrementCalled = true,
              ),
              CartItemTile(
                item: itemQty3,
                onIncrement: () {},
                onDecrement: () {},
              ),
            ],
          ),
        ),
      ),
    );

    // Verify item 1 shows delete icon at quantity 1
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

    // Verify item 2 shows remove icon at quantity > 1
    expect(find.byIcon(Icons.remove_rounded), findsOneWidget);

    // Tap decrement on item 1 (which has quantity 1)
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pump();
    expect(decrementCalled, isTrue);

    // Tap increment on item 1
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pump();
    expect(incrementCalled, isTrue);
  });
}

