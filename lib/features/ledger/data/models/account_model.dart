

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vatix/core/utils/currency.dart';
import '../../domain/entities/account_entity.dart';

/// [AccountModel] — Retailer/wholesaler account representation connected to Firestore (Data Layer)
///
/// Document path: `accounts/{wholesalerId}_{retailerId}`
class AccountModel extends AccountEntity {
  const AccountModel({
    required super.wholesalerId,
    required super.retailerId,
    required super.retailerName,
    required super.balances,
    required super.updatedAt,
  });

  /// Creates a model from [AccountEntity]
  factory AccountModel.fromEntity(AccountEntity entity) {
    return AccountModel(
      wholesalerId: entity.wholesalerId,
      retailerId: entity.retailerId,
      retailerName: entity.retailerName,
      balances: entity.balances,
      updatedAt: entity.updatedAt,
    );
  }

  /// Converts from Firestore [DocumentSnapshot]
  factory AccountModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return AccountModel.fromFirestoreMap(data);
  }

  /// Converts from [QueryDocumentSnapshot] (for queries)
  factory AccountModel.fromQueryDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return AccountModel.fromFirestoreMap(doc.data());
  }

  /// Parses data map from Firestore
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

    final Map<Currency, int> balances = {};
    
    // 1. Attempt to read nested balances map properly
    final rawBalances = data['balances'];
    if (rawBalances is Map<String, dynamic>) {
      for (final entry in rawBalances.entries) {
        final currency = Currency.tryFromString(entry.key);
        if (currency != null) {
          balances[currency] = (entry.value as num?)?.toInt() ?? 0;
        }
      }
    } else {
      // 2. [Defensive fallback] Read legacy flattened fields if present in older documents
      data.forEach((key, value) {
        if (key.startsWith('balances.')) {
          final currencyCode = key.split('.').last;
          final currency = Currency.tryFromString(currencyCode);
          if (currency != null) {
            balances[currency] = (value as num?)?.toInt() ?? 0;
          }
        }
      });
    }

    return AccountModel(
      wholesalerId: (data['wholesalerId'] as String?) ?? '',
      retailerId: (data['retailerId'] as String?) ?? '',
      retailerName: (data['retailerName'] as String?) ?? '',
      balances: balances,
      updatedAt: updatedAt,
    );
  }
  /// Converts to Map for saving in Firestore
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
