import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/avatar_constants.dart';
import '../../../data/models/shop_item_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/shop_provider.dart';
import '../../widgets/avatar_widget.dart';
import '../shop/shop_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  bool _loading = false;
  bool _nameChanged = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _nameCtrl.addListener(() {
      final changed = _nameCtrl.text.trim() != widget.user.name;
      if (changed != _nameChanged) {
        setState(() => _nameChanged = changed);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ShopProvider>().loadShop(widget.user);
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || name == widget.user.name) return;
    if (name.length < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Name must be at least 2 characters',
            style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final currentUser = auth.user ?? widget.user;
      final updated = currentUser.copyWith(name: name);
      await UserRepository().upsert(updated);
      if (!mounted) return;
      auth.refresh(updated);
      setState(() => _nameChanged = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Name updated!',
            style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _equip(ShopItemModel item) async {
    final shop = context.read<ShopProvider>();
    final auth = context.read<AuthProvider>();
    final currentUser = auth.user ?? widget.user;
    final updated = await shop.equipItem(item, currentUser);
    if (updated != null && mounted) {
      auth.refresh(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final shop = context.watch<ShopProvider>();
    final user = auth.user ?? widget.user;

    final ownedAvatars =
        shop.avatars.where((a) => shop.isOwned(a.id)).toList();
    final ownedBorders =
        shop.borders.where((b) => shop.isOwned(b.id)).toList();
    final ownedBadges =
        shop.badges.where((b) => shop.isOwned(b.id)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C16),
      body: SafeArea(
        child: Column(children: [
          const SizedBox(height: 16),

          // ── Top bar ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                child: Text(
                  'Edit Profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: (_nameChanged && !_loading) ? _saveName : null,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _nameChanged ? 1.0 : 0.3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3580FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Save',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            )),
                  ),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // ── Scrollable content ────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar preview
                  Center(
                    child: AvatarWidget(
                      avatarId: user.equippedAvatarId,
                      borderId: user.equippedBorderId,
                      badgeId: user.equippedBadgeId,
                      size: 90,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Coins balance
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFFFD700)
                                .withValues(alpha: 0.3)),
                      ),
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on_rounded,
                                color: Color(0xFFFFD700), size: 16),
                            const SizedBox(width: 6),
                            Text('${user.coins} Coins',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFFD700),
                                )),
                          ]),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Display name ───────────────────────────────
                  _sectionLabel('Display Name'),
                  const SizedBox(height: 8),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0C16),
                      border: Border.all(
                        color: _nameChanged
                            ? const Color(0xFF3580FF)
                            : const Color(0xFF191D30),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _nameCtrl,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Your display name',
                        hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          color: Color(0xFF848A94),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 18, vertical: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'This name is shown to your team members',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF545A64),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Avatar selector ────────────────────────────
                  Row(children: [
                    _sectionLabel('Avatar'),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ShopScreen(user: user))),
                      child: const Text(
                        'Browse Shop →',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xFF3580FF),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: shop.loading
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Color(0xFF3580FF),
                                  strokeWidth: 2),
                            ))
                        : ownedAvatars.isEmpty
                            ? const Center(
                                child: Text('No avatars yet',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      color: Color(0xFF848A94),
                                    )))
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: ownedAvatars.length,
                                itemBuilder: (_, i) {
                                  final av = ownedAvatars[i];
                                  final selected =
                                      user.equippedAvatarId == av.id;
                                  final avData =
                                      AvatarConstants.getById(av.id);
                                  return GestureDetector(
                                    onTap: () => _equip(av),
                                    child: _avatarSelectorCard(
                                      avData: avData,
                                      label: av.name,
                                      isSelected: selected,
                                    ),
                                  );
                                },
                              ),
                  ),

                  const SizedBox(height: 20),

                  // ── Border selector ────────────────────────────
                  _sectionLabel('Profile Border'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ownedBorders.isEmpty
                        ? const Center(
                            child: Text('No borders yet',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: Color(0xFF848A94),
                                )))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: ownedBorders.length,
                            itemBuilder: (_, i) {
                              final br = ownedBorders[i];
                              final selected =
                                  user.equippedBorderId == br.id;
                              final bdData =
                                  BorderConstants.getById(br.id);
                              final col = bdData.color == Colors.transparent
                                  ? const Color(0xFF848A94)
                                  : bdData.color;
                              return GestureDetector(
                                onTap: () => _equip(br),
                                child: Container(
                                  width: 70,
                                  margin: const EdgeInsets.only(
                                      right: 10),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? col.withValues(alpha: 0.12)
                                        : const Color(0xFF191D30),
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    border: Border.all(
                                      color: selected
                                          ? col
                                          : const Color(0xFF191D30),
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: bdData.gradient != null
                                              ? SweepGradient(
                                                  colors:
                                                      bdData.gradient!)
                                              : null,
                                          border: bdData.gradient == null
                                              ? Border.all(
                                                  color: col, width: 3)
                                              : null,
                                        ),
                                        child: bdData.gradient != null
                                            ? Container(
                                                margin:
                                                    const EdgeInsets.all(
                                                        3),
                                                decoration:
                                                    const BoxDecoration(
                                                  color: Color(0xFF191D30),
                                                  shape: BoxShape.circle,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        br.name,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 8,
                                          color: selected
                                              ? Colors.white
                                              : const Color(
                                                  0xFF848A94),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 20),

                  // ── Badge selector ─────────────────────────────
                  _sectionLabel('Badge'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ownedBadges.isEmpty
                        ? const Center(
                            child: Text('No badges yet',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: Color(0xFF848A94),
                                )))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: ownedBadges.length,
                            itemBuilder: (_, i) {
                              final bg = ownedBadges[i];
                              final selected =
                                  user.equippedBadgeId == bg.id;
                              final bgData =
                                  BadgeConstants.getById(bg.id);
                              return GestureDetector(
                                onTap: () => _equip(bg),
                                child: _badgeSelectorCard(
                                  bgData: bgData,
                                  label: bg.name,
                                  isSelected: selected,
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Avatar selector card ─────────────────────────────────────
  Widget _avatarSelectorCard({
    required AvatarData avData,
    required String label,
    required bool isSelected,
  }) {
    const selectedColor = Color(0xFFFFD700);
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? selectedColor.withValues(alpha: 0.1)
            : const Color(0xFF191D30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? selectedColor : const Color(0xFF191D30),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: avData.gradient,
              ),
            ),
            child: Center(
              child: Icon(avData.icon,
                  color: avData.iconColor, size: 18),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 8,
              color: isSelected ? selectedColor : const Color(0xFF848A94),
            ),
          ),
        ],
      ),
    );
  }

  // ── Badge selector card ───────────────────────────────────────
  Widget _badgeSelectorCard({
    required BadgeData bgData,
    required String label,
    required bool isSelected,
  }) {
    const selectedColor = Color(0xFF3580FF);
    final iconColor = bgData.color == Colors.transparent
        ? const Color(0xFF848A94)
        : bgData.color;
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? selectedColor.withValues(alpha: 0.1)
            : const Color(0xFF191D30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? selectedColor : const Color(0xFF191D30),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Icon(bgData.icon, color: iconColor, size: 18),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 8,
              color: isSelected ? selectedColor : const Color(0xFF848A94),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF848A94),
          letterSpacing: 1.1,
        ),
      );
}
