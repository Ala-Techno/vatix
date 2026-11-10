import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vatix/core/utils/currency.dart';
import '../../domain/entities/ledger_entry_entity.dart';

/// [LedgerEntryModel] — تمثيل قيد دفتر الأستاذ المتصل بـ Firestore (Data Layer)
///
/// مسار المستند: `ledger/{id}`
class LedgerEntryModel extends LedgerEntryEntity {
  const LedgerEntryModel({
    required super.id,
    required super.wholesalerId,
    required super.retailerId,
    required super.type,
    required super.amount,
    required super.currency,
    required super.orderId,
    required super.createdBy,
    super.method,
    super.reference,
    super.note,
    required super.createdAt,
  });

  /// إنشاء نموذج من [LedgerEntryEntity]
  factory LedgerEntryModel.fromEntity(LedgerEntryEntity entity) {
    return LedgerEntryModel(
      id: entity.id,
      wholesalerId: entity.wholesalerId,
      retailerId: entity.retailerId,
      type: entity.type,
      amount: entity.amount,
      currency: entity.currency,
      orderId: entity.orderId,
      createdBy: entity.createdBy,
      method: entity.method,
      reference: entity.reference,
      note: entity.note,
      createdAt: entity.createdAt,
    );
  }

  /// تحويل من مستند Firestore [DocumentSnapshot]
  factory LedgerEntryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return LedgerEntryModel.fromFirestoreMap(doc.id, data);
  }

  /// تحويل من [QueryDocumentSnapshot] (للاستعلامات)
  factory LedgerEntryModel.fromQueryDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return LedgerEntryModel.fromFirestoreMap(doc.id, doc.data());
  }

  /// المنطق الداخلي لتحليل الخريطة القادمة من Firestore
  factory LedgerEntryModel.fromFirestoreMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final createdAtTs = data['createdAt'];
    final DateTime createdAt;
    if (createdAtTs is Timestamp) {
      createdAt = createdAtTs.toDate();
    } else if (createdAtTs is DateTime) {
      createdAt = createdAtTs;
    } else {
      createdAt = DateTime.now();
    }

    return LedgerEntryModel(
      id: id,
      wholesalerId: (data['wholesalerId'] as String?) ?? '',
      retailerId: (data['retailerId'] as String?) ?? '',
      type: LedgerEntryType.fromString(
        (data['type'] as String?) ?? 'DEBT',
      ),
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      currency: Currency.fromString((data['currency'] as String?) ?? 'YER'),
      orderId: (data['orderId'] as String?) ?? '',
      createdBy: (data['createdBy'] as String?) ?? '',
      method: PaymentMethod.tryFromString(data['method'] as String?),
      reference: data['reference'] as String?,
      note: data['note'] as String?,
      createdAt: createdAt,
    );
  }

  /// تحويل إلى Map لحفظه في Firestore
  Map<String, dynamic> toFirestoreMap() {
    return {
      'wholesalerId': wholesalerId,
      'retailerId': retailerId,
      'type': type.code,
      'amount': amount,
      'currency': currency.toFirestoreString(),
      'orderId': orderId,
      'createdBy': createdBy,
      if (method != null) 'method': method!.code,
      if (reference != null && reference!.isNotEmpty) 'reference': reference,
      if (note != null && note!.isNotEmpty) 'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
