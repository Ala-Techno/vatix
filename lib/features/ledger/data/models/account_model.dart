

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vatix/core/utils/currency.dart';
import '../../domain/entities/account_entity.dart';

/// [AccountModel] — تمثيل حساب التاجر/الجملة المتصل بـ Firestore (Data Layer)
///
/// مسار المستند: `accounts/{wholesalerId}_{retailerId}`
class AccountModel extends AccountEntity {
  const AccountModel({
    required super.wholesalerId,
    required super.retailerId,
    required super.retailerName,
    required super.balances,
    required super.updatedAt,
  });

  /// إنشاء نموذج من [AccountEntity]
  factory AccountModel.fromEntity(AccountEntity entity) {
    return AccountModel(
      wholesalerId: entity.wholesalerId,
      retailerId: entity.retailerId,
      retailerName: entity.retailerName,
      balances: entity.balances,
      updatedAt: entity.updatedAt,
    );
  }

  /// تحويل من مستند Firestore [DocumentSnapshot]
  factory AccountModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return AccountModel.fromFirestoreMap(data);
  }

  /// تحويل من [QueryDocumentSnapshot] (للاستعلامات)
  factory AccountModel.fromQueryDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return AccountModel.fromFirestoreMap(doc.data());
  }

  /// تحليل خريطة البيانات القادمة من Firestore
  factory AccountModel.fromFirestoreMap(Map<String, dynamic> data) {
    final updatedAtTs = data['updatedAt'];
    final DateTime updatedAt;
    if (updatedAtTs is Timestamp) {
      updatedAt = updatedAtTs.toDate();
    } else if (updatedAtTs is DateTime) {
      updatedAt = updatedAtTs;
    } else {
      updatedAt = DateTime.now();
    }

    // تحويل خريطة الأرصدة من Firestore
    // مثال في Firestore: { "YER": 500000, "SAR": 25000 }
    final rawBalances = data['balances'] as Map<String, dynamic>? ?? {};
    final Map<Currency, int> balances = {};
    for (final entry in rawBalances.entries) {
      final currency = Currency.tryFromString(entry.key);
      if (currency != null) {
        balances[currency] = (entry.value as num?)?.toInt() ?? 0;
      }
    }

    return AccountModel(
      wholesalerId: (data['wholesalerId'] as String?) ?? '',
      retailerId: (data['retailerId'] as String?) ?? '',
      retailerName: (data['retailerName'] as String?) ?? '',
      balances: balances,
      updatedAt: updatedAt,
    );
  }

  /// تحويل إلى Map لحفظه في Firestore
  Map<String, dynamic> toFirestoreMap() {
    final rawBalances = {
      for (final entry in balances.entries) entry.key.code: entry.value,
    };

    return {
      'wholesalerId': wholesalerId,
      'retailerId': retailerId,
      'retailerName': retailerName,
      'balances': rawBalances,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
