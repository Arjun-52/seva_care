class PaymentHistoryModel {
  final String id;
  final String planName;
  final int amount;
  final String currency;
  final String status;
  final String? method;
  final String? razorpayId;
  final DateTime? paidAt;
  final DateTime createdAt;

  PaymentHistoryModel({
    required this.id,
    required this.planName,
    required this.amount,
    required this.currency,
    required this.status,
    this.method,
    this.razorpayId,
    this.paidAt,
    required this.createdAt,
  });

  factory PaymentHistoryModel.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryModel(
      id: json['id'] as String? ?? '',
      planName: json['planName'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      status: json['status'] as String? ?? 'pending',
      method: json['method'] as String?,
      razorpayId: json['razorpayId'] as String?,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planName': planName,
      'amount': amount,
      'currency': currency,
      'status': status,
      'method': method,
      'razorpayId': razorpayId,
      'paidAt': paidAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
