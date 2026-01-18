class AppConfig {
  // ============================================================
  // SUPABASE (Safe - Protected by Row Level Security)
  // ============================================================
  
  static const String supabaseUrl = 'https://mdwuhyptlqsduvkosqvn.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_FqbICn1Q3EftxArGYpfHNg_wwF_C3b5'; // Replace with your key
  
  // ============================================================
  // RAZORPAY PUBLIC KEY (Safe - Public key only)
  // ============================================================
  
  static const String razorpayKeyId = 'rzp_test_S4wy5BwyMS57ji'; // Replace with your key
  
  // ============================================================
  // EDGE FUNCTION ENDPOINTS
  // ============================================================
  
  static String get aiChatEndpoint => '$supabaseUrl/functions/v1/ai-chat';
  static String get verifyPaymentEndpoint => '$supabaseUrl/functions/v1/verify-payment';
  static String get createOrderEndpoint => '$supabaseUrl/functions/v1/create-order';
  
  // ============================================================
  // APP INFO
  // ============================================================
  
  static const String appName = 'welist';
  static const String appDisplayName = 'WeList';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String appTagline = 'Find local services with AI';
  
  // ============================================================
  // DEFAULT SETTINGS
  // ============================================================
  
  static const String defaultCity = 'Shillong';
  static const String defaultCurrency = 'INR';
  static const String currencySymbol = '₹';
  static const String defaultLanguage = 'en';
  
  // Main tabs for home screen
  static const List<String> mainTabs = [
    'Services',
    'Shops',
    'Messages',
  ];
  
  // ============================================================
  // AI CHAT LIMITS
  // ============================================================
  
  static const int freeUserAIDailyLimit = 3;
  static const int freePartnerAIDailyLimit = 3;
  static const int paidUserAIDailyLimit = -1;
  
  static const List<String> unlimitedAIPlans = [
    'basic', 'plus', 'pro',
    'starter', 'business',
  ];
  
  // ============================================================
  // FEATURE FLAGS
  // ============================================================
  
  static const bool enableAIChat = true;
  static const bool enableVoiceSearch = false;
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = true;
  static const bool enableReferralProgram = true;
  
  // ============================================================
  // SUBSCRIPTION PRICING (INR)
  // ============================================================
  
  static const Map<String, int> userPlanPrices = {
    'free': 0,
    'basic': 99,
    'plus': 199,
    'pro': 499,
  };
  
  static const Map<String, int> userPlanUnlocks = {
    'free': 0,
    'basic': 3,
    'plus': 8,
    'pro': 15,
  };
  
  static const Map<String, String> userPlanNames = {
    'free': 'Free',
    'basic':  'Basic',
    'plus': 'Plus',
    'pro': 'Pro',
  };
  
  static const Map<String, int> partnerPlanPrices = {
    'free': 0,
    'starter': 199,
    'business': 499,
  };
  
  static const Map<String, String> partnerPlanNames = {
    'free': 'Free',
    'starter': 'Starter',
    'business':  'Business',
  };
  
  // ============================================================
  // STORAGE BUCKETS
  // ============================================================
  
  static const String avatarsBucket = 'avatars';
  static const String coversBucket = 'covers';
  static const String itemsBucket = 'items';
  static const String shopsBucket = 'shops';
  
  // ============================================================
  // LIMITS & PAGINATION
  // ============================================================
  
  static const int defaultPageSize = 20;
  static const int searchResultsLimit = 50;
  static const int chatHistoryLimit = 100;
  static const int notificationsLimit = 50;
  static const int unlockExpiryDays = 30;
  
  // ============================================================
  // IMAGE CONSTRAINTS
  // ============================================================
  
  static const int maxImageSizeBytes = 5 * 1024 * 1024;
  static const int imageQuality = 85;
  static const double maxImageWidth = 1920;
  static const double maxImageHeight = 1920;
  
  // ============================================================
  // REFERRAL REWARDS
  // ============================================================
  
  static const int referrerRewardUnlocks = 2;
  static const int refereeRewardUnlocks = 1;
  static const int signupBonusUnlocks = 1;
  
  // ============================================================
  // CONTACT & LEGAL
  // ============================================================
  
  static const String supportEmail = 'support@welist.app';
  static const String privacyPolicyUrl = 'https://welist.app/privacy';
  static const String termsOfServiceUrl = 'https://welist.app/terms';
  static const String websiteUrl = 'https://welist.app';
  
  // ============================================================
  // CITIES
  // ============================================================
  
  static const List<String> supportedCities = [
    'Shillong',
    'Guwahati',
    'Tura',
    'Jowai',
    'Nongstoin',
    'Cherrapunji',
  ];
}

// ============================================================
// APP CONSTANTS
// ============================================================

class AppConstants {
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyUserCity = 'user_city';
  static const String keyThemeMode = 'theme_mode';
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyAuthToken = 'auth_token';
}