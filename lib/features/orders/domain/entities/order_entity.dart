import 'package:flutter/material.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/money_formatter.dart';
import 'order_item_entity.dart';

/// حالة أمر الشراء في دورة الحياة (Order Status)
enum OrderStatus {
  pending('pending', 'قيد الانتظار'),
  approved('approved', 'معتمد'),
  delivered('delivered', 'تم التوصيل'),
  rejected('rejected', 'مرفوض'),
  cancelled('cancelled', 'ملغي');

  final String name;
  final String label;

  const OrderStatus(this.name, this.label);

  static OrderStatus fromString(String? value) {
    return OrderStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == value?.toLowerCase(),
      orElse: () => OrderStatus.pending,
    );
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return AppColors.statusPending;
      case OrderStatus.approved:
        return AppColors.statusActive;
      case OrderStatus.delivered:
        return AppColors.primaryLight;
      case OrderStatus.rejected:
      case OrderStatus.cancelled:
        return AppColors.statusBlocked;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case OrderStatus.pending:
        return AppColors.statusPendingBg;
      case OrderStatus.approved:
        return AppColors.statusActiveBg;
      case OrderStatus.delivered:
        return AppColors.surfaceVariant;
      case OrderStatus.rejected:
      case OrderStatus.cancelled:
        return AppColors.statusBlockedBg;
    }
  }
}

/// طريقة سداد الطلب (Payment Type) — يحددها المورد عند القبول (M4)
enum PaymentType {
  credit('credit', 'آجل (دين)'),
  cash('cash', 'نقد (كاش)');

  final String code;
  final String label;

  const PaymentType(this.code, this.label);

  static PaymentType? fromString(String? value) {
    if (value == null) return null;
    return PaymentType.values.firstWhere(
      (p) => p.code.toLowerCase() == value.toLowerCase(),
      orElse: () => PaymentType.credit,
    );
  }
}

/// [OrderEntity] — كيان أمر الشراء الأساسي بين التاجر والمورد
class OrderEntity {
  final String id;
  final String retailerId;
  final String wholesalerId;
  final String retailerName;
  final String wholesalerName;
  final List<OrderItemEntity> items;
  final Map<Currency, int> totals; // إجمالي لكل عملة بالـ Subunits
  final OrderStatus status;
  final PaymentType? paymentType;
  final String? note;
  final String? rejectionReason;
  final String? assignedDistributorId;
  final bool hasPendingWrites; // هل الطلب بانتظار المزامنة مع الخادم (Offline E3)
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? approvedAt;
  final DateTime? deliveredAt;

  const OrderEntity({
    required this.id,
    required this.retailerId,
    required this.wholesalerId,
    required this.retailerName,
    required this.wholesalerName,
    required this.items,
    required this.totals,
    required this.status,
    this.paymentType,
    this.note,
    this.rejectionReason,
    this.assignedDistributorId,
    this.hasPendingWrites = false,
    required this.createdAt,
    required this.updatedAt,
    this.approvedAt,
    this.deliveredAt,
  });

  /// معرف مختصر ومرتب للعرض في الواجهة (مثال: #A8F2B1)
  String get shortId {
    if (id.length <= 6) return '#${id.toUpperCase()}';
    return '#${id.substring(0, 6).toUpperCase()}';
  }

  /// إجمالي عدد القطع المطلوبة في هذا الطلب
  int get totalItemCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  /// هل يمكن إلغاء الطلب من قبل التاجر (فقط عندما يكون pending)
  bool get canCancel => status == OrderStatus.pending;

  /// سلسلة نصية منسقة لجميع الإجماليات حسب العملات
  /// مثال: "45,000 ر.ي + 120.00 ر.س"
  String get formattedTotalsSummary {
    if (totals.isEmpty) return '0';
    return totals.entries
        .map((e) => MoneyFormatter.format(e.value, e.key))
        .join(' + ');
  }

  OrderEntity copyWith({
    String? id,
    String? retailerId,
    String? wholesalerId,
    String? retailerName,
    String? wholesalerName,
    List<OrderItemEntity>? items,
    Map<Currency, int>? totals,
    OrderStatus? status,
    PaymentType? paymentType,
    String? note,
    String? rejectionReason,
    String? assignedDistributorId,
    bool? hasPendingWrites,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? approvedAt,
    DateTime? deliveredAt,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      retailerId: retailerId ?? this.retailerId,
      wholesalerId: wholesalerId ?? this.wholesalerId,
      retailerName: retailerName ?? this.retailerName,
      wholesalerName: wholesalerName ?? this.wholesalerName,
      items: items ?? this.items,
      totals: totals ?? this.totals,
      status: status ?? this.status,
      paymentType: paymentType ?? this.paymentType,
      note: note ?? this.note,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      assignedDistributorId:
          assignedDistributorId ?? this.assignedDistributorId,
      hasPendingWrites: hasPendingWrites ?? this.hasPendingWrites,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}

