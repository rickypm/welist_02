import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/subscription/subscription_screen.dart';
import '../../screens/referral/referral_screen.dart';

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;
    final user = authProvider.user;

    return Drawer(
      backgroundColor: AppColors.surface,
      width: MediaQuery.of(context).size.width * 0.8,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Close button row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppConfig.appName,
                        style: AppTextStyles.logoSmall,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Iconsax.close_square,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // User Info or Sign In Prompt
                  if (isLoggedIn) ...[
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppColors.inputBorderGradient,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: user?.avatarUrl != null
                              ?  Image.network(
                                  user! .avatarUrl!,
                                  fit: BoxFit.cover,
                                  width: 74,
                                  height: 74,
                                  errorBuilder: (_, __, ___) =>
                                      _buildAvatarPlaceholder(user. name),
                                )
                              : _buildAvatarPlaceholder(user?.name ??  'U'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    Text(
                      user?.name ?? 'User',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 4),

                    // Email
                    Text(
                      user?.email ?? '',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 12),

                    // Plan badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize:  MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.crown,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user?.displayPlan ?? 'FREE',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Guest Mode - Sign In Prompt
                    Container(
                      padding: const EdgeInsets. all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.inputBorderGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Iconsax.user,
                            color: AppColors.white,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Welcome, Guest!',
                            style:  TextStyle(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sign in to unlock all features',
                            style:  TextStyle(
                              color: AppColors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width:  double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator. push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()),
                                );
                              },
                              style: ElevatedButton. styleFrom(
                                backgroundColor:  AppColors.white,
                                foregroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(color: AppColors.surfaceLight, height: 1),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Profile (requires auth)
                  if (isLoggedIn)
                    _MenuItem(
                      icon: Iconsax.user,
                      title: 'Profile',
                      subtitle: 'View and edit your profile',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator. push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileScreen()),
                        );
                      },
                    ),

                  // Subscription (requires auth)
                  if (isLoggedIn)
                    _MenuItem(
                      icon: Iconsax.crown,
                      title: 'Subscription',
                      subtitle:  '${user?.unlocksRemaining ??  0} unlocks remaining',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SubscriptionScreen()),
                        );
                      },
                    ),

                  // Referrals & Rewards (requires auth)
                  if (isLoggedIn)
                    _MenuItem(
                      icon: Iconsax. gift,
                      title: 'Referrals & Rewards',
                      subtitle:  'Invite friends, earn unlocks',
                      showBadge: true,
                      badgeText: 'NEW',
                      onTap:  () {
                        Navigator.pop(context);
                        Navigator. push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ReferralScreen()),
                        );
                      },
                    ),

                  // Settings (available for all)
                  _MenuItem(
                    icon: Iconsax. setting_2,
                    title: 'Settings',
                    subtitle:  'App preferences',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets. symmetric(horizontal: 16, vertical: 8),
                    child: Divider(color:  AppColors.surfaceLight),
                  ),

                  _MenuItem(
                    icon:  Iconsax.info_circle,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Help & Support - Coming soon')),
                      );
                    },
                  ),
                  _MenuItem(
                    icon:  Iconsax. document,
                    title: 'Terms & Privacy',
                    onTap:  () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Terms & Privacy - Coming soon')),
                      );
                    },
                  ),
                  _MenuItem(
                    icon: Iconsax.star,
                    title: 'Rate the App',
                    onTap: () {
                      Navigator. pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Rate the App - Coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const Divider(color:  AppColors.surfaceLight, height: 1),

            // Sign In / Sign Out
            if (isLoggedIn)
              _MenuItem(
                icon:  Iconsax.logout,
                title: 'Sign Out',
                isDestructive: true,
                onTap: () async {
                  Navigator.pop(context);

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text('Sign Out? '),
                      content: 
                          const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Sign Out',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    final dataProvider = context.read<DataProvider>();
                    await authProvider.signOut();
                    dataProvider.clearChat();
                  }
                },
              )
            else
              _MenuItem(
                icon:  Iconsax.login,
                title: 'Sign In',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),

            // Version
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Version ${AppConfig.appVersion}',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Container(
      width: 74,
      height: 74,
      color: AppColors.surfaceLight,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String?  subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool showBadge;
  final String?  badgeText;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
    this.showBadge = false,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height:  40,
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.error.withValues(alpha: 0.1)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppColors.error : AppColors.textSecondary,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDestructive ? AppColors.error : AppColors.textPrimary,
              fontWeight:  FontWeight.w500,
            ),
          ),
          if (showBadge && badgeText != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(4),
              ),
              child:  Text(
                badgeText! ,
                style: const TextStyle(
                  color:  AppColors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style:  TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            )
          : null,
      trailing:  Icon(
        Iconsax.arrow_right_3,
        size: 18,
        color: isDestructive
            ? AppColors.error.withValues(alpha: 0.5)
            : AppColors.textMuted,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}