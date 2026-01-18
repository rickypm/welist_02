import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../models/professional_model.dart';
import '../../models/shop_model.dart';
import '../../services/ai_service.dart';

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final Function(ProfessionalModel)? onProfessionalTap;
  final Function(ShopModel)? onShopTap;
  final List<ProfessionalModel>? professionals;
  final List<ShopModel>? shops;
  final bool isLoading;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.onProfessionalTap,
    this.onShopTap,
    this. professionals,
    this.shops,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _buildUserMessage();
    } else {
      return _buildAssistantMessage(context);
    }
  }

  Widget _buildUserMessage() {
    return Align(
      alignment:  Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:  Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.content,
          style: AppTextStyles.chatUser,
        ),
      ),
    );
  }

  Widget _buildAssistantMessage(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Response text
          _buildFormattedContent(message.content),

          // Professional Results
          if (professionals != null && professionals!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...professionals!.take(3).map((professional) {
              return _buildProfessionalCard(context, professional);
            }),
          ],

          // Shop Results
          if (shops != null && shops!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...shops!.take(3).map((shop) {
              return _buildShopCard(context, shop);
            }),
          ],

          // No results message
          if (professionals?. isEmpty == true &&
              shops?.isEmpty == true &&
              ! isLoading) ...[
            const SizedBox(height: 8),
            Text(
              'Browse categories for more options.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormattedContent(String content) {
    final lines = content.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.trim().startsWith('•') || line.trim().startsWith('-')) {
          return _buildBulletPoint(line);
        }
        if (line.trim().isEmpty) {
          return const SizedBox(height: 8);
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildRichText(line),
        );
      }).toList(),
    );
  }

  Widget _buildBulletPoint(String line) {
    final String text = line.replaceFirst(RegExp(r'^[\s]*[•\-]\s*'), '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child:  _buildRichText(text),
          ),
        ],
      ),
    );
  }

  Widget _buildRichText(String text) {
    final List<InlineSpan> spans = [];
    final RegExp boldRegex = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;

    for (final match in boldRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: AppTextStyles.chatAssistant,
        ));
      }

      spans.add(TextSpan(
        text: match.group(1),
        style: AppTextStyles.chatAssistant. copyWith(
          fontWeight: FontWeight.w700,
        ),
      ));

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text. substring(lastEnd),
        style: AppTextStyles.chatAssistant,
      ));
    }

    if (spans.isEmpty) {
      return Text(text, style: AppTextStyles.chatAssistant);
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildProfessionalCard(BuildContext context, ProfessionalModel professional) {
    return GestureDetector(
      onTap: () => onProfessionalTap?. call(professional),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors. surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius:  BorderRadius.circular(10),
              ),
              child:  professional.avatarUrl != null
                  ?  ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image. network(
                        professional.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(professional.displayName),
                      ),
                    )
                  : _buildAvatarPlaceholder(professional.displayName),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          professional.visibleName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (professional.isVerified)
                        Icon(
                          Iconsax.verify5,
                          size: 14,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    professional.profession,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Iconsax.location, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        professional.city,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Iconsax.arrow_right_3,
              size: 18,
              color: AppColors. textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopCard(BuildContext context, ShopModel shop) {
    return GestureDetector(
      onTap: () => onShopTap?.call(shop),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border. all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children:  [
            // Logo
            Container(
              width:  48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child:  shop.logoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image. network(
                        shop.logoUrl!,
                        fit:  BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Iconsax.shop,
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  :  Icon(
                      Iconsax.shop,
                      color: AppColors.textMuted,
                    ),
            ),
            const SizedBox(width:  12),

            // Info
            Expanded(
              child:  Column(
                crossAxisAlignment:  CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shop. name,
                          style: const TextStyle(
                            fontWeight:  FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize:  14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (shop.isVerified)
                        Icon(
                          Iconsax.verify5,
                          size: 14,
                          color: AppColors. primary,
                        ),
                    ],
                  ),
                  const SizedBox(height:  4),
                  Row(
                    children: [
                      Icon(Iconsax.location, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          shop.fullAddress,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                          maxLines:  1,
                          overflow:  TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Iconsax. arrow_right_3,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Center(
      child: Text(
        name. isNotEmpty ? name[0].toUpperCase() : 'P',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors. textMuted,
        ),
      ),
    );
  }
}