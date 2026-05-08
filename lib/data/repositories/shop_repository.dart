import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/shop_item_model.dart';

class ShopRepository {
  Future<Database> get _db async => AppDatabase.instance;
  static const _uuid = Uuid();

  Future<List<String>> getOwnedItemIds(String userId) async {
    final db = await _db;
    final rows = await db.query(
      'user_inventory',
      columns: ['item_id'],
      where: 'user_id=?',
      whereArgs: [userId],
    );
    return rows.map((r) => r['item_id'] as String).toList();
  }

  Future<void> addToInventory(String userId, String itemId) async {
    final db = await _db;
    // No-op if already owned (unique user_id+item_id)
    final existing = await db.query(
      'user_inventory',
      where: 'user_id=? AND item_id=?',
      whereArgs: [userId, itemId],
    );
    if (existing.isNotEmpty) return;
    await db.insert('user_inventory', {
      'id': _uuid.v4(),
      'user_id': userId,
      'item_id': itemId,
      'purchased_at': DateTime.now().toIso8601String(),
    });
  }

  Future<bool> isOwned(String userId, String itemId) async {
    final db = await _db;
    final rows = await db.query(
      'user_inventory',
      where: 'user_id=? AND item_id=?',
      whereArgs: [userId, itemId],
    );
    return rows.isNotEmpty;
  }

  Future<void> updateEquipped(
      String userId, ShopItemType type, String itemId) async {
    final db = await _db;
    final col = switch (type) {
      ShopItemType.avatar => 'equipped_avatar_id',
      ShopItemType.border => 'equipped_border_id',
      ShopItemType.badge => 'equipped_badge_id',
    };
    await db.update('users', {col: itemId},
        where: 'id=?', whereArgs: [userId]);
  }

  Future<void> updateCoins(String userId, int coins) async {
    final db = await _db;
    await db.update('users', {'coins': coins},
        where: 'id=?', whereArgs: [userId]);
  }
}
