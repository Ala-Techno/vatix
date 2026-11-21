/// [InviteCodeEntity] — Invite code belonging to a specific wholesaler.
class InviteCodeEntity {
  final String code; // The invite code itself (doc.id in invites collection)
  final String wholesalerId; // Wholesaler ID owning the code
  final bool isActive; // Whether the code is currently active
  final DateTime createdAt; // Creation timestamp

  const InviteCodeEntity({
    required this.code,
    required this.wholesalerId,
    required this.isActive,
    required this.createdAt,
  });
}

