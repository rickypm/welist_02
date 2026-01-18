import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../screens/subscription/subscription_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  final bool isPartner;

  const ProfileScreen({
    super.key,
    this.isPartner = false,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors. background,
        leading: IconButton(
          icon:  const Icon(Iconsax.arrow_left, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Profile', style: AppTextStyles.h3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Container(
                width: 100,
                height: 100,
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
                            width: 94,
                            height: 94,
                            errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(user. name),
                          )
                        : _buildAvatarPlaceholder(user?. name ??  'U'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Name
            Text(
              user?.name ??  'User',
              style:  AppTextStyles.h2,
            ),
            const SizedBox(height: 8),

            // Email
            Text(
              user?.email ?? '',
              style: AppTextStyles. bodyMedium,
            ),
            const SizedBox(height:  8),

            // Plan badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.inputBorderGradient,
                borderRadius:  BorderRadius.circular(20),
              ),
              child:  Text(
                user?.displayPlan ?? 'FREE',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Account Section
            _buildSection(
              context,
              title: 'Account',
              items: [
                _ProfileItem(
                  icon:  Iconsax.user_edit,
                  title:  'Edit Profile',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  },
                ),
                _ProfileItem(
                  icon: Iconsax.lock,
                  title: 'Change Password',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Change password - Coming soon')),
                    );
                  },
                ),
                _ProfileItem(
                  icon:  Iconsax.location,
                  title: 'Location',
                  subtitle: user?.city ?? 'Not set',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Subscription Section
            _buildSection(
              context,
              title: 'Subscription',
              items: [
                _ProfileItem(
                  icon:  Iconsax.crown,
                  title: 'Current Plan',
                  subtitle: user?.displayPlan ?? 'Free',
                  onTap:  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SubscriptionScreen(isPartner: isPartner)),
                    );
                  },
                ),
                _ProfileItem(
                  icon: Iconsax.unlock,
                  title: 'Unlocks Remaining',
                  subtitle: '${user?.unlocksRemaining ?? 0}',
                  onTap:  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SubscriptionScreen(isPartner: isPartner)),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Support Section
            _buildSection(
              context,
              title: 'Support',
              items: [
                _ProfileItem(
                  icon: Iconsax. info_circle,
                  title:  'Help & Support',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help & Support - Coming soon')),
                    );
                  },
                ),
                _ProfileItem(
                  icon: Iconsax. document,
                  title: 'Terms & Privacy',
                  onTap:  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Terms & Privacy - Coming soon')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Container(
      width: 94,
      height: 94,
      color: AppColors.surfaceLight,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: AppColors. white,
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_ProfileItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height:  12),
        Container(
          decoration: BoxDecoration(
            color: AppColors. surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry. key;
              final item = entry.value;
              final isLast = index == items. length - 1;

              return Column(
                children: [
                  ListTile(
                    leading:  Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary. withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.icon,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle:  item.subtitle != null
                        ?  Text(
                            item.subtitle!,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    trailing: const Icon(
                      Iconsax.arrow_right_3,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    onTap: item.onTap,
                  ),
                  if (! isLast)
                    const Divider(
                      color: AppColors.surfaceLight,
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ProfileItem {
  final IconData icon;
  final String title;
  final String?  subtitle;
  final VoidCallback onTap;

  _ProfileItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}