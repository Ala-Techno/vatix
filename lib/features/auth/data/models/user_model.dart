import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

/// [UserModel] — Data layer model.
/// Extends [UserEntity] and adds Firestore serialization logic.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.role,
    required super.businessName,
    required super.ownerName,
    required super.phone,
    required super.city,
    required super.email,
    super.address,
    super.avatarUrl,
    super.wholesalerId,
    super.status,
    super.inviteCode,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Converts directly from [DocumentSnapshot] — uses doc.id as the identifier
  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return UserModel(
      id: snapshot.id, // Always doc.id, no duplicate id field
      role: UserRole.fromString(data['role']?.toString() ?? 'retailer'),
      businessName: data['businessName']?.toString() ?? '',
      ownerName: data['ownerName']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      city: data['city']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      address: data['address']?.toString(),
      avatarUrl: data['avatarUrl']?.toString(),
      wholesalerId: data['wholesalerId']?.toString(),
      status: data['status'] != null
          ? RetailerStatus.fromString(data['status'].toString())
          : null,
      inviteCode: data['inviteCode']?.toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts to Map for saving retailer registration document in Firestore
  /// Fixed fields only — no wholesaler role, no status alteration
  static Map<String, dynamic> toFirestoreForRegistration({
    required String uid,
    required String businessName,
    required String ownerName,
    required String phone,
    required String city,
    required String email,
    required String wholesalerId,
    required String inviteCode,
  }) {
    return {
      'role': UserRole.retailer.toFirestoreString(),
      'status': RetailerStatus.pending.toFirestoreString(),
      'businessName': businessName,
      'ownerName': ownerName,
      'phone': phone,
      'city': city,
      'email': email,
      'wholesalerId': wholesalerId,
      'inviteCode': inviteCode,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
