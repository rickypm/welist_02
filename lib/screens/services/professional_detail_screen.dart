import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../models/professional_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/professional/unlock_dialog.dart';
import '../subscription/subscription_screen.dart';
import '../messages/chat_screen.dart';

class ProfessionalDetailScreen extends StatefulWidget {
  final ProfessionalModel professional;

  const ProfessionalDetailScreen({
    super.key,
    required this.professional,
  });

  @override
  State<ProfessionalDetailScreen> createState() =>
      _ProfessionalDetailScreenState();
}

class _ProfessionalDetailScreenState extends State<ProfessionalDetailScreen> {
  bool _isUnlocking = false;
  bool _isContactUnlocked = false; // FIXED: State variable for unlock status

  @override
  void initState() {
    super.initState();
    _trackView();
    _checkUnlockStatus(); // Check status on init
  }

  Future<void> _checkUnlockStatus() async {
    final dataProvider = context.read<DataProvider>();
    final isUnlocked = await dataProvider.isProfessionalUnlocked(widget.professional.id);
    if (mounted) {
      setState(() => _isContactUnlocked = isUnlocked);
    }
  }

  Future<void> _trackView() async {
    // Track profile view analytics
  }

  Future<void> _handleUnlock() async {
    final authProvider = context.read<AuthProvider>();
    final dataProvider = context.read<DataProvider>();

    if (authProvider.user == null) return;

    final result = await UnlockDialog.show(
      context,
      professionalName: widget.professional.displayName,
      unlocksRemaining: authProvider.user!.unlocksRemaining,
      onUnlock: () async {
        final success = await dataProvider.unlockProfessional(
          authProvider.user!.id,
          widget.professional.id,
        );

        if (success) {
          await authProvider.refreshUser();
          setState(() => _isContactUnlocked = true); // Update state immediately
        }

        return success;
      },
      onUpgrade: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact unlocked successfully! '),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _startConversation() async {
    final authProvider = context.read<AuthProvider>();
    final dataProvider = context.read<DataProvider>();

    if (authProvider.user == null) return;

    final conversation = await dataProvider.getOrCreateConversation(
      authProvider.user!.id,
      widget.professional.id,
    );

    if (conversation != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversation: conversation,
            isPartnerView: false,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // final dataProvider = context.watch<DataProvider>(); // Not needed in build anymore
    final authProvider = context.watch<AuthProvider>();
    final professional = widget.professional;
    // Removed sync call to async function

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor:  AppColors.background,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:  AppColors.background.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.arrow_left, color: AppColors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient:  LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.3),
                      AppColors.background,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      AvatarWidget(
                        imageUrl: professional.avatarUrl,
                        name: professional.displayName,
                        size: 100,
                        isVerified: professional.isVerified,
                        showBorder: true,
                        borderColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child:  Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Verified Badge
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isContactUnlocked // FIXED: Use state variable
                                  ? professional.displayName
                                  :  professional.visibleName,
                              style: AppTextStyles.h2,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              professional.profession,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (professional. isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax. verify5,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight. w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stats Row
                  Row(
                    children: [
                      _buildStatChip(Iconsax.location, professional.city),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        Iconsax.briefcase,
                        professional.experienceDisplay,
                      ),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        Iconsax.user,
                        professional.isGroup ? 'Team' : 'Individual',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  if (professional.description != null &&
                      professional.description!.isNotEmpty) ...[
                    Text('About', style: AppTextStyles.h3),
                    const SizedBox(height: 12),
                    Text(
                      professional. description!,
                      style:  TextStyle(
                        color:  AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Services
                  if (professional.services.isNotEmpty) ...[
                    Text('Services', style:  AppTextStyles.h3),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: professional. services.map((service) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.surfaceLight),
                          ),
                          child: Text(
                            service,
                            style:  const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Unlock Info (if not unlocked)
                  if (!_isContactUnlocked) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Iconsax.lock, color: AppColors.warning),
                          const SizedBox(width:  12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Contact details are locked',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warning,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Unlock to see full name, phone, and start a conversation',
                                  style:  TextStyle(
                                    fontSize: 12,
                                    color: AppColors.warning.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Iconsax.unlock,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width:  8),
                        Text(
                          'You have ${authProvider.user?.unlocksRemaining ??  0} unlocks remaining',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Contact Details (if unlocked)
                  if (_isContactUnlocked) ...[
                    Text('Contact Details', style: AppTextStyles.h3),
                    const SizedBox(height: 12),
                    _buildContactTile(
                      icon:  Iconsax.user,
                      label: 'Full Name',
                      value: professional.displayName,
                    ),
                    if (professional.phone != null)
                      _buildContactTile(
                        icon: Iconsax.call,
                        label: 'Phone',
                        value: professional.phone! ,
                        isPhone: true,
                      ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color:  AppColors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: _isContactUnlocked // FIXED: Removed syntax error '? ?'
                ? ElevatedButton.icon(
                    onPressed:  _startConversation,
                    icon: const Icon(Iconsax.message),
                    label: const Text('Start Conversation'),
                    style:  ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _isUnlocking ? null : _handleUnlock,
                    icon:  _isUnlocking
                        ? const SizedBox(
                            width:  20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Iconsax.unlock),
                    label: Text(_isUnlocking ? 'Unlocking...' : 'Unlock Contact'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets. symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String label,
    required String value,
    bool isPhone = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child:  Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isPhone)
            IconButton(
              onPressed: () {
                // Launch phone dialer
              },
              icon: Icon(
                Iconsax.call,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}