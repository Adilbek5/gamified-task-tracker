import 'package:flutter/material.dart';
import '../core/constants/avatar_constants.dart';
import '../data/models/shop_item_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/shop_repository.dart';
import '../data/repositories/user_repository.dart';

class ShopProvider extends ChangeNotifier {
  final ShopRepository _shopRepo;
  final UserRepository _userRepo;

  List<ShopItemModel> _catalog = [];
  List<String> _ownedIds = [];
  bool _loading = false;

  List<ShopItemModel> get catalog => _catalog;
  List<String> get ownedIds => _ownedIds;
  bool get loading => _loading;

  ShopProvider(this._shopRepo, this._userRepo) {
    _initCatalog();
  }

  void _initCatalog() {
    final avatarItems = AvatarConstants.avatars.map((a) => ShopItemModel(
          id: a.id,
          name: a.name,
          description: a.description,
          price: a.price,
          type: ShopItemType.avatar,
          emoji: '',
          previewColor: a.gradient.first,
          requiredLevel: a.requiredLevel,
        ));

    final borderItems = BorderConstants.borders.map((b) => ShopItemModel(
          id: b.id,
          name: b.name,
          description: 'Profile border effect',
          price: b.price,
          type: ShopItemType.border,
          emoji: '',
          previewColor: b.color,
          requiredLevel: b.requiredLevel,
        ));

    final badgeItems = BadgeConstants.badges.map((b) => ShopItemModel(
          id: b.id,
          name: b.name,
          description: b.description,
          price: b.price,
          type: ShopItemType.badge,
          emoji: '',
          previewColor: b.color,
          requiredLevel: b.requiredLevel,
        ));

    _catalog = [...avatarItems, ...borderItems, ...badgeItems];
  }

  // ── Catalog helpers ───────────────────────────────────────────

  List<ShopItemModel> itemsByType(ShopItemType type) =>
      _catalog.where((i) => i.type == type).toList();

  bool isOwned(String itemId) => _ownedIds.contains(itemId);

  bool isEquipped(String itemId, UserModel user) =>
      user.equippedAvatarId == itemId ||
      user.equippedBorderId == itemId ||
      user.equippedBadgeId == itemId;

  // ── Convenience typed lists ───────────────────────────────────

  List<ShopItemModel> get avatars => itemsByType(ShopItemType.avatar);
  List<ShopItemModel> get borders => itemsByType(ShopItemType.border);
  List<ShopItemModel> get badges => itemsByType(ShopItemType.badge);

  // ── Data loading ──────────────────────────────────────────────

  Future<void> loadShop(UserModel user) async {
    _loading = true;
    notifyListeners();
    // Ensure default items are in inventory for new users
    for (final id in const ['avatar_default', 'border_none', 'badge_none']) {
      await _shopRepo.addToInventory(user.id, id);
    }
    _ownedIds = await _shopRepo.getOwnedItemIds(user.id);
    _loading = false;
    notifyListeners();
  }

  // ── Transactions ──────────────────────────────────────────────

  /// Returns updated [UserModel] on success (coins deducted), null if insufficient.
  Future<UserModel?> purchaseItem(ShopItemModel item, UserModel user) async {
    if (isOwned(item.id)) return user; // already owned — free equip
    if (user.coins < item.price) return null;
    if (user.level < item.requiredLevel) return null;

    final newCoins = user.coins - item.price;
    await _shopRepo.updateCoins(user.id, newCoins);
    await _shopRepo.addToInventory(user.id, item.id);
    _ownedIds = [..._ownedIds, item.id];
    notifyListeners();
    return user.copyWith(coins: newCoins);
  }

  /// Returns updated [UserModel] with new equipped ID, null if not owned.
  Future<UserModel?> equipItem(ShopItemModel item, UserModel user) async {
    if (!isOwned(item.id)) return null;
    await _shopRepo.updateEquipped(user.id, item.type, item.id);

    final updated = switch (item.type) {
      ShopItemType.avatar => user.copyWith(equippedAvatarId: item.id),
      ShopItemType.border => user.copyWith(equippedBorderId: item.id),
      ShopItemType.badge => user.copyWith(equippedBadgeId: item.id),
    };
    // Keep local DB in sync
    await _userRepo.upsert(updated);
    notifyListeners();
    return updated;
  }
}
