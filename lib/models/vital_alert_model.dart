class VitalAlertModel {
  final String id;
  final String seniorId;
  final String alertType;
  final String title;
  final String message;
  final String severity; // critical, elevated, normal, etc.
  final String status;   // active, resolved, etc.
  final DateTime createdAt;
  final String? seniorName;

  VitalAlertModel({
    required this.id,
    required this.seniorId,
    required this.alertType,
    required this.title,
    required this.message,
    required this.severity,
    required this.status,
    required this.createdAt,
    this.seniorName,
  });

  factory VitalAlertModel.fromJson(Map<String, dynamic> json) {
    return VitalAlertModel(
      id: json['id'] as String? ?? '',
      seniorId: json['seniorId'] as String? ?? '',
      alertType: json['alertType'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      severity: json['severity'] as String? ?? 'normal',
      status: json['status'] as String? ?? 'active',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      seniorName: json['seniorName'] as String?,
    );
  }
}
