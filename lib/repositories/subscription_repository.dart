import '../core/api/api_client.dart';
import '../models/payment_history_model.dart';
import '../models/payment_verification_model.dart';
import '../models/current_subscription_model.dart';
import '../models/subscription/subscription_plan_model.dart';
import '../models/subscription/subscription_order_result.dart';
import '../config/env.dart';
import '../utils/app_logger.dart';

class SubscriptionRepository {
  static const _tag = 'SubscriptionRepository';
  final ApiClient _apiClient;

  SubscriptionRepository(this._apiClient);

  /// Fetch available subscription plans
  Future<List<SubscriptionPlanModel>> fetchPlans() async {
    AppLogger.i('[$_tag] Fetching subscription plans');
    final res = await _apiClient.get('subscriptions/plans');
    if (res.success && res.data != null) {
      final List<dynamic> dataList = res.data as List<dynamic>;
      return dataList.map((e) => SubscriptionPlanModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      AppLogger.e('[$_tag] Failed to fetch plans: ${res.errorMessage}');
      throw Exception(res.errorMessage);
    }
  }

  /// Upgrade/Initiate a paid or free subscription
  Future<SubscriptionOrderResult> upgradeSubscription(String planId) async {
    AppLogger.i('[$_tag] Upgrading subscription to plan: $planId');
    final res = await _apiClient.post(
      'subscriptions/upgrade',
      body: {'planId': planId},
    );

    if (!res.success || res.data == null) {
      AppLogger.e('[$_tag] Failed to upgrade subscription: ${res.errorMessage}');
      throw Exception(res.errorMessage);
    }

    final data = res.data as Map<String, dynamic>;
    
    // Check if it is a free order or if payment is not required
    final isFree = data['isFree'] as bool? ?? false;
    final subscriptionId = data['subscriptionId'] as String? ?? '';
    
    if (isFree || data['order'] == null) {
      AppLogger.i('[$_tag] Free subscription detected');
      return FreeSubscriptionOrder(subscriptionId: subscriptionId);
    }

    final orderData = data['order'] as Map<String, dynamic>;
    final orderId = orderData['id'] as String? ?? '';
    final amount = orderData['amount'] as int? ?? 0;
    final paymentId = data['paymentId'] as String? ?? '';
    final keyId = data['keyId'] as String? ?? Env.razorpayKey;

    AppLogger.i('[$_tag] Paid subscription order created successfully: $orderId');
    return PaidSubscriptionOrder(
      orderId: orderId,
      amount: amount,
      keyId: keyId,
      subscriptionId: subscriptionId,
      paymentId: paymentId,
    );
  }

  /// Verify a subscription payment with the backend
  Future<PaymentVerificationResponse> verifySubscriptionPayment({
    required String subscriptionId,
    required String razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
  }) async {
    AppLogger.i('[$_tag] Verifying payment for Subscription: $subscriptionId, Payment: $razorpayPaymentId');
    
    final body = {
      'subscriptionId': subscriptionId,
      'razorpayPaymentId': razorpayPaymentId,
      if (razorpayOrderId != null) 'razorpayOrderId': razorpayOrderId,
      if (razorpaySignature != null) 'razorpaySignature': razorpaySignature,
    };

    final res = await _apiClient.post(
      'subscriptions/verify-payment',
      body: body,
    );

    if (res.success && res.data != null) {
      final response = PaymentVerificationResponse.fromJson(res.data as Map<String, dynamic>);
      if (response.verified) {
        AppLogger.i('[$_tag] Payment verified successfully');
      } else {
        AppLogger.e('[$_tag] Payment verification failed');
      }
      return response;
    } else {
      AppLogger.e('[$_tag] API error: ${res.errorMessage}');
      throw Exception(res.errorMessage);
    }
  }

  /// Get current subscription status
  Future<CurrentSubscriptionModel?> getCurrentSubscription() async {
    AppLogger.i('[$_tag] Fetching current subscription');
    final res = await _apiClient.get('subscriptions/current');
    if (res.success) {
      if (res.data == null) {
        AppLogger.i('[$_tag] No active subscription');
        return null;
      }
      return CurrentSubscriptionModel.fromJson(res.data as Map<String, dynamic>);
    } else {
      AppLogger.e('[$_tag] Failed to fetch current subscription: ${res.errorMessage}');
      throw Exception(res.errorMessage);
    }
  }

  /// Legacy methods (kept for compatibility)
  Future<List<PaymentHistoryModel>> getSubscriptionPayments() async {
    AppLogger.i('[$_tag] Fetching payment history');
    final res = await _apiClient.get('subscriptions/payments');
    if (res.success) {
      if (res.data == null) return <PaymentHistoryModel>[];
      final List<dynamic> dataList = res.data as List<dynamic>;
      return dataList.map((e) => PaymentHistoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      AppLogger.e('[$_tag] API failure: ${res.errorMessage}');
      throw Exception(res.errorMessage);
    }
  }

  Future<PaymentVerificationResponse> verifyPayment(String subscriptionId, String razorpayPaymentId) async {
    return verifySubscriptionPayment(
      subscriptionId: subscriptionId,
      razorpayPaymentId: razorpayPaymentId,
    );
  }
}
