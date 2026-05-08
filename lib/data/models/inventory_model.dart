class InventoryModel {
  final String userId;
  final List<String> ownedItemIds;
  final String? equippedAvatarId;
  final String? equippedBorderId;
  final String? equippedBadgeId;
  final String? equippedBannerId;

  const InventoryModel({
    required this.userId,
    required this.ownedItemIds,
    this.equippedAvatarId,
    this.equippedBorderId,
    this.equippedBadgeId,
    this.equippedBannerId,
  });

  InventoryModel copyWith({
    String? userId,
    List<String>? ownedItemIds,
    String? equippedAvatarId,
    String? equippedBorderId,
    String? equippedBadgeId,
    String? equippedBannerId,
  }) =>
      InventoryModel(
        userId: userId ?? this.userId,
        ownedItemIds: ownedItemIds ?? this.ownedItemIds,
        equippedAvatarId: equippedAvatarId ?? this.equippedAvatarId,
        equippedBorderId: equippedBorderId ?? this.equippedBorderId,
        equippedBadgeId: equippedBadgeId ?? this.equippedBadgeId,
        equippedBannerId: equippedBannerId ?? this.equippedBannerId,
      );

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'owned_item_ids': ownedItemIds.join(','),
    'equipped_avatar_id': equippedAvatarId ?? 'avatar_default',
    'equipped_border_id': equippedBorderId ?? 'border_none',
    'equipped_badge_id': equippedBadgeId ?? 'badge_none',
    'equipped_banner_id': equippedBannerId ?? 'banner_none',
  };

  factory InventoryModel.fromMap(Map<String, dynamic> m) => InventoryModel(
    userId: m['user_id'],
    ownedItemIds: (m['owned_item_ids'] as String? ?? '').isEmpty
        ? []
        : (m['owned_item_ids'] as String).split(','),
    equippedAvatarId: m['equipped_avatar_id'],
    equippedBorderId: m['equipped_border_id'],
    equippedBadgeId: m['equipped_badge_id'],
    equippedBannerId: m['equipped_banner_id'],
  );

  factory InventoryModel.defaultFor(String userId) => InventoryModel(
    userId: userId,
    ownedItemIds: const [
      'avatar_default',
      'border_none',
      'badge_none',
      'banner_none',
    ],
    equippedAvatarId: 'avatar_default',
    equippedBorderId: 'border_none',
    equippedBadgeId: 'badge_none',
    equippedBannerId: 'banner_none',
  );
}
