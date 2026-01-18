import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

/// AI Service that calls Supabase Edge Function
/// - OpenAI API key is stored on server, NOT in client app
/// - Handles usage limits for free users
class AIService {
  final _supabase = Supabase.instance.client;

  // ============================================================
  // SEND MESSAGE TO AI (via Edge Function)
  // ============================================================
  
  /// Send a message to AI chat via secure Edge Function
  /// Returns AIResponse with limit information
  Future<AIResponse> sendMessage({
    required String message,
    String? city,
    List<ChatMessage>? history,
    bool skipAI = false,
  }) async {
    try {
      final session = _supabase.auth.currentSession;
      final userId = session?.user. id;
      final userCity = city ?? AppConfig.defaultCity;

      // Build request body
      final body = {
        'message': message,
        'city': userCity,
        'userId': userId,
        'skipAI': skipAI,
        if (history != null && history.isNotEmpty)
          'history': history.map((m) => m.toJson()).toList(),
      };

      // Call Edge Function
      final response = await http.post(
        Uri.parse(AppConfig.aiChatEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          if (session?.accessToken != null)
            'Authorization': 'Bearer ${session! .accessToken}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          return AIResponse(
            success: true,
            message: data['message'] ??  '',
            searchIntent: data['searchIntent'] != null
                ? SearchIntent.fromJson(data['searchIntent'])
                : null,
            matchedProfessionals: data['matchedProfessionals'] != null
                ? List<String>.from(data['matchedProfessionals'])
                : null,
            limitReached: data['limitReached'] ?? false,
            remaining: data['remaining'] ?? -1,
            isPaid: data['isPaid'] ?? false,
          );
        } else {
          return AIResponse(
            success: false,
            message: '',
            error: data['error'] ?? 'AI service error',
          );
        }
      } else {
        debugPrint('AI Service HTTP Error: ${response.statusCode}');
        return AIResponse(
          success: false,
          message: '',
          error: 'Server error:  ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('AI Service Exception: $e');
      return AIResponse(
        success: false,
        message: '',
        error: 'Connection error: ${e.toString()}',
      );
    }
  }

  // ============================================================
  // CHECK AI USAGE (Without making a request)
  // ============================================================
  
  /// Check user's AI usage without consuming a request
  Future<AIUsageStatus> checkUsageStatus() async {
    try {
      final userId = _supabase.auth. currentUser?.id;
      if (userId == null) {
        return AIUsageStatus(
          canUse: true,
          remaining: AppConfig.freeUserAIDailyLimit,
          limit: AppConfig.freeUserAIDailyLimit,
          isPaid: false,
        );
      }

      final response = await _supabase
          .rpc('check_ai_usage_limit', params: {
            'p_user_id': userId,
            'p_daily_limit': AppConfig.freeUserAIDailyLimit,
          });

      if (response != null) {
        return AIUsageStatus(
          canUse: response['canUse'] ?? true,
          remaining: response['remaining'] ?? 0,
          limit: response['limit'] ?? AppConfig.freeUserAIDailyLimit,
          isPaid:  response['isPaid'] ?? false,
          error: response['error'],
        );
      }

      return AIUsageStatus(
        canUse: true,
        remaining: AppConfig. freeUserAIDailyLimit,
        limit: AppConfig. freeUserAIDailyLimit,
        isPaid: false,
      );
    } catch (e) {
      debugPrint('Check Usage Status Error: $e');
      return AIUsageStatus(
        canUse: true,
        remaining: AppConfig. freeUserAIDailyLimit,
        limit: AppConfig. freeUserAIDailyLimit,
        isPaid: false,
      );
    }
  }

  // ============================================================
  // GET USAGE STATS
  // ============================================================
  
  /// Get detailed AI usage statistics
  Future<AIUsageStats? > getUsageStats() async {
    try {
      final userId = _supabase.auth. currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .rpc('get_ai_usage_stats', params: {'p_user_id': userId});

      if (response != null) {
        return AIUsageStats(
          today: response['today'] ?? 0,
          thisWeek: response['thisWeek'] ?? 0,
          thisMonth: response['thisMonth'] ??  0,
          total: response['total'] ?? 0,
        );
      }

      return null;
    } catch (e) {
      debugPrint('Get Usage Stats Error: $e');
      return null;
    }
  }

  // ============================================================
  // LOCAL FALLBACK (No API call)
  // ============================================================
  
  /// Fallback intent extraction using keyword matching
  SearchIntent? extractLocalIntent(String message) {
    final lowerMessage = message.toLowerCase();
    
    final categoryKeywords = {
      'electrician': ['electrician', 'electric', 'wiring', 'power', 'light', 'fan', 'switch'],
      'plumber': ['plumber', 'plumbing', 'pipe', 'water', 'tap', 'leak', 'drain', 'toilet'],
      'carpenter': ['carpenter', 'carpentry', 'furniture', 'wood', 'cabinet', 'door', 'table'],
      'painter': ['painter', 'painting', 'paint', 'wall', 'color', 'whitewash'],
      'ac-repair': ['ac', 'air conditioner', 'cooling', 'hvac', 'split ac', 'window ac'],
      'cleaning': ['cleaning', 'cleaner', 'housekeeping', 'maid', 'deep clean', 'sanitize'],
      'tutoring':  ['tutor', 'teacher', 'teaching', 'coaching', 'class', 'tuition', 'learn'],
      'beauty': ['beauty', 'salon', 'parlour', 'parlor', 'haircut', 'makeup', 'facial', 'spa'],
      'mechanic': ['mechanic', 'car', 'bike', 'vehicle', 'repair', 'garage', 'service'],
      'legal': ['lawyer', 'legal', 'advocate', 'law', 'court', 'attorney'],
      'medical': ['doctor', 'medical', 'clinic', 'health', 'hospital', 'physician'],
      'it-tech':  ['computer', 'laptop', 'it', 'tech', 'software', 'hardware', 'network'],
      'photography': ['photographer', 'photography', 'photo', 'video', 'wedding', 'shoot'],
      'catering': ['catering', 'caterer', 'food', 'cook', 'chef', 'party food'],
      'event-planning':  ['event', 'wedding', 'party', 'decoration', 'planner', 'organize'],
      'pest-control':  ['pest', 'cockroach', 'termite', 'insect', 'rat', 'mosquito'],
    };

    for (final entry in categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerMessage.contains(keyword)) {
          return SearchIntent(
            category:  entry.key,
            query: message,
            confidence: 0.8,
          );
        }
      }
    }

