import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vatix/core/errors/exceptions.dart';
import '../models/customer_model.dart';
import '../models/invite_code_model.dart';

abstract class CustomersRemoteDataSource {
  Stream<List<CustomerModel>> watchCustomers({
    required String wholesalerId,
    required String status,
  });

  Future<void> setCustomerStatus({
    required String customerId,
    required String status,
  });

  Stream<InviteCodeModel?> watchActiveInvite({
    required String wholesalerId,
  });

  Future<String> rotateInvite({
    required String wholesalerId,
  });
}

class CustomersRemoteDataSourceImpl implements CustomersRemoteDataSource {
  final FirebaseFirestore _firestore;

  CustomersRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  // Unambiguous characters and digits (excluding O, 0, I, 1) per clause 1.3.3
  static const String _allowedChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  @override
  Stream<List<CustomerModel>> watchCustomers({
    required String wholesalerId,
    required String status,
  }) {
    return _firestore
        .collection('users')
        .where('wholesalerId', isEqualTo: wholesalerId)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerModel.fromFirestore(doc))
            .toList());
  }

 @override
  Future<void> setCustomerStatus({
    required String customerId,
    required String status,
  }) async {
    try {
      final batch = _firestore.batch();

      // 1. Customer document reference
      final userRef = _firestore.collection('users').doc(customerId);

      // 2. Update primary user status
      batch.update(userRef, {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. If customer becomes active, proactively create the account document
      if (status == 'active') {
        // Read current user data to fetch wholesalerId and customer name
        final userDoc = await userRef.get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          final wholesalerId = userData?['wholesalerId'];
          final customerName = userData?['businessName'] ?? userData?['ownerName'] ?? 'تاجر';

          if (wholesalerId != null) {
            final accountId = '${wholesalerId}_$customerId';
            final accountRef = _firestore.collection('accounts').doc(accountId);

            batch.set(
              accountRef,
              {
                'wholesalerId': wholesalerId,
                'retailerId': customerId,
                'retailerName': customerName,
                'balances': {
                  'YER': 0,
                  'SAR': 0,
                  'USD': 0,
                },
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          }
        }
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'فشل تحديث حالة العميل');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
  @override
  Stream<InviteCodeModel?> watchActiveInvite({
    required String wholesalerId,
  }) {
    return _firestore
        .collection('invites')
        .where('wholesalerId', isEqualTo: wholesalerId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return InviteCodeModel.fromFirestore(snapshot.docs.first);
    });
  }

  @override
  Future<String> rotateInvite({
    required String wholesalerId,
  }) async {
    try {
      // 1. Generate a new unique 8-character code and verify it does not already exist
      String newCode = '';
      bool exists = true;
      int attempts = 0;

      while (exists && attempts < 10) {
        newCode = _generateRandomCode(8);
        final checkDoc =
            await _firestore.collection('invites').doc(newCode).get();
        exists = checkDoc.exists;
        attempts++;
      }

      if (exists) {
        throw const ServerException(message: 'فشل توليد كود دعوة فريد، حاول ثانية');
      }

      // 2. Rotate code via WriteBatch: deactivate old codes and create new code
      final batch = _firestore.batch();

      final currentInvites = await _firestore
          .collection('invites')
          .where('wholesalerId', isEqualTo: wholesalerId)
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in currentInvites.docs) {
        batch.update(doc.reference, {'isActive': false});
      }

      final newDocRef = _firestore.collection('invites').doc(newCode);
      batch.set(newDocRef, {
        'wholesalerId': wholesalerId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      return newCode;
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'فشل تدوير كود الدعوة');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  String _generateRandomCode(int length) {
    final random = Random.secure();
    return List.generate(
      length,
      (index) => _allowedChars[random.nextInt(_allowedChars.length)],
    ).join();
  }
}

