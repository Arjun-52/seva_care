sealed class SubscriptionPaymentResult {
  const SubscriptionPaymentResult();
}

class SubscriptionFreeEnrollmentSucceeded extends SubscriptionPaymentResult {
  final String planId;
  const SubscriptionFreeEnrollmentSucceeded(this.planId);
}

class SubscriptionPaymentSucceeded extends SubscriptionPaymentResult {
  final String razorpayPaymentId;
  final String razorpayOrderId;
  final String razorpaySignature;
  
  const SubscriptionPaymentSucceeded({
    required this.razorpayPaymentId,
    required this.razorpayOrderId,
    required this.razorpaySignature,
  });
}

class SubscriptionPaymentFailed extends SubscriptionPaymentResult {
  final SubscriptionPaymentFailureReason reason;
  final String message;

  const SubscriptionPaymentFailed({
    required this.reason,
    required this.message,
  });
}

class SubscriptionExternalWalletSelected extends SubscriptionPaymentResult {
  final String? walletName;
  const SubscriptionExternalWalletSelected(this.walletName);
}

enum SubscriptionPaymentFailureReason {
  network,
  timeout,
  ssl,
  invalidOrder,
  paymentDeclined,
  unknown,
}
