import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

/// Payment Service using Razorpay
/// Razorpay Secret Key is stored on server, NOT in client app
class PaymentService {
  final _supabase = Supabase.instance.client;
  late Razorpay _razorpay;
  
  // Callbacks
  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  Function(ExternalWalletResponse)? onWallet;

  // ============================================================
  // INITIALIZATION
  // ============================================================
  
  void initialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    Function(ExternalWalletResponse)? onWallet,
  }) {
    this.onSuccess = onSuccess;
    this.onFailure = onFailure;
    this.onWallet = onWallet;

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  // ============================================================
  // CREATE ORDER (via Edge Function)
  // ============================================================
  
  /// Create a Razorpay order via Edge Function
  /// This is more secure as order creation happens on server
  Future<OrderResult> createOrder({
    required int amountInPaise,
    required String planId,
    required String planType,
  }) async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        return OrderResult(
          success: false,
          error: 'User not authenticated',
        );
      }

      final response = await http.post(
        Uri.parse(AppConfig.createOrderEndpoint),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({
          'amount': amountInPaise,
          'currency': 'INR',
          'planId': planId,
          'planType': planType,
          'userId': session.user.id,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          return OrderResult(
            success: true,
            orderId: data['orderId'],
            amount: data['amount'],
            currency: data['currency'],
          );
        } else {
          return OrderResult(
            success:  false,
            error: data['error'] ?? 'Failed to create order',
          );
        }
      } else {
        return OrderResult(
          success: false,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Create Order Error: $e');
      return OrderResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // ============================================================
  // OPEN PAYMENT CHECKOUT
  // ============================================================
  
  /// Open Razorpay checkout with the order
  void openCheckout({
    required String orderId,
    required int amountInPaise,
    required String planName,
    required String userEmail,
    required String userName,
    String? userPhone,
  }) {
    final options = {
      'key': AppConfig.razorpayKeyId,
      'amount': amountInPaise,
      'order_id': orderId,
      'name': AppConfig.appDisplayName,
      'description': 'Subscription:  $planName',
      'prefill': {
        'email': userEmail,
        'contact': userPhone ??  '',
        'name': userName,
      },
      'theme': {
        'color': '#4A90D9',
      },
      'modal': {
        'confirm_close': true,
        'animation': true,
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay Open Error: $e');
      onFailure?.call(PaymentFailureResponse(
        Razorpay.UNKNOWN_ERROR,
        'Failed to open payment:  $e',
        null,
      ));
    }
  }

  // ============================================================
  // VERIFY PAYMENT (via Edge Function)
  // ============================================================
  
  /// Verify payment signature via Edge Function
  /// Razorpay secret key is on server, NOT in client app
  Future<VerificationResult> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        return VerificationResult(
          success: false,
          error: 'User not authenticated',
        );
      }

      final response = await http.post(
        Uri.parse(AppConfig.verifyPaymentEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({
          'razorpay_order_id':  orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
          'userId': session.user.id,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        return VerificationResult(
          success: data['success'] == true,
          message: data['message'],
          error: data['error'],
        );
      } else {
        return VerificationResult(
          success: false,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Verify Payment Error: $e');
      return VerificationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // ============================================================
  // QUICK PAYMENT (Create Order + Open Checkout)
  // ============================================================
  
  /// Convenience method:  create order and open checkout
  Future<bool> startPayment({
    required String planId,
    required String planType,
    required int amountInRupees,
    required String planName,
    required String userEmail,
    required String userName,
    String? userPhone,
  }) async {
    // Create order first
    final orderResult = await createOrder(
      amountInPaise: amountInRupees * 100,
      planId:  planId,
      planType:  planType,
    );

    if (! orderResult.success || orderResult.orderId == null) {
      onFailure?.call(PaymentFailureResponse(
        Razorpay.UNKNOWN_ERROR,
        orderResult.error ??  'Failed to create order',
        null,
      ));
      return false;
    }

    // Open checkout
    openCheckout(
      orderId:  orderResult.orderId!,
      amountInPaise: amountInRupees * 100,
      planName: planName,
      userEmail: userEmail,
      userName: userName,
      userPhone: userPhone,
    );

    return true;
  }

  // ============================================================
  // INTERNAL HANDLERS
  // ============================================================
  
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('Payment Success: ${response.paymentId}');
    
    // Verify payment on server
    if (response.orderId != null && 
        response.paymentId != null && 
        response.signature != null) {
      
      final verification = await verifyPayment(
        orderId: response.orderId!,
        paymentId:  response.paymentId!,
        signature: response.signature!,
      );

      if (verification.success) {
        onSuccess?.call(response);
      } else {
        onFailure?.call(PaymentFailureResponse(
          Razorpay.UNKNOWN_ERROR,
          'Payment verification failed: ${verification.error}',
          null,
        ));
      }
    } else {
      onSuccess?.call(response);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response. code} - ${response.message}');
    onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    onWallet?.call(response);
  }
}

// ============================================================
// MODELS
// ============================================================

class OrderResult {
  final bool success;
  final String?  orderId;
  final int?  amount;
  final String? currency;
  final String? error;

  OrderResult({
    required this. success,
    this.orderId,
    this.amount,
    this.currency,
    this.error,
  });
}

class VerificationResult {
  final bool success;
  final String? message;
  final String? error;

  VerificationResult({
    required this. success,
    this.message,
    this.error,
  });
}