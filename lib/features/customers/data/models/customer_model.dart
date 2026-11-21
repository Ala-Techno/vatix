import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vatix/features/auth/domain/entities/user_entity.dart';
import '../../domain/entities/customer_entity.dart';

/// [CustomerModel] — Maps retailer document from Firestore to entity
class CustomerModel extends CustomerEntity {
  const CustomerModel({
    required super.id,
    required super.businessName,
    required super.ownerName,
    required super.phone,
    required super.city,
    required super.email,
    super.address,
    super.avatarUrl,
    required super.wholesalerId,
    required super.status,
    super.inviteCode,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CustomerModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return CustomerModel(
      id: doc.id,
      businessName: data['businessName']?.toString() ?? '',
      ownerName: data['ownerName']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      city: data['city']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      address: data['address']?.toString(),
      avatarUrl: data['avatarUrl']?.toString(),
      wholesalerId: data['wholesalerId']?.toString() ?? '',
      status: data['status'] != null
          ? RetailerStatus.fromString(data['status'].toString())
          : RetailerStatus.pending,
      inviteCode: data['inviteCode']?.toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

