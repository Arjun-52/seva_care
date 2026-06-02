sealed class SubscriptionOrderResult {
  const SubscriptionOrderResult();
}

class FreeSubscriptionOrder extends SubscriptionOrderResult {
  final String subscriptionId;
  const FreeSubscriptionOrder({required this.subscriptionId});
}

class PaidSubscriptionOrder extends SubscriptionOrderResult {
  final String orderId;
  final int amount; // in paise
  final String keyId;
  final String subscriptionId;
  final String paymentId;

  const PaidSubscriptionOrder({
    required this.orderId,
    required this.amount,
    required this.keyId,
    required this.subscriptionId,
    required this.paymentId,
  });
}
