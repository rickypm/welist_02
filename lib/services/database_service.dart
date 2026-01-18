import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/category_model.dart';
import '../models/professional_model.dart';
import '../models/shop_model.dart';
import '../models/item_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // USERS
  // ============================================================

  Future<UserModel?> getUser(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting user:  $e');
      return null;
    }
  }

  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _supabase. from('users').update(data).eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('display_order');
      
      return (response as List)
          .map((e) => CategoryModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return [];
    }
  }

  // ============================================================
  // PROFESSIONALS
  // ============================================================

  Future<List<ProfessionalModel>> getProfessionalsByCategory(String categoryId) async {
    try {
      final response = await _supabase
          .from('professionals')
          .select()
          .eq('category_id', categoryId)
          .eq('is_available', true);
      
      return (response as List)
          .map((e) => ProfessionalModel. fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error getting professionals: $e');
      return [];
    }
  }

  Future<ProfessionalModel?> getProfessionalByUserId(String userId) async {
    try {
      final response = await _supabase
          .from('professionals')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response == null) return null;
      return ProfessionalModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting professional: $e');
      return null;
    }
  }

  // FIXED: Missing method added
  Future<ProfessionalModel?> getProfessionalById(String id) async {
    try {
      final response = await _supabase
          .from('professionals')
          .select()
          .eq('id', id)
          .maybeSingle();
      
      if (response == null) return null;
      return ProfessionalModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting professional by id: $e');
      return null;
    }
  }

  // FIXED: Missing method added
  Future<bool> updateProfessional(String professionalId, Map<String, dynamic> data) async {
    try {
      await _supabase.from('professionals').update(data).eq('id', professionalId);
      return true;
    } catch (e) {
      debugPrint('Error updating professional:  $e');
      return false;
    }
  }

  // FIXED: Missing method added
  Future<void> incrementProfileViews(String professionalId) async {
    try {
      await _supabase.rpc('increment_profile_views', params:  {'prof_id': professionalId});
    } catch (e) {
      debugPrint('Error incrementing views: $e');
    }
  }

  Future<List<ProfessionalModel>> searchProfessionals(String query, {String? city}) async {
    try {
      var dbQuery = _supabase
          . from('professionals')
          .select()
          .textSearch('search_vector', query);
          
      if (city != null) {
        dbQuery = dbQuery.eq('city', city);
      }
      
      final response = await dbQuery;
      return (response as List).map((e) => ProfessionalModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error searching professionals: $e');
      return [];
    }
  }

  // ============================================================
  // UNLOCKS
  // ============================================================

  // FIXED: Missing method added
  Future<bool> checkUnlockStatus(String userId, String professionalId) async {
    try {
      final response = await _supabase
          .from('unlocks')
          .select()
          .eq('user_id', userId)
          .eq('professional_id', professionalId)
          .gt('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<List<ProfessionalModel>> getUnlockedProfessionals(String userId) async {
    try {
      final response = await _supabase
          .from('unlocks')
          .select('professional: professionals(*)')
          .eq('user_id', userId)
          .gt('expires_at', DateTime.now().toIso8601String());
      
      return (response as List)
          .map((e) => ProfessionalModel. fromJson(e['professional']))
          .toList();
    } catch (e) {
      debugPrint('Error getting unlocked professionals: $e');
      return [];
    }
  }

  Future<bool> unlockProfessional(String userId, String professionalId) async {
    try {
      final user = await getUser(userId);
      if (user == null || user.unlocksRemaining < 1) return false;

      await _supabase. from('unlocks').insert({
        'user_id': userId,
        'professional_id': professionalId,
        'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      });

      // Simple update instead of RPC for safety
      await _supabase. from('users').update({
        'unlocks_remaining': user.unlocksRemaining - 1
      }).eq('id', userId);
      
      return true;
    } catch (e) {
      debugPrint('Error unlocking:  $e');
      return false;
    }
  }

  // ============================================================
  // SHOPS & ITEMS
  // ============================================================

  Future<ShopModel? > getShopByProfessionalId(String professionalId) async {
    try {
      final response = await _supabase
          .from('shops')
          .select()
          .eq('professional_id', professionalId)
          .maybeSingle();
      
      if (response == null) return null;
      return ShopModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting shop: $e');
      return null;
    }
  }

  Future<List<ShopModel>> searchShops(String query, {String? city}) async {
    try {
      var dbQuery = _supabase. from('shops').select().ilike('name', '%$query%');
      if (city != null) dbQuery = dbQuery.eq('city', city);
      final response = await dbQuery;
      return (response as List).map((e) => ShopModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<ShopModel?> createShop(Map<String, dynamic> data) async {
    try {
      final response = await _supabase.from('shops').insert(data).select().single();
      return ShopModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating shop: $e');
      return null;
    }
  }

  Future<bool> updateShop(String shopId, Map<String, dynamic> data) async {
    try {
      await _supabase. from('shops').update(data).eq('id', shopId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<ItemModel>> getItemsByShop(String shopId) async {
    try {
      final response = await _supabase
          .from('items')
          .select()
          .eq('shop_id', shopId)
          .eq('is_active', true);
      return (response as List).map((e) => ItemModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<ItemModel>> searchItems(String query, {String? city}) async {
    try {
      final response = await _supabase
          .from('items')
          .select('*, shop:shops! inner(*)')
          .ilike('name', '%$query%');
      return (response as List).map((e) => ItemModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<ItemModel?> createItem(Map<String, dynamic> data) async {
    try {
      final response = await _supabase.from('items').insert(data).select().single();
      return ItemModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateItem(String itemId, Map<String, dynamic> data) async {
    try {
      await _supabase.from('items').update(data).eq('id', itemId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    try {
      await _supabase.from('items').delete().eq('id', itemId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getFeaturedItems({String? city}) async {
    try {
      final response = await _supabase
          .from('items')
          .select('*, shop:shops!inner(*)')
          .eq('is_featured', true)
          .limit(10);
      return response as List;
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // MESSAGING
  // ============================================================

  Future<List<ConversationModel>> getConversations(String userId, {bool isPartner = false}) async {
    try {
      final column = isPartner ? 'professional_id' : 'user_id';
      final response = await _supabase
          .from('conversations')
          .select('''
            *,
            user:users!user_id(*),
            professional:professionals!professional_id(*)
          ''')
          .eq(column, userId)
          .order('last_message_at', ascending: false);
      
      return (response as List).map((e) => ConversationModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error getting conversations: $e');
      return [];
    }
  }

  Future<ConversationModel?> getOrCreateConversation(String userId, String professionalId) async {
    try {
      final existing = await _supabase
          .from('conversations')
          .select()
          .eq('user_id', userId)
          .eq('professional_id', professionalId)
          .maybeSingle();
      
      if (existing != null) return ConversationModel.fromJson(existing);

      final newConv = await _supabase
          .from('conversations')
          .insert({
            'user_id': userId,
            'professional_id':  professionalId,
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
          
      return ConversationModel. fromJson(newConv);
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      return null;
    }
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);
      
      return (response as List).map((e) => MessageModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Stream<List<MessageModel>> subscribeToMessages(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((maps) => maps.map((e) => MessageModel.fromJson(e)).toList());
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderType,
    required String content,
  }) async {
    try {
      await _supabase. from('messages').insert({
        'conversation_id': conversationId,
        'sender_id':  senderId,
        'sender_type': senderType,
        'content': content,
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  // FIXED: Updated to match DataProvider call signature (2 parameters)
  // Marks all messages in conversation as read except those sent by odType
  Future<void> markMessagesAsRead(String conversationId, String odType) async {
    try {
      await _supabase
          . from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_type', odType);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // FIXED:  Renamed parameters to match DataProvider call
  Future<int> getUnreadNotificationCount({
    required String userId, 
    required String userType
  }) async {
    try {
      // Logic adjusted to count messages not notifications for simplicity based on errors
      // Real implementation would query notifications table
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false)
          .count();
      return response. count;
    } catch (e) {
      return 0;
    }
  }

  // ============================================================
  // STATS & SUBSCRIPTION
  // ============================================================

  Future<Map<String, dynamic>> getPartnerStats(String professionalId) async {
    try {
      final response = await _supabase. rpc('get_partner_stats', params: {'prof_id': professionalId});
      return response as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  // FIXED: Added missing parameters odId and odType
  Future<bool> createSubscription({
    required String odId, // ID of user or professional
    required String odType, // 'user' or 'professional'
    required String plan,
    required double amount,
    required String paymentId,
    String? orderId,
  }) async {
    try {
      await _supabase. from('subscriptions').insert({
        'user_id': odType == 'user' ? odId : null,
        'professional_id':  odType == 'professional' ?  odId : null,
        'plan': plan,
        'amount': amount,
        'payment_id': paymentId,
        'order_id': orderId,
        'status': 'active',
        'starts_at': DateTime.now().toIso8601String(),
        'ends_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Error creating subscription: $e');
      return false;
    }
  }
}