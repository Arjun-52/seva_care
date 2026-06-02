import '../core/api/api_client.dart';
import '../models/payment_history_model.dart';
import '../models/current_subscription_model.dart';
import '../models/subscription/subscription_plan_model.dart';
import '../models/upgrade_subscription_model.dart';
import '../utils/app_logger.dart';

/// Result returned by [SubscriptionRepository.upgradeSubscription].
///
/// - [isImmediate] = true  → backend created a Razorpay order; open checkout.
/// - [isImmediate] = false → backend scheduled a downgrade; show [message] to user.
class UpgradeResult {
  /// Human-readable message from the backend (always present).
  final String message;

  /// Set when [isImmediate] is true — contains order/plan details for Razorpay.
  final UpgradeSubscriptionModel? order;

  bool get isImmediate => order != null;

  const UpgradeResult.immediate(UpgradeSubscriptionModel this.order, {required this.message});
  const UpgradeResult.scheduled({required this.message}) : order = null;
}

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

  /// Fetch payment history
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

  /// Upgrade (or downgrade) a subscription plan.
  ///
  /// Returns [UpgradeResult.immediate] when the backend created a Razorpay order
  /// (the caller should open Razorpay Checkout).
  ///
  /// Returns [UpgradeResult.scheduled] when the backend accepted the request but
  /// no order was created (e.g. downgrade scheduled for next billing cycle).
  Future<UpgradeResult> upgradeSubscription(String planId) async {
    AppLogger.i('[$_tag] Upgrade request started for planId: $planId');
    final res = await _apiClient.post('subscriptions/upgrade', body: {
      'planId': planId,
    });

    if (!res.success) {
      // Hard API failure (4xx / 5xx)
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] Upgrade request failed: $errMsg');
      throw Exception(errMsg);
    }

    // Success + data → immediate Razorpay checkout
    if (res.data != null) {
      AppLogger.i('[$_tag] Upgrade response received — immediate checkout');
      final model = UpgradeSubscriptionModel.fromJson(res.data as Map<String, dynamic>);
      return UpgradeResult.immediate(model, message: res.failure?.message ?? 'Upgrade initiated');
    }

    // Success + data == null → scheduled change (downgrade / same-cycle deferral)
    AppLogger.i('[$_tag] Upgrade accepted — scheduled (no order created). Message: ${res.message}');
    return UpgradeResult.scheduled(
      message: res.message ?? 'Your plan change has been scheduled for the next billing cycle.',
    );
  }

  /// Verify subscription payment after Razorpay Checkout completes.
  ///
  /// Sends all captured Razorpay fields to the backend verify-payment endpoint.
  /// [subscriptionId]    — from POST /v1/subscriptions/upgrade response
  /// [razorpayPaymentId] — from Razorpay PaymentSuccessResponse
  /// [razorpayOrderId]   — from Razorpay PaymentSuccessResponse
  /// [razorpaySignature] — from Razorpay PaymentSuccessResponse
  /// [backendPaymentId]  — paymentId from POST /v1/subscriptions/upgrade response
  Future<bool> verifySubscriptionPayment({
    required String subscriptionId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
    required String backendPaymentId,
  }) async {
    AppLogger.i(
      '[$_tag] Verification started:\n'
      '  subscriptionId    : $subscriptionId\n'
      '  razorpayPaymentId : $razorpayPaymentId\n'
      '  razorpayOrderId   : $razorpayOrderId\n'
      '  razorpaySignature : $razorpaySignature\n'
      '  backendPaymentId  : $backendPaymentId',
    );
    final res = await _apiClient.post('subscriptions/verify-payment', body: {
      'subscriptionId':    subscriptionId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpayOrderId':   razorpayOrderId,
      'razorpaySignature': razorpaySignature,
      'paymentId':         backendPaymentId,
    });
    if (res.success) {
      AppLogger.i('[$_tag] Verification success');
      return true;
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] Verification failure: $errMsg');
      throw Exception(errMsg);
    }
  }
}

