import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/payment_service.dart';

class SubscriptionScreen extends StatefulWidget {
  final bool isPartner;

  const SubscriptionScreen({
    super.key,
    this.isPartner = false,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final PaymentService _paymentService = PaymentService();
  String? _selectedPlan;
  bool _isProcessing = false;

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  List<_PlanData> get _plans {
    if (widget.isPartner) {
      return [
        _PlanData(
          id: 'free',
          name: 'Free',
          price: 0,
          period: 'Forever',
          features: [
            'Basic profile listing',
            'Up to 5 services',
            'Limited visibility',
          ],
          notIncluded: [
            'Read & reply to messages',
            'Verified badge',
            'Analytics dashboard',
          ],
        ),
        _PlanData(
          id: 'starter',
          name: 'Starter',
          price: 199,
          period: '/month',
          features: [
            'Everything in Free',
            'Read & reply to messages',
            'Up to 20 services',
            'Basic analytics',
          ],
          notIncluded:  [
            'Verified badge',
            'Priority listing',
          ],
        ),
        _PlanData(
          id: 'business',
          name: 'Business',
          price: 499,
          period: '/month',
          isPopular: true,
          features:  [
            'Everything in Starter',
            'Verified badge ✓',
            'Unlimited services',
            'Priority listing',
            'Advanced analytics',
            'Priority support',
          ],
          notIncluded: [],
        ),
      ];
    } else {
      return [
        _PlanData(
          id: 'free',
          name: 'Free',
          price: 0,
          period: 'Forever',
          features: [
            'Browse all professionals',
            'AI chat assistance',
            'View limited details',
          ],
          notIncluded: [
            'Unlock contacts (0)',
            'Priority support',
          ],
        ),
        _PlanData(
          id: 'basic',
          name: 'Basic',
          price: 99,
          period: '/month',
          features: [
            'Everything in Free',
            '3 contact unlocks',
            'View full profiles',
          ],
          notIncluded:  [
            'Priority support',
          ],
        ),
        _PlanData(
          id: 'plus',
          name: 'Plus',
          price: 199,
          period: '/month',
          isPopular: true,
          features: [
            'Everything in Basic',
            '8 contact unlocks',
            'Priority in AI suggestions',
            'Chat support',
          ],
          notIncluded: [],
        ),
        _PlanData(
          id: 'pro',
          name: 'Pro',
          price: 499,
          period: '/month',
          features: [
            'Everything in Plus',
            '15 contact unlocks',
            'Exclusive deals',
            'Priority support',
            'Early access to features',
          ],
          notIncluded: [],
        ),
      ];
    }
  }

  Future<void> _handleSubscribe(_PlanData plan) async {
    if (plan.price == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already on the Free plan'),
          backgroundColor: AppColors.info,
        ),
      );
      return;
    }

    setState(() {
      _selectedPlan = plan.id;
      _isProcessing = true;
    });

    final authProvider = context.read<AuthProvider>();
    final dataProvider = context.read<DataProvider>();
    final user = authProvider.user;

    if (user == null) {
      setState(() => _isProcessing = false);
      return;
    }

    // Initialize payment service with callbacks
    _paymentService.initialize(
      onSuccess: (response) async {
        final success = await dataProvider.subscribe(
          userId: widget.isPartner
              ? dataProvider.currentProfessional!.id
              : user.id,
          userType: widget.isPartner ? 'professional' : 'user',
          plan: plan.id,
          amount: plan.price.toDouble(),
          paymentId: response.paymentId ?? '',
          orderId: response.orderId,
        );

        if (success) {
          await authProvider.refreshUser();

          if (mounted) {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully upgraded to ${plan.name} plan!'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context);
          }
        }
      },
      onFailure: (response) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Payment failed'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );

    // Start payment flow
    await _paymentService.startPayment(
      planId: plan.id,
      planType: widget.isPartner ? 'partner' : 'user',
      amountInRupees: plan.price,
      planName: plan.name,
      userEmail: user.email,
      userName: user.name,
      userPhone: user.phone,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final dataProvider = context.watch<DataProvider>();

    String currentPlan;
    if (widget.isPartner) {
      currentPlan = dataProvider.selectedProfessional?.subscriptionPlan ?? 'free';
    } else {
      currentPlan = authProvider.user?.subscriptionPlan ?? 'free';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor:  AppColors.background,
        leading: IconButton(
          icon:  const Icon(Iconsax. arrow_left, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Subscription', style: AppTextStyles.h3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(),
            const SizedBox(height: 24),

            // Current Plan
            Text(
              'Current Plan:  ${currentPlan.toUpperCase()}',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),

            // Plans
            for (final plan in _plans) _buildPlanCard(plan, currentPlan),

            const SizedBox(height: 24),

            // Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.info_circle, color: AppColors.info, size: 20),
                  const SizedBox(width:  12),
                  Expanded(
                    child: Text(
                      'All plans are billed monthly. You can cancel anytime.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize:  12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.inputBorderGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Iconsax.crown,
              color: AppColors.white,
              size: 28,
            ),
          ),
          const SizedBox(width:  16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upgrade Your Plan',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isPartner
                      ?  'Get more visibility and features'
                      : 'Unlock more contacts and features',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(_PlanData plan, String currentPlan) {
    final isCurrentPlan = plan.id == currentPlan;
    final isProcessingThis = _isProcessing && _selectedPlan == plan.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border. all(
          color: isCurrentPlan
              ? AppColors.primary
              : plan.isPopular
                  ? AppColors.accent
                  : AppColors.surfaceLight,
          width: isCurrentPlan || plan.isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Badge
          if (plan.isPopular || isCurrentPlan)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isCurrentPlan ? AppColors.primary : AppColors.accent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Text(
                isCurrentPlan ? 'CURRENT PLAN' : 'MOST POPULAR',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color:  AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name & Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    RichText(
                      text:  TextSpan(
                        children: [
                          TextSpan(
                            text: '₹${plan.price}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          TextSpan(
                            text: plan.period,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height:  16),

                // Features
                ... plan.features.map((feature) => _buildFeatureItem(
                      feature,
                      included: true,
                    )),

                // Not Included
                ... plan.notIncluded.map((feature) => _buildFeatureItem(
                      feature,
                      included: false,
                    )),

                const SizedBox(height: 16),

                // Subscribe Button
                if (! isCurrentPlan)
                  SizedBox(
                    width:  double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: plan.price == 0 || isProcessingThis
                          ? null
                          :  () => _handleSubscribe(plan),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.surfaceLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isProcessingThis
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              plan.price == 0 ? 'Current' : 'Subscribe',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature, {required bool included}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            included ? Iconsax.tick_circle : Iconsax. close_circle,
            size: 16,
            color:  included ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child:  Text(
              feature,
              style: TextStyle(
                fontSize: 13,
                color:  included ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanData {
  final String id;
  final String name;
  final int price;
  final String period;
  final bool isPopular;
  final List<String> features;
  final List<String> notIncluded;

  _PlanData({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    this.isPopular = false,
    required this.features,
    required this.notIncluded,
  });
}