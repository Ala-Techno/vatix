/// أدوار المستخدمين في النظام
enum UserRole {
  wholesaler, // المورد (الشركة/المصنع)
  retailer; // التاجر (عميل الشركة)

  /// تحويل النص القادم من Firestore إلى Enum
  static UserRole fromString(String value) {
    switch (value) {
      case 'wholesaler':
        return UserRole.wholesaler;
      case 'retailer':
        return UserRole.retailer;
      default:
        throw ArgumentError('دور غير معروف: $value');
    }
  }

  /// تحويل إلى نص للتخزين في Firestore
  String toFirestoreString() => name; // 'wholesaler' | 'retailer'
}

/// حالة حساب التاجر
enum RetailerStatus {
  pending, // بانتظار موافقة المورد
  active, // نشط ومفعّل
  blocked; // موقوف

  /// تحويل من نص Firestore
  static RetailerStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return RetailerStatus.pending;
      case 'active':
        return RetailerStatus.active;
      case 'blocked':
        return RetailerStatus.blocked;
      default:
        return RetailerStatus.pending;
    }
  }

  /// تحويل إلى نص للتخزين في Firestore
  String toFirestoreString() => name;
}

/// [UserEntity] — كيان المستخدم النقي في طبقة Domain.
/// لا يعتمد على Flutter أو Firebase أو أي مكتبة خارجية.
class UserEntity {
  final String id; // doc.id من Firestore
  final UserRole role;
  final String businessName;
  final String ownerName;
  final String phone;
  final String city;
  final String email;
  final String? address;
  final String? avatarUrl;
  // حقول التاجر فقط
  final String? wholesalerId; // معرّف المورد المرتبط به
  final RetailerStatus? status; // حالة حساب التاجر
  final String? inviteCode; // الكود المستخدم عند التسجيل
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.role,
    required this.businessName,
    required this.ownerName,
    required this.phone,
    required this.city,
    required this.email,
    this.address,
    this.avatarUrl,
    this.wholesalerId,
    this.status,
    this.inviteCode,
    required this.createdAt,
    required this.updatedAt,
  });

  /// هل المستخدم مورد؟
  bool get isWholesaler => role == UserRole.wholesaler;

  /// هل المستخدم تاجر نشط؟
  bool get isActiveRetailer =>
      role == UserRole.retailer && status == RetailerStatus.active;
}
