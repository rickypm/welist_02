import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import 'partner_home_screen.dart';
import 'partner_shop_screen.dart';
import 'partner_inbox_screen.dart';
import '../profile/profile_screen.dart';

class PartnerMainScreen extends StatefulWidget {
  const PartnerMainScreen({super.key});

  @override
  State<PartnerMainScreen> createState() => _PartnerMainScreenState();
}

class _PartnerMainScreenState extends State<PartnerMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PartnerHomeScreen(),
    const PartnerShopScreen(),
    const PartnerInboxScreen(),
    const ProfileScreen(isPartner: true),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final authProvider = context.read<AuthProvider>();
    final dataProvider = context.read<DataProvider>();

    if (authProvider.user != null) {
      await dataProvider.loadProfessionalByUserId(authProvider.user! .id);
      
      if (dataProvider.selectedProfessional != null) {
        await dataProvider.loadPartnerShop(dataProvider.selectedProfessional!.id);
        await dataProvider.loadPartnerStats(authProvider.user!.id);
        await dataProvider.loadConversations(authProvider.user! .id, isPartner: true);
        
        if (dataProvider.shop != null) {
          await dataProvider.loadShopItems(dataProvider.shop!.id);
        }
      }
      
      await dataProvider.loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child:  Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Iconsax.home,
                  activeIcon: Iconsax.home_15,
                  label: 'Dashboard',
                ),
                _buildNavItem(
                  index:  1,
                  icon:  Iconsax.shop,
                  activeIcon: Iconsax.shop,
                  label: 'My Shop',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Iconsax.message,
                  activeIcon:  Iconsax.message,
                  label: 'Inbox',
                  showBadge: _getUnreadCount() > 0,
                  badgeCount: _getUnreadCount(),
                ),
                _buildNavItem(
                  index: 3,
                  icon: Iconsax.user,
                  activeIcon: Iconsax. user,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getUnreadCount() {
    final dataProvider = context.watch<DataProvider>();
    int count = 0;
    for (final conv in dataProvider.conversations) {
      count += conv.professionalUnreadCount;
    }
    return count;
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior. opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                  size: 24,
                ),
                if (showBadge && badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color:  AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints:  const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight. w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}