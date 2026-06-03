class SubscriptionPlanModel {
  final String id;
  final String name;
  final int priceInr;
  final String period;
  final List<String> features;
  final bool isPopular;
  final int maxSeniors;
  final bool active;
  final DateTime? createdAt;

  SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.priceInr,
    required this.period,
    required this.features,
    this.isPopular = false,
    this.maxSeniors = 1,
    this.active = true,
    this.createdAt,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      priceInr: json['priceInr'] as int? ?? 0,
      period: json['period'] as String? ?? 'monthly',
      features: (json['features'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isPopular: json['isPopular'] as bool? ?? false,
      maxSeniors: json['maxSeniors'] as int? ?? 1,
      active: json['active'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'priceInr': priceInr,
      'period': period,
      'features': features,
      'isPopular': isPopular,
      'maxSeniors': maxSeniors,
      'active': active,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
