import '../core/api/api_client.dart';
import '../models/payment_history_model.dart';
import '../models/current_subscription_model.dart';
import '../models/subscription/subscription_plan_model.dart';
import '../models/upgrade_subscription_model.dart';
import '../models/subscription_list_model.dart';
import '../models/create_subscription_model.dart';
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
  /// Sends ONLY the two fields required by the backend:
  ///   • [subscriptionId]    — from POST /v1/subscriptions/upgrade response
  ///   • [razorpayPaymentId] — from Razorpay PaymentSuccessResponse.paymentId
  ///
  /// Returns `true`  when the backend confirms verification (verified == true).
  /// Returns `false` when the backend returns verified == false (not yet verified).
  /// Throws on network / server error.
  Future<bool> verifySubscriptionPayment({
    required String subscriptionId,
    required String razorpayPaymentId,
  }) async {
    AppLogger.i(
      '[$_tag] Verify-payment request:\n'
      '  subscriptionId    : $subscriptionId\n'
      '  razorpayPaymentId : $razorpayPaymentId',
    );

    final res = await _apiClient.post('subscriptions/verify-payment', body: {
      'subscriptionId':    subscriptionId,
      'razorpayPaymentId': razorpayPaymentId,
    });

    AppLogger.i('[$_tag] Verify-payment raw response: success=${res.success} data=${res.data}');

    if (!res.success) {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] Verify-payment API error: $errMsg');
      throw Exception(errMsg);
    }

    // Backend returns { "verified": true/false } or { "data": { "verified": ... } }
    // Handle both shapes.
    final data = res.data;
    bool verified = false;

    if (data is Map<String, dynamic>) {
      verified = data['verified'] == true;
    } else if (data == null) {
      // Some backends return success:true with no data when verified
      verified = true;
    }

    if (verified) {
      AppLogger.i('[$_tag] Payment verified successfully');
    } else {
      AppLogger.e('[$_tag] Payment not yet verified — verified=false returned by backend');
    }

    return verified;
  }

  /// Cancel the active subscription.
  ///
  /// Calls PUT /v1/subscriptions/cancel.
  /// Returns the backend success message on success.
  /// Throws with the backend error message on failure.
  Future<String> cancelSubscription() async {
    AppLogger.i('[$_tag] Cancel subscription request started');
    final res = await _apiClient.put('subscriptions/cancel');

    if (res.success) {
      final msg = res.message ?? 'Subscription cancelled. Access remains until the billing period ends.';
      AppLogger.i('[$_tag] Cancellation successful: $msg');
      return msg;
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] Cancellation failed: $errMsg');
      throw Exception(errMsg);
    }
  }

  /// Refund a completed subscription payment.
  ///
  /// Calls POST /v1/subscriptions/payments/{paymentId}/refund.
  /// Returns true when success == true.
  /// Throws with backend error message on failure.
  Future<bool> refundPayment(String paymentId) async {
    AppLogger.i('[$_tag] Refund request started for paymentId: $paymentId');
    final res = await _apiClient.post('subscriptions/payments/$paymentId/refund');

    if (res.success) {
      AppLogger.i('[$_tag] Refund request succeeded');
      return true;
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] Refund request failed: $errMsg');
      throw Exception(errMsg);
    }
  }

  /// Cancel a pending subscription payment.
  ///
  /// Calls PUT /v1/subscriptions/payments/{paymentId}/cancel.
  /// Returns true when success == true.
  /// Throws with backend error message on failure.
  Future<bool> cancelPayment(String paymentId) async {
    AppLogger.i('[$_tag] Cancel payment request started for paymentId: $paymentId');
    final res = await _apiClient.put('subscriptions/payments/$paymentId/cancel');

    if (res.success) {
      AppLogger.i('[$_tag] Cancel payment request succeeded');
      return true;
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] Cancel payment request failed: $errMsg');
      throw Exception(errMsg);
    }
  }

  /// Fetch the HTML receipt for a completed or refunded payment.
  ///
  /// Calls GET /v1/subscriptions/payments/{paymentId}/receipt.
  /// Returns the HTML string on success.
  /// Throws with backend error message on failure.
  Future<String?> getPaymentReceipt(String paymentId) async {
    AppLogger.i('[$_tag] Fetch payment receipt request started for paymentId: $paymentId');
    final res = await _apiClient.get('subscriptions/payments/$paymentId/receipt');

    if (res.success) {
      if (res.data != null && res.data is Map) {
        final dataMap = res.data as Map;
        final html = dataMap['html'] as String?;
        AppLogger.i('[$_tag] Successfully fetched receipt HTML');
        return html;
      }
      AppLogger.i('[$_tag] Receipt request success but data or html field is null');
      return null;
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] Fetch payment receipt failed: $errMsg');
      throw Exception(errMsg);
    }
  }

  /// Fetch all subscriptions records.
  ///
  /// Calls GET /v1/subscriptions.
  /// Returns a strongly typed List of [SubscriptionModel].
  /// Throws with backend error message on failure.
  Future<List<SubscriptionModel>> getSubscriptions() async {
    AppLogger.i('[$_tag] Fetch subscriptions list request started');
    final res = await _apiClient.get('subscriptions');

    if (res.success) {
      if (res.data == null) return <SubscriptionModel>[];
      final List<dynamic> dataList = res.data as List<dynamic>;
      AppLogger.i('[$_tag] Successfully fetched subscriptions count: ${dataList.length}');
      return dataList.map((e) => SubscriptionModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] Fetch subscriptions list failed: $errMsg');
      throw Exception(errMsg);
    }
  }

  /// Create a new subscription plan record.
  ///
  /// Calls POST /v1/subscriptions.
  /// Returns a strongly typed [CreateSubscriptionResponse].
  /// Throws with backend error message on failure.
  Future<CreateSubscriptionResponse> createSubscription({required String planId}) async {
    AppLogger.i('[$_tag] Create subscription request started for planId: $planId');
    final res = await _apiClient.post('subscriptions', body: {
      'planId': planId,
    });

    if (res.success) {
      if (res.data != null && res.data is Map) {
        AppLogger.i('[$_tag] Subscription created successfully');
        return CreateSubscriptionResponse.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('Server returned empty data for created subscription');
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] Create subscription failed: $errMsg');
      throw Exception(errMsg);
    }
  }

  /// Update an existing subscription record.
  ///
  /// Calls PUT /v1/subscriptions/{subscriptionId}.
  /// Returns strongly typed [CreateSubscriptionResponse].
  /// Throws with backend error message on failure.
  Future<CreateSubscriptionResponse> updateSubscription({
    required String subscriptionId,
    required Map<String, dynamic> data,
  }) async {
    AppLogger.i('[$_tag] Update subscription request started for subscriptionId: $subscriptionId');
    final res = await _apiClient.put('subscriptions/$subscriptionId', body: data);

    if (res.success) {
      if (res.data != null && res.data is Map) {
        AppLogger.i('[$_tag] Subscription updated successfully');
        return CreateSubscriptionResponse.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('Server returned empty data for updated subscription');
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] Update subscription failed: $errMsg');
      throw Exception(errMsg);
    }
  }

  /// Delete a subscription record.
  ///
  /// Calls DELETE /v1/subscriptions/{subscriptionId}.
  /// Returns human-readable success message.
  /// Throws with backend error message on failure.
  Future<String> deleteSubscription({required String subscriptionId}) async {
    AppLogger.i('[$_tag] Delete subscription request started for subscriptionId: $subscriptionId');
    final res = await _apiClient.delete('subscriptions/$subscriptionId');

    if (res.success) {
      final msg = res.message ?? 'Subscription deleted';
      AppLogger.i('[$_tag] Subscription deleted successfully: $msg');
      return msg;
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] Delete subscription failed: $errMsg');
      throw Exception(errMsg);
    }
  }
}
