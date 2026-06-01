import '../core/api/api_client.dart';
import '../models/payment_history_model.dart';
import '../models/payment_verification_model.dart';
import '../utils/app_logger.dart';

class SubscriptionRepository {
  final ApiClient _apiClient;

  SubscriptionRepository(this._apiClient);

  Future<List<PaymentHistoryModel>> getSubscriptionPayments() async {
    AppLogger.i('Payment history requested');
    final res = await _apiClient.get('subscriptions/payments');
    if (res.success) {
      AppLogger.i('API success');
      if (res.data == null) {
        AppLogger.i('Empty response (data is null)');
        return <PaymentHistoryModel>[];
      }
      final List<dynamic> dataList = res.data as List<dynamic>;
      AppLogger.i('Number of records loaded: ${dataList.length}');
      if (dataList.isEmpty) {
        AppLogger.i('Empty response');
      }
      return dataList.map((e) => PaymentHistoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      AppLogger.e('API failure: ${res.errorMessage}');
      throw Exception(res.errorMessage);
    }
  }

  Future<PaymentVerificationResponse> verifyPayment(String subscriptionId, String razorpayPaymentId) async {
    AppLogger.i('Payment verification started');
    AppLogger.i('Subscription ID: $subscriptionId');
    AppLogger.i('Razorpay Payment ID: $razorpayPaymentId');

    final request = PaymentVerificationRequest(
      subscriptionId: subscriptionId,
      razorpayPaymentId: razorpayPaymentId,
    );

    final res = await _apiClient.post(
      'subscriptions/verify-payment',
      body: request.toJson(),
    );

    if (res.success && res.data != null) {
      AppLogger.i('Verification response received');
      final response = PaymentVerificationResponse.fromJson(res.data as Map<String, dynamic>);
      if (response.verified) {
        AppLogger.i('Payment verified successfully');
      } else {
        AppLogger.e('Verification failed');
      }
      return response;
    } else {
      AppLogger.e('API error: ${res.errorMessage}');
      throw Exception(res.errorMessage);
    }
  }
}
