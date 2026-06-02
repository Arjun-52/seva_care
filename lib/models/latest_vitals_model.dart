class LatestVitalsModel {
  final String id;
  final String seniorId;
  final int? bpSystolic;
  final int? bpDiastolic;
  final int? spo2;
  final int? heartRate;
  final double? temperature;
  final double? bloodSugar;
  final String? mood;
  final String? notes;
  final String? recordedBy;
  final String? source;
  final String? deviceId;
  final DateTime recordedAt;
  final DateTime createdAt;

  LatestVitalsModel({
    required this.id,
    required this.seniorId,
    this.bpSystolic,
    this.bpDiastolic,
    this.spo2,
    this.heartRate,
    this.temperature,
    this.bloodSugar,
    this.mood,
    this.notes,
    this.recordedBy,
    this.source,
    this.deviceId,
    required this.recordedAt,
    required this.createdAt,
  });

  factory LatestVitalsModel.fromJson(Map<String, dynamic> json) {
    return LatestVitalsModel(
      id: json['id'] as String? ?? '',
      seniorId: json['seniorId'] as String? ?? '',
      bpSystolic: json['bpSystolic'] as int?,
      bpDiastolic: json['bpDiastolic'] as int?,
      spo2: json['spo2'] as int?,
      heartRate: json['heartRate'] as int?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      bloodSugar: (json['bloodSugar'] as num?)?.toDouble(),
      mood: json['mood'] as String?,
      notes: json['notes'] as String?,
      recordedBy: json['recordedBy'] as String?,
      source: json['source'] as String?,
      deviceId: json['deviceId'] as String?,
      recordedAt: json['recordedAt'] != null
          ? DateTime.tryParse(json['recordedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
