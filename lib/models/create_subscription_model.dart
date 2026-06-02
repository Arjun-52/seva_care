class CreateSubscriptionResponse {
  final String id;
  final String userId;
  final String planId;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final bool autoRenew;
  final String? razorpaySubId;
  final String? scheduledPlanId;
  final DateTime createdAt;

  CreateSubscriptionResponse({
    required this.id,
    required this.userId,
    required this.planId,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.autoRenew,
    this.razorpaySubId,
    this.scheduledPlanId,
    required this.createdAt,
  });

  factory CreateSubscriptionResponse.fromJson(Map<String, dynamic> json) {
    return CreateSubscriptionResponse(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      autoRenew: json['autoRenew'] as bool? ?? true,
      razorpaySubId: json['razorpaySubId'] as String?,
      scheduledPlanId: json['scheduledPlanId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'planId': planId,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'autoRenew': autoRenew,
      'razorpaySubId': razorpaySubId,
      'scheduledPlanId': scheduledPlanId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
