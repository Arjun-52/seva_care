class SubscriptionModel {
  final String id;
  final String nriName;
  final String country;
  final String plan;
  final int amount;
  final String status;
  final DateTime? nextBilling;
  final DateTime? since;
  final String senior;
  final String? paymentId;
  final String? paymentStatus;
  final bool autoRenew;

  SubscriptionModel({
    required this.id,
    required this.nriName,
    required this.country,
    required this.plan,
    required this.amount,
    required this.status,
    this.nextBilling,
    this.since,
    required this.senior,
    this.paymentId,
    this.paymentStatus,
    this.autoRenew = true,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String? ?? '',
      nriName: json['nriName'] as String? ?? '',
      country: json['country'] as String? ?? '',
      plan: json['plan'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending_payment',
      nextBilling: json['nextBilling'] != null
          ? DateTime.tryParse(json['nextBilling'] as String)
          : null,
      since: json['since'] != null
          ? DateTime.tryParse(json['since'] as String)
          : null,
      senior: json['senior'] as String? ?? '',
      paymentId: json['paymentId'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
      autoRenew: json['autoRenew'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nriName': nriName,
      'country': country,
      'plan': plan,
      'amount': amount,
      'status': status,
      'nextBilling': nextBilling?.toIso8601String(),
      'since': since?.toIso8601String(),
      'senior': senior,
      'paymentId': paymentId,
      'paymentStatus': paymentStatus,
      'autoRenew': autoRenew,
    };
  }
}
