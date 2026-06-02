import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seva_care_app/models/subscription/subscription_order_result.dart';
import 'package:seva_care_app/repositories/subscription_repository.dart';
import 'package:seva_care_app/services/subscription_payment_service.dart';
import 'package:seva_care_app/core/api/api_client.dart';

class MockApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockSubscriptionRepository extends SubscriptionRepository {
  MockSubscriptionRepository() : super(MockApiClient());

  @override
  Future<SubscriptionOrderResult> upgradeSubscription(String planId) async {
    return const PaidSubscriptionOrder(
      orderId: 'order_MOCK12345678',
      amount: 499900,
      keyId: 'rzp_test_1DP5mmOlF5G6q',
      subscriptionId: 'sub_MOCK123',
      paymentId: 'pay_MOCK123',
    );
  }
}

void main() {
  test('Verify Razorpay Key and Checkout Options in Payment Service', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    const channel = MethodChannel('razorpay_flutter');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'open') {
        return <dynamic, dynamic>{};
      }
      return null;
    });

    final mockRepo = MockSubscriptionRepository();
    final paymentService = SubscriptionPaymentService(mockRepo);
    paymentService.init();

    print('--- START RUNTIME LOG CHECK ---');
    paymentService.purchaseSubscription(
      planId: 'P002',
      email: 'test@sevacare.com',
      name: 'Rishi',
    );
    await Future.delayed(const Duration(milliseconds: 100));
    print('--- END RUNTIME LOG CHECK ---');
  });
}
