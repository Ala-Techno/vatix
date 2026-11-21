import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/invite_code_entity.dart';

/// [InviteCodeModel] — Maps invite code document from Firestore
class InviteCodeModel extends InviteCodeEntity {
  const InviteCodeModel({
    required super.code,
    required super.wholesalerId,
    required super.isActive,
    required super.createdAt,
  });

  factory InviteCodeModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return InviteCodeModel(
      code: doc.id,
      wholesalerId: data['wholesalerId']?.toString() ?? '',
      isActive: data['isActive'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

