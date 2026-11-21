import 'package:vatix/features/auth/domain/entities/user_entity.dart';

/// [CustomerEntity] — Represents a customer (retailer) associated with a wholesaler.
class CustomerEntity {
  final String id; // Retailer ID in Firestore (doc.id)
  final String businessName; // Business / shop name
  final String ownerName; // Owner name
  final String phone; // Phone number
  final String city; // City
  final String email; // Email
  final String? address; // Detailed address
  final String? avatarUrl; // Shop avatar URL if available
  final String wholesalerId; // Associated wholesaler ID
  final RetailerStatus status; // pending / active / blocked
  final String? inviteCode; // Invite code used during registration
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

