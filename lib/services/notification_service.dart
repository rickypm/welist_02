import 'package:flutter/foundation.dart';
// import 'package:firebase_messaging/firebase_messaging.dart'; // Uncomment when adding FCM
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  // final FirebaseMessaging _messaging = FirebaseMessaging.instance; // Uncomment when adding FCM

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Request permission
      // await _requestPermission();
      
      // Get FCM token
      // final token = await _messaging.getToken();
      // if (token != null) {
      //   await _saveFCMToken(token);
      // }
      
      // Listen for token refresh
      // _messaging.onTokenRefresh.listen(_saveFCMToken);
      
      debugPrint('Notification service initialized');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    try {
      // final settings = await _messaging.requestPermission(
      //   alert: true,
      //   badge: true,
      //   sound: true,
      // );
      // return settings.authorizationStatus == AuthorizationStatus.authorized;
      return true;
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      return false;
    }
  }

  /// Save FCM token to database
  Future<void> saveFCMToken(String token, String userId) async {
    try {
      await _supabase. from('user_devices').upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': defaultTargetPlatform. name,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, platform');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Send push notification (via Edge Function)
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase. functions.invoke(
        'send-notification',
        body: {
          'user_id': userId,
          'title':  title,
          'body': body,
          'data': data,
        },
      );
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// Send message notification
  Future<void> sendMessageNotification({
    required String recipientId,
    required String senderName,
    required String messagePreview,
    required String conversationId,
  }) async {
    await sendPushNotification(
      userId: recipientId,
      title: 'New message from $senderName',
      body:  messagePreview,
      data:  {
        'type': 'message',
        'conversation_id': conversationId,
      },
    );
  }

  /// Send unlock notification
  Future<void> sendUnlockNotification({
    required String professionalUserId,
    required String userName,
  }) async {
    await sendPushNotification(
      userId:  professionalUserId,
      title: 'New Contact Unlock',
      body: '$userName has unlocked your contact',
      data: {
        'type': 'unlock',
      },
    );
  }

  /// Create in-app notification
  Future<void> createInAppNotification({
    required String userId,
    required String title,
    required String message,
    String? actionType,
    String? actionId,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message':  message,
        'action_type': actionType,
        'action_id': actionId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error creating in-app notification: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);
      
      return (response as List).length;
    } catch (e) {
      debugPrint('Error getting unread count:  $e');
      return 0;
    }
  }

  /// Get notifications
  Future<List<Map<String, dynamic>>> getNotifications(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final data = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          . from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read':  true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  /// Delete old notifications
  Future<void> deleteOldNotifications(String userId, {int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now()
          .subtract(Duration(days: daysOld))
          .toIso8601String();

      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId)
          .lt('created_at', cutoffDate);
    } catch (e) {
      debugPrint('Error deleting old notifications: $e');
    }
  }
}