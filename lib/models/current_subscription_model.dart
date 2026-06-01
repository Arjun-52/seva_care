class CurrentSubscriptionModel {
  final String id;
  final String planId;
  final String planName;
  final int priceInr;
  final String period;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> features;

  CurrentSubscriptionModel({
    required this.id,
    required this.planId,
    required this.planName,
    required this.priceInr,
    required this.period,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.features,
  });

  factory CurrentSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return CurrentSubscriptionModel(
      id: json['id'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      planName: json['planName'] as String? ?? '',
      priceInr: json['priceInr'] as int? ?? 0,
      period: json['period'] as String? ?? 'monthly',
      status: json['status'] as String? ?? 'active',
      startDate: json['startDate'] != null 
          ? DateTime.tryParse(json['startDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null 
          ? DateTime.tryParse(json['endDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      features: (json['features'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planId': planId,
      'planName': planName,
      'priceInr': priceInr,
      'period': period,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'features': features,
    };
  }
}
