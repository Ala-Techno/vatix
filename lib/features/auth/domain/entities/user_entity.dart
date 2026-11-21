/// User roles in the system
enum UserRole {
  wholesaler, // Wholesaler (company / manufacturer)
  retailer; // Retailer (client of the company)

  /// Converts Firestore string to Enum
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

  /// Converts to string for Firestore storage
  String toFirestoreString() => name; // 'wholesaler' | 'retailer'
}

/// Retailer account status
enum RetailerStatus {
  pending, // Pending wholesaler approval
  active, // Active and approved
  blocked; // Blocked / suspended

  /// Converts from Firestore string
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

  /// Converts to string for Firestore storage
  String toFirestoreString() => name;
}

/// [UserEntity] — Pure user entity in Domain layer.
/// Independent of Flutter, Firebase, or external libraries.
class UserEntity {
  final String id; // doc.id from Firestore
  final UserRole role;
  final String businessName;
  final String ownerName;
  final String phone;
  final String city;
  final String email;
  final String? address;
  final String? avatarUrl;
  // Retailer-only fields
  final String? wholesalerId; // Linked wholesaler ID
  final RetailerStatus? status; // Retailer account status
  final String? inviteCode; // Invite code used during registration
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

  /// Whether the user is a wholesaler
  bool get isWholesaler => role == UserRole.wholesaler;

  /// Whether the user is an active retailer
  bool get isActiveRetailer =>
      role == UserRole.retailer && status == RetailerStatus.active;

  UserEntity copyWith({
    String? id,
    UserRole? role,
    String? businessName,
    String? ownerName,
    String? phone,
    String? city,
    String? email,
    String? address,
    String? avatarUrl,
    String? wholesalerId,
    RetailerStatus? status,
    String? inviteCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      role: role ?? this.role,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      email: email ?? this.email,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      wholesalerId: wholesalerId ?? this.wholesalerId,
      status: status ?? this.status,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
