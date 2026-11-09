/// [InviteCodeEntity] — كود دعوة يخص مورداً معيناً.
class InviteCodeEntity {
  final String code; // كود الدعوة نفسه (وهو doc.id في مجموعة invites)
  final String wholesalerId; // معرف المورد صاحب الكود
  final bool isActive; // هل الكود نشط حالياً؟
  final DateTime createdAt; // وقت الإنشاء

  const InviteCodeEntity({
    required this.code,
    required this.wholesalerId,
    required this.isActive,
    required this.createdAt,
  });
}

