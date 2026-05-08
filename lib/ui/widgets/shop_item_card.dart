import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/shop_item_model.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/shop_provider.dart';

class ShopItemCard extends StatelessWidget {
  final ShopItemModel item;
  final ShopProvider shop;
  final GamificationProvider gam;
  final VoidCallback onPurchase;
  final VoidCallback onEquip;

  const ShopItemCard({
    super.key,
    required this.item,
    required this.shop,
    required this.gam,
    required this.onPurchase,
    required this.onEquip,
  });

  static const _coinColor = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final user = gam.user;
    if (user == null) return const SizedBox();

    final owned = shop.isOwned(item.id);
    final equipped = shop.isEquipped(item.id, user);
    final locked = user.level < item.requiredLevel;

    Color bgColor = AppColors.surface;
    Color borderColor = AppColors.border;
    double borderWidth = 0.5;

    if (equipped) {
      bgColor = const Color(0xFF251500);
      borderColor = _coinColor;
      borderWidth = 1.5;
    } else if (owned) {
      bgColor = const Color(0xFF0A2010);
      borderColor = AppColors.success;
      borderWidth = 0.8;
    }

    Widget card = Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (equipped) return;
          if (owned) {
            onEquip();
          } else if (locked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Reach level ${item.requiredLevel} to unlock ${item.name}'),
                backgroundColor: AppColors.surfaceAlt,
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            onPurchase();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.emoji,
                  style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                item.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              _buildBadge(equipped, owned, locked, user.coins),
            ],
          ),
        ),
      ),
    );

    if (locked) {
      return Opacity(opacity: 0.5, child: card);
    }
    return card;
  }

  Widget _buildBadge(
      bool equipped, bool owned, bool locked, int userCoins) {
    if (equipped) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _coinColor.withOpacity(0.18),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _coinColor, width: 0.5),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check, size: 10, color: _coinColor),
          SizedBox(width: 3),
          Text('EQUIPPED',
              style: TextStyle(
                  color: _coinColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w600)),
        ]),
      );
    }
    if (owned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('OWNED',
            style: TextStyle(
                color: AppColors.success,
                fontSize: 9,
                fontWeight: FontWeight.w600)),
      );
    }
    if (locked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.textMuted.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock, size: 10, color: AppColors.textMuted),
          const SizedBox(width: 3),
          Text('Lvl ${item.requiredLevel}',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 9)),
        ]),
      );
    }
    // Buyable (enough or not enough coins)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.monetization_on, size: 10, color: _coinColor),
        const SizedBox(width: 3),
        Text('${item.price}',
            style: const TextStyle(
                color: _coinColor,
                fontSize: 9,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