    return null;
  }

  // ============================================================
  // GENERATE RESPONSES
  // ============================================================
  
  /// Generate a helpful response when AI is unavailable
  String generateFallbackResponse(String message, SearchIntent? intent) {
    if (intent != null) {
      final categoryName = _formatCategoryName(intent.category ??  '');
      return "I found that you're looking for a $categoryName. Let me show you the available professionals in your area.";
    }
    
    return "I'm here to help you find local services. You can ask me things like:\n\n"
           "• \"I need an electrician\"\n"
           "• \"Find me a plumber nearby\"\n"
           "• \"Looking for a tutor for my child\"\n\n"
           "What service are you looking for? ";
  }

  /// Generate limit reached message
  String generateLimitReachedMessage(int limit) {
    return "🔒 You've reached your daily limit of $limit AI chat requests.\n\n"
           "Don't worry!  You can still:\n"
           "• Browse service categories below\n"
           "• Use simple keyword search\n"
           "• View professional profiles\n\n"
           "💡 **Upgrade to a paid plan for unlimited AI assistance! **";
  }

  String _formatCategoryName(String slug) {
    return slug
        .replaceAll('-', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1)}' 
            : '')
        .join(' ');
  }
}

// ============================================================
// MODELS
// ============================================================

class AIResponse {
  final bool success;
  final String message;
  final SearchIntent? searchIntent;
  final List<String>? matchedProfessionals;
  final String? error;
  final bool limitReached;
  final int remaining;  // -1 means unlimited
  final bool isPaid;

  AIResponse({
    required this.success,
    required this.message,
    this.searchIntent,
    this. matchedProfessionals,
    this.error,
    this.limitReached = false,
    this.remaining = -1,
    this.isPaid = false,
  });

  bool get hasSearchIntent => searchIntent != null && searchIntent!.category != null;
  bool get hasError => error != null && error!.isNotEmpty;
  bool get isUnlimited => remaining == -1;
}

class SearchIntent {
  final String?  category;
  final String? query;
  final double?  confidence;

  SearchIntent({
    this.category,
    this.query,
    this.confidence,
  });

  factory SearchIntent.fromJson(Map<String, dynamic> json) {
    return SearchIntent(
      category:  json['category'],
      query:  json['query'],
      confidence:  json['confidence']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'query': query,
      'confidence': confidence,
    };
  }
}

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'],
      content: json['content'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

class AIUsageStatus {
  final bool canUse;
  final int remaining;
  final int limit;
  final bool isPaid;
  final String?  error;

  AIUsageStatus({
    required this.canUse,
    required this.remaining,
    required this.limit,
    required this.isPaid,
    this.error,
  });

  bool get isUnlimited => remaining == -1 || isPaid;
  bool get isLimitReached => ! canUse && ! isPaid;
}

class AIUsageStats {
  final int today;
  final int thisWeek;
  final int thisMonth;
  final int total;

  AIUsageStats({
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.total,
  });
}