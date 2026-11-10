import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/errors/failures.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/features/auth/domain/entities/user_entity.dart';
import 'package:vatix/features/cart/domain/entities/cart_item_entity.dart';
import '../entities/order_entity.dart';
import '../entities/order_item_entity.dart';
import '../repositories/orders_repository.dart';

/// معطيات إنشاء أمر شراء جديد
class PlaceOrderParams {
  final List<CartItemEntity> cartItems;
  final UserEntity retailerUser;
  final String wholesalerName;
  final String? note;

  const PlaceOrderParams({
    required this.cartItems,
    required this.retailerUser,
    required this.wholesalerName,
    this.note,
  });
}

/// [PlaceOrderUseCase] — حالة استخدام إنشاء أمر شراء جديد
/// تتولى: بناء لقطة العناصر (Snapshot) والإجماليات لكل عملة وربط أسماء الشركات
class PlaceOrderUseCase {
  final OrdersRepository _repository;

  PlaceOrderUseCase(this._repository);

  Future<ApiResult<OrderEntity>> call(PlaceOrderParams params) async {
    // 1. التحقق من وجود عناصر بالسلة
    if (params.cartItems.isEmpty) {
      return ApiFailure(const ValidationFailure('لا يمكن إرسال أمر شراء بسلة فارغة.'));
    }

    // 2. التحقق من ارتباط التاجر بمورد
    final wholesalerId = params.retailerUser.wholesalerId?.trim();
    if (wholesalerId == null || wholesalerId.isEmpty) {
      return ApiFailure(
        const ValidationFailure('حساب التاجر غير مرتبط بأي مورد معتمد.'),
      );
    }

    // 3. التحقق من تطابق مورد جميع الأصناف
    for (final item in params.cartItems) {
      if (item.wholesalerId.trim() != wholesalerId) {
        return ApiFailure(
          const ValidationFailure(
            'تحتوي السلة على أصناف لا تنتمي إلى المورد المعتمد الخاص بك.',
          ),
        );
      }
    }

    // 4. بناء لقطة الأصناف (Items Snapshot)
    final items = params.cartItems
        .map((cartItem) => OrderItemEntity.fromCartItem(cartItem))
        .toList();

    // 5. حساب الإجماليات لكل عملة (Totals by Currency)
    final totals = <Currency, int>{};
    for (final item in items) {
      totals[item.currency] = (totals[item.currency] ?? 0) + item.lineTotal;
    }

    final retailerName = params.retailerUser.businessName.trim().isNotEmpty
        ? params.retailerUser.businessName.trim()
        : (params.retailerUser.ownerName.trim().isNotEmpty
            ? params.retailerUser.ownerName.trim()
            : 'التاجر');

    final wholesalerName = params.wholesalerName.trim().isNotEmpty
        ? params.wholesalerName.trim()
        : 'المورد المعتمد';

    final now = DateTime.now();

    final order = OrderEntity(
      id: '', // سيتم إنشاؤه بواسطة Firestore
      retailerId: params.retailerUser.id,
      wholesalerId: wholesalerId,
      retailerName: retailerName,
      wholesalerName: wholesalerName,
      items: items,
      totals: totals,
      status: OrderStatus.pending,
      note: params.note?.trim().isEmpty == true ? null : params.note?.trim(),
      hasPendingWrites: true,
      createdAt: now,
      updatedAt: now,
    );

    return _repository.placeOrder(order: order);
  }
}

