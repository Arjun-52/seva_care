class SeniorVitalHistoryModel {
  final String id;
  final int? bpSystolic;
  final int? bpDiastolic;
  final int? spo2;
  final int? heartRate;
  final double? temperature;
  final String? mood;
  final String? source;
  final DateTime recordedAt;

  SeniorVitalHistoryModel({
    required this.id,
    this.bpSystolic,
    this.bpDiastolic,
    this.spo2,
    this.heartRate,
    this.temperature,
    this.mood,
    this.source,
    required this.recordedAt,
  });

  factory SeniorVitalHistoryModel.fromJson(Map<String, dynamic> json) {
    return SeniorVitalHistoryModel(
      id: json['id'] as String? ?? '',
      bpSystolic: json['bpSystolic'] as int?,
      bpDiastolic: json['bpDiastolic'] as int?,
      spo2: json['spo2'] as int?,
      heartRate: json['heartRate'] as int?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      mood: json['mood'] as String?,
      source: json['source'] as String?,
      recordedAt: json['recordedAt'] != null
          ? DateTime.tryParse(json['recordedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
