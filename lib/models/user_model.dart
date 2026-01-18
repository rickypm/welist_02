class UserModel {
  final String id;
  final String email;
  final String name;
  final String?  phone;
  final String? avatarUrl;
  final String role;
  final String city;
  final String subscriptionPlan;
  final int unlocksRemaining;
  final bool isActive;
  final DateTime?  lastSeenAt;
  final String? referralCode;
  final String? referredByUserId;
  final String? referredByCode;
  final int totalReferrals;
  final double referralEarnings;
  final bool signupRewardClaimed;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this. email,
    required this.name,
    this.phone,
    this.avatarUrl,
    this.role = 'user',
    this.city = 'Shillong',
    this.subscriptionPlan = 'free',
    this.unlocksRemaining = 0,
    this.isActive = true,
    this.lastSeenAt,
    this.referralCode,
    this.referredByUserId,
    this.referredByCode,
    this.totalReferrals = 0,
    this.referralEarnings = 0,
    this.signupRewardClaimed = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ??  DateTime.now();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name:  json['name'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      role: json['role'] ?? 'user',
      city: json['city'] ??  'Shillong',
      subscriptionPlan: json['subscription_plan'] ?? 'free',
      unlocksRemaining: json['unlocks_remaining'] ?? 0,
      isActive: json['is_active'] ??  true,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'])
          : null,
      referralCode: json['referral_code'],
      referredByUserId: json['referred_by_user_id'],
      referredByCode: json['referred_by_code'],
      totalReferrals: json['total_referrals'] ?? 0,
      referralEarnings: (json['referral_earnings'] ??  0).toDouble(),
      signupRewardClaimed: json['signup_reward_claimed'] ??  false,
      createdAt:  json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':  id,
      'email': email,
      'name': name,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role,
      'city': city,
      'subscription_plan': subscriptionPlan,
      'unlocks_remaining': unlocksRemaining,
      'is_active': isActive,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'referral_code': referralCode,
      'referred_by_user_id':  referredByUserId,
      'referred_by_code': referredByCode,
      'total_referrals': totalReferrals,
      'referral_earnings': referralEarnings,
      'signup_reward_claimed': signupRewardClaimed,
      'created_at':  createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String?  id,
    String? email,
    String? name,
    String? phone,
    String?  avatarUrl,
    String?  role,
    String? city,
    String? subscriptionPlan,
    int? unlocksRemaining,
    bool? isActive,
    DateTime? lastSeenAt,
    String? referralCode,
    String? referredByUserId,
    String? referredByCode,
    int? totalReferrals,
    double? referralEarnings,
    bool? signupRewardClaimed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      city: city ?? this.city,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      unlocksRemaining: unlocksRemaining ?? this.unlocksRemaining,
      isActive: isActive ?? this.isActive,
      lastSeenAt:  lastSeenAt ?? this.lastSeenAt,
      referralCode: referralCode ?? this. referralCode,
      referredByUserId: referredByUserId ?? this.referredByUserId,
      referredByCode: referredByCode ?? this. referredByCode,
      totalReferrals: totalReferrals ?? this.totalReferrals,
      referralEarnings: referralEarnings ?? this.referralEarnings,
      signupRewardClaimed: signupRewardClaimed ?? this.signupRewardClaimed,
      createdAt:  createdAt ?? this.createdAt,
      updatedAt:  updatedAt ?? this.updatedAt,
    );
  }

  // Computed properties
  bool get isPartner => role == 'partner';
  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';
  bool get isPaidUser => subscriptionPlan != 'free';
  bool get hasUnlocks => unlocksRemaining > 0;
  bool get hasReferralCode => referralCode != null && referralCode!.isNotEmpty;
  bool get wasReferred => referredByCode != null && referredByCode! .isNotEmpty;

  // Alias getters for compatibility
  String get displayPlan => planDisplayName;

  String get displayName => name.isNotEmpty ? name : email.split('@').first;
  
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts. first[0]}${parts.last[0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return 'U';
  }

  String get planDisplayName {
    switch (subscriptionPlan) {
      case 'basic':
        return 'Basic';
      case 'plus':
        return 'Plus';
      case 'pro':
        return 'Pro';
      default:
        return 'Free';
    }
  }

  @override
  String toString() => 'UserModel(id: $id, email: $email, name: $name, role: $role)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id. hashCode;
}