class Medicine {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final String scheduledTime;
  final String? prescribedBy;
  final String? notes;
  final bool taken;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.scheduledTime,
    this.prescribedBy,
    this.notes,
    required this.taken,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      scheduledTime: json['scheduledTime'] as String? ?? '',
      prescribedBy: json['prescribedBy'] as String?,
      notes: json['notes'] as String?,
      taken: json['taken'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'scheduledTime': scheduledTime,
      'prescribedBy': prescribedBy,
      'notes': notes,
      'taken': taken,
    };
  }
}

class MedicinesResponse {
  final bool success;
  final String message;
  final List<Medicine> medicines;
  final List<dynamic> errors;
  final Map<String, dynamic> meta;

  MedicinesResponse({
    required this.success,
    required this.message,
    required this.medicines,
    required this.errors,
    required this.meta,
  });

  factory MedicinesResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataList = json['data'] as List<dynamic>? ?? [];
    final medicinesList = dataList.map((e) => Medicine.fromJson(e as Map<String, dynamic>)).toList();
    return MedicinesResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      medicines: medicinesList,
      errors: json['errors'] as List<dynamic>? ?? [],
      meta: json['meta'] as Map<String, dynamic>? ?? {},
    );
  }
}
