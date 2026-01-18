import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../messages/chat_screen.dart';

class PartnerInboxScreen extends StatefulWidget {
  const PartnerInboxScreen({super.key});

  @override
  State<PartnerInboxScreen> createState() => _PartnerInboxScreenState();
}

class _PartnerInboxScreenState extends State<PartnerInboxScreen> {
  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final authProvider = context.read<AuthProvider>();
    final dataProvider = context.read<DataProvider>();

    if (authProvider.user != null) {
      await dataProvider.loadConversations(authProvider.user!.id, isPartner: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final dataProvider = context.watch<DataProvider>();
    final professional = dataProvider.selectedProfessional;
    final canReadMessages = _canReadMessages(professional);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Inbox'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        color: AppColors.primary,
        child: ! canReadMessages
            ? _buildUpgradePrompt()
            : _buildBody(dataProvider),
      ),
    );
  }

  bool _canReadMessages(dynamic professional) {
    if (professional == null) return false;
    final plan = professional.subscriptionPlan;
    return plan == 'starter' || plan == 'business';
  }

  Widget _buildUpgradePrompt() {
    return Center(
      child:  Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width:  100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape. circle,
              ),
              child: const Icon(
                Iconsax.lock,
                size: 48,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Messages Locked',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height:  8),
            Text(
              'Upgrade to Starter or Business plan to read and reply to customer messages.',
              textAlign: TextAlign. center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton. icon(
              onPressed: () {
                Navigator.pushNamed(context, '/subscription');
              },
              icon:  const Icon(Iconsax. crown),
              label: const Text('Upgrade Now'),
              style:  ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(DataProvider dataProvider) {
    if (dataProvider.conversationsLoading) {
      return ListView. builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: ShimmerListTile(),
          );
        },
      );
    }

    if (dataProvider.conversations.isEmpty) {
      return EmptyState(
        icon:  Iconsax.message,
        title: 'No messages yet',
        subtitle: 'Customer inquiries will appear here',
      );
    }

    return ListView. builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: dataProvider.conversations.length,
      itemBuilder: (context, index) {
        final conversation = dataProvider.conversations[index];
        return _buildConversationTile(conversation);
      },
    );
  }

  Widget _buildConversationTile(dynamic conversation) {
    final hasUnread = conversation.professionalUnreadCount > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: AvatarWidget(
        imageUrl: conversation.userAvatarUrl,
        name: conversation.userName,
        size: 52,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.userName ??  'Customer',
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.bold :  FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            conversation.timeAgo,
            style: TextStyle(
              fontSize: 12,
              color: hasUnread ? AppColors.primary : AppColors.textMuted,
              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conversation.lastMessagePreview ??  'No messages yet',
              style: TextStyle(
                fontSize: 13,
                color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color:  AppColors.primary,
                shape: BoxShape. circle,
              ),
              child: Text(
                conversation.professionalUnreadCount > 9
                    ? '9+'
                    : conversation.professionalUnreadCount.toString(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversation: conversation,
              isPartnerView: true,
            ),
          ),
        ).then((_) => _loadConversations());
      },
    );
  }
}