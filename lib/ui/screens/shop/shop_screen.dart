import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/avatar_constants.dart';
import '../../../data/models/shop_item_model.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/shop_provider.dart';
import '../../../widgets/animated_card.dart';

class ShopScreen extends StatefulWidget {
  final UserModel user;
  const ShopScreen({super.key, required this.user});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  static const _tabs = [
    Tab(text: 'Avatars'),
    Tab(text: 'Borders'),
    Tab(text: 'Badges'),
  ];

  static const _types = [
    ShopItemType.avatar,
    ShopItemType.border,
    ShopItemType.badge,
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ShopProvider>().loadShop(widget.user);
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  UserModel get _user =>
      context.read<AuthProvider>().user ?? widget.user;

  Future<void> _onItemTap(ShopItemModel item) async {
    final shop = context.read<ShopProvider>();
    final auth = context.read<AuthProvider>();
    final user = _user;

    final owned = shop.isOwned(item.id);
    final equipped = shop.isEquipped(item.id, user);

    if (equipped) return;

    if (owned) {
      final updated = await shop.equipItem(item, user);
      if (updated != null && mounted) {
        auth.refresh(updated);
        _showSnack('${item.name} equipped!', const Color(0xFF22C55E));
      }
      return;
    }

    if (!mounted) return;
    await _showBuyDialog(item, user);
  }

  Future<void> _showBuyDialog(ShopItemModel item, UserModel user) async {
    final canAfford = user.coins >= item.price;
    final canLevel = user.level >= item.requiredLevel;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF191D30),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          _ItemPreview(item: item, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.description,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Color(0xFF848A94)),
            ),
            const SizedBox(height: 16),
            Row(children: [
              const Icon(Icons.monetization_on_rounded,
                  color: Color(0xFFFFD700), size: 18),
              const SizedBox(width: 6),
              Text(
                'Price: ${item.price} coins',
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.white),
              ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.bar_chart,
                  size: 16,
                  color: canLevel
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFEF4444)),
              const SizedBox(width: 6),
              Text(
                'Required level: ${item.requiredLevel}',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: canLevel
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444)),
              ),
            ]),
            if (!canAfford)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Not enough coins',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFFEF4444)),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF848A94))),
          ),
          ElevatedButton(
            onPressed: (canAfford && canLevel)
                ? () async {
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    final shop = context.read<ShopProvider>();
                    final auth = context.read<AuthProvider>();
                    final updated =
                        await shop.purchaseItem(item, _user);
                    if (!mounted) return;
                    if (updated != null) {
                      auth.refresh(updated);
                      _showSnack('${item.name} purchased!',
                          const Color(0xFF3580FF));
                      final equipped =
                          await shop.equipItem(item, updated);
                      if (equipped != null && mounted) {
                        auth.refresh(equipped);
                      }
                    } else {
                      _showSnack(
                          'Purchase failed',
                          const Color(0xFFEF4444));
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3580FF),
              disabledBackgroundColor: const Color(0xFF2D2D2D),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              item.price == 0 ? 'Get Free' : 'Buy for ${item.price} 🪙',
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user ?? widget.user;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C16),
      body: SafeArea(
        child: Column(children: [
          // ── Top bar ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFF191D30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 16),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Shop',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF191D30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.monetization_on_rounded,
                      color: Color(0xFFFFD700), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${user.coins}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ]),
              ),
            ]),
          ),

          // ── Tab bar ───────────────────────────────────────
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF191D30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: const Color(0xFF3580FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF848A94),
                tabs: _tabs,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Tab content ──────────────────────────────────
          Expanded(
            child: shop.loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF3580FF)))
                : TabBarView(
                    controller: _tab,
                    children: List.generate(3, (i) {
                      final items = shop.itemsByType(_types[i]);
                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: items.length,
                        itemBuilder: (_, idx) => AnimatedCard(
                          index: idx,
                          child: _ItemCard(
                            item: items[idx],
                            user: user,
                            shop: shop,
                            onTap: () => _onItemTap(items[idx]),
                          ),
                        ),
                      );
                    }),
                  ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ITEM CARD
// ─────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  final ShopItemModel item;
  final UserModel user;
  final ShopProvider shop;
  final VoidCallback onTap;

  const _ItemCard({
    required this.item,
    required this.user,
    required this.shop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final owned = shop.isOwned(item.id);
    final equipped = shop.isEquipped(item.id, user);
    final locked = user.level < item.requiredLevel;

    return GestureDetector(
      onTap: locked ? null : onTap,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: const Color(0xFF191D30),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: equipped
                    ? const Color(0xFF3580FF)
                    : locked
                        ? const Color(0xFF2A2E42)
                        : const Color(0xFF252A3D),
                width: equipped ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: _ItemPreview(item: item, size: 64)),
                  const SizedBox(height: 8),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  if (equipped)
                    _badge('EQUIPPED', const Color(0xFF3580FF))
                  else if (owned)
                    _badge('OWNED', const Color(0xFF22C55E))
                  else
                    Row(children: [
                      const Icon(Icons.monetization_on_rounded,
                          color: Color(0xFFFFD700), size: 13),
                      const SizedBox(width: 3),
                      Text(
                        item.price == 0 ? 'Free' : '${item.price}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                    ]),
                ],
              ),
            ),
          ),
          if (locked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, color: Colors.white54, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      'Lv.${item.requiredLevel}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(

        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color),
        ),
      );
}

// ─────────────────────────────────────────────
//  ITEM PREVIEW (gradient-based, replaces emoji)
// ─────────────────────────────────────────────
class _ItemPreview extends StatelessWidget {
  final ShopItemModel item;
  final double size;

  const _ItemPreview({required this.item, required this.size});

  @override
  Widget build(BuildContext context) {
    if (item.type == ShopItemType.avatar) {
      final av = AvatarConstants.getById(item.id);
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: av.gradient,
          ),
        ),
        child: Center(
          child: Icon(av.icon, color: av.iconColor, size: size * 0.44),
        ),
      );
    }

    if (item.type == ShopItemType.border) {
      final bd = BorderConstants.getById(item.id);
      if (bd.id == 'border_none') {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF252A3D),
          ),
          child: const Center(
            child: Icon(Icons.block_rounded,
                color: Color(0xFF848A94), size: 20),
          ),
        );
      }
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: bd.gradient != null
              ? SweepGradient(colors: bd.gradient!)
              : null,
          color: bd.gradient == null ? bd.color : null,
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            color: Color(0xFF191D30),
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    // badge
    final bg = BadgeConstants.getById(item.id);
    if (bg.id == 'badge_none') {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF252A3D),
        ),
        child: const Center(
          child: Icon(Icons.remove_rounded,
              color: Color(0xFF848A94), size: 20),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg.color.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Icon(bg.icon, color: bg.color, size: size * 0.48),
      ),
    );
  }
}


