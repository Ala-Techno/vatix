import 'package:vatix/features/auth/domain/entities/user_entity.dart';

/// [CustomerEntity] — يمثل عميلاً (تاجراً) يتبع لمورد معين.
class CustomerEntity {
  final String id; // معرّف التاجر في Firestore (doc.id)
  final String businessName; // اسم المحل / المنشأة
  final String ownerName; // اسم التاجر / المالك
  final String phone; // رقم الهاتف
  final String city; // المدينة
  final String email; // البريد الإلكتروني
  final String? address; // العنوان التفصيلي
  final String? avatarUrl; // صورة المنشأة إن وجدت
  final String wholesalerId; // معرف المورد التابع له
  final RetailerStatus status; // pending / active / blocked
  final String? inviteCode; // كود الدعوة الذي استخدمه عند التسجيل
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerEntity({
    required this.id,
    required this.businessName,
    required this.ownerName,
    required this.phone,
    required this.city,
    required this.email,
    this.address,
    this.avatarUrl,
    required this.wholesalerId,
    required this.status,
    this.inviteCode,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == RetailerStatus.pending;
  bool get isActive => status == RetailerStatus.active;
  bool get isBlocked => status == RetailerStatus.blocked;
}

