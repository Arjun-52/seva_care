class UpgradeOrderModel {
  final String id;
  final int amount;
  final String currency;

  UpgradeOrderModel({
    required this.id,
    required this.amount,
    required this.currency,
  });

  factory UpgradeOrderModel.fromJson(Map<String, dynamic> json) {
    return UpgradeOrderModel(
      id: json['id'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
    };
  }
}

class UpgradePlanModel {
  final String name;
  final int price;

  UpgradePlanModel({
    required this.name,
    required this.price,
  });

  factory UpgradePlanModel.fromJson(Map<String, dynamic> json) {
    return UpgradePlanModel(
      name: json['name'] as String? ?? '',
      price: json['price'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
    };
  }
}

class UpgradeSubscriptionModel {
  final String subscriptionId;
  final String paymentId;
  final UpgradeOrderModel order;
  final UpgradePlanModel plan;

  UpgradeSubscriptionModel({
    required this.subscriptionId,
    required this.paymentId,
    required this.order,
    required this.plan,
  });

  factory UpgradeSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return UpgradeSubscriptionModel(
      subscriptionId: json['subscriptionId'] as String? ?? '',
      paymentId: json['paymentId'] as String? ?? '',
      order: json['order'] != null
          ? UpgradeOrderModel.fromJson(json['order'] as Map<String, dynamic>)
          : UpgradeOrderModel(id: '', amount: 0, currency: 'INR'),
      plan: json['plan'] != null
          ? UpgradePlanModel.fromJson(json['plan'] as Map<String, dynamic>)
          : UpgradePlanModel(name: '', price: 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscriptionId': subscriptionId,
      'paymentId': paymentId,
      'order': order.toJson(),
      'plan': plan.toJson(),
    };
  }
}
