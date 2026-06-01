class PaymentVerificationRequest {
  final String subscriptionId;
  final String razorpayPaymentId;

  PaymentVerificationRequest({
    required this.subscriptionId,
    required this.razorpayPaymentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'subscriptionId': subscriptionId,
      'razorpayPaymentId': razorpayPaymentId,
    };
  }
}

class PaymentVerificationResponse {
  final bool verified;

  PaymentVerificationResponse({
    required this.verified,
  });

  factory PaymentVerificationResponse.fromJson(Map<String, dynamic> json) {
    return PaymentVerificationResponse(
      verified: json['verified'] as bool? ?? false,
    );
  }
}
