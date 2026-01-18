import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/empty_state.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final authProvider = context.read<AuthProvider>();
    final dataProvider = context.read<DataProvider>();

    if (authProvider.user != null) {
      await dataProvider.loadConversations(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon:  const Icon(Iconsax. arrow_left, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Messages',
          style: AppTextStyles.h3,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        color: AppColors.primary,
        child: dataProvider.conversationsLoading
            ? const Center(child: CircularProgressIndicator())
            : dataProvider.conversations.isEmpty
                ? const EmptyState(
                    icon: Iconsax.message,
                    title: 'No messages yet',
                    subtitle: 'Start a conversation by contacting a service provider',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: dataProvider.conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = dataProvider.conversations[index];
                      return _buildConversationTile(conversation);
                    },
                  ),
      ),
    );
  }

  Widget _buildConversationTile(dynamic conversation) {
    final hasUnread = conversation.userUnreadCount > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical:  8),
      leading: AvatarWidget(
        imageUrl: conversation.professionalAvatarUrl,
        name: conversation.professionalName,
        size: 52,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.professionalName ??  'Unknown',
              style:  TextStyle(
                fontWeight: hasUnread ? FontWeight.bold :  FontWeight.w500,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            conversation.timeAgo,
            style: TextStyle(
              fontSize: 12,
              color: hasUnread ? AppColors.primary :  AppColors.textMuted,
              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conversation.lastMessagePreview ?? 'No messages yet',
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
                shape: BoxShape.circle,
              ),
              child: Text(
                conversation.userUnreadCount > 9
                    ? '9+'
                    : conversation.userUnreadCount.toString(),
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
              isPartnerView: false,
            ),
          ),
        );
      },
    );
  }
}