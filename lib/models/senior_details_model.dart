class SeniorDetailsModel {
  final String id;
  final String? userId;
  final String name;
  final int age;
  final String gender;
  final String? phone;
  final String? zoneId;
  final String city;
  final String tier;
  final String status;
  final String mobility;
  final List<String> conditions;
  final String avatar;
  final String? address;
  final String? emergencyNotes;
  final String? careAideId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? careAide;
  final Map<String, dynamic>? zone;
  final List<FamilyLinkModel> familyLinks;
  final List<VitalModel> vitals;
  final List<MedicineDetailsModel> medicines;
  final List<IotDeviceDetailsModel> iotDevices;
  final List<EmergencyAlertDetailsModel> emergencyAlerts;

  SeniorDetailsModel({
    required this.id,
    this.userId,
    required this.name,
    required this.age,
    required this.gender,
    this.phone,
    this.zoneId,
    required this.city,
    required this.tier,
    required this.status,
    required this.mobility,
    required this.conditions,
    required this.avatar,
    this.address,
    this.emergencyNotes,
    this.careAideId,
    required this.createdAt,
    required this.updatedAt,
    this.careAide,
    this.zone,
    required this.familyLinks,
    required this.vitals,
    required this.medicines,
    required this.iotDevices,
    required this.emergencyAlerts,
  });

  factory SeniorDetailsModel.fromJson(Map<String, dynamic> json) {
    return SeniorDetailsModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String?,
      name: json['name'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      gender: json['gender'] as String? ?? '',
      phone: json['phone'] as String?,
      zoneId: json['zoneId'] as String?,
      city: json['city'] as String? ?? '',
      tier: json['tier'] as String? ?? '',
      status: json['status'] as String? ?? '',
      mobility: json['mobility'] as String? ?? '',
      conditions: (json['conditions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      avatar: json['avatar'] as String? ?? '',
      address: json['address'] as String?,
      emergencyNotes: json['emergencyNotes'] as String?,
      careAideId: json['careAideId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      careAide: json['careAide'] as Map<String, dynamic>?,
      zone: json['zone'] as Map<String, dynamic>?,
      familyLinks: (json['familyLinks'] as List?)
              ?.map((e) => FamilyLinkModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      vitals: (json['vitals'] as List?)
              ?.map((e) => VitalModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      medicines: (json['medicines'] as List?)
              ?.map((e) => MedicineDetailsModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      iotDevices: (json['iotDevices'] as List?)
              ?.map((e) => IotDeviceDetailsModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      emergencyAlerts: (json['emergencyAlerts'] as List?)
              ?.map((e) => EmergencyAlertDetailsModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class FamilyLinkModel {
  final String relation;
  final bool isPrimary;
  final FamilyUserModel user;

  FamilyLinkModel({
    required this.relation,
    required this.isPrimary,
    required this.user,
  });

  factory FamilyLinkModel.fromJson(Map<String, dynamic> json) {
    return FamilyLinkModel(
      relation: json['relation'] as String? ?? '',
      isPrimary: json['isPrimary'] as bool? ?? false,
      user: FamilyUserModel.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class FamilyUserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;

  FamilyUserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  factory FamilyUserModel.fromJson(Map<String, dynamic> json) {
    return FamilyUserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
    );
  }
}

class VitalModel {
  final int? bpSystolic;
  final int? bpDiastolic;
  final int? spo2;
  final int? heartRate;
  final double? temperature;
  final double? bloodSugar;
  final String? mood;
  final String? notes;
  final String? source;
  final DateTime recordedAt;

  VitalModel({
    this.bpSystolic,
    this.bpDiastolic,
    this.spo2,
    this.heartRate,
    this.temperature,
    this.bloodSugar,
    this.mood,
    this.notes,
    this.source,
    required this.recordedAt,
  });

  factory VitalModel.fromJson(Map<String, dynamic> json) {
    return VitalModel(
      bpSystolic: json['bpSystolic'] as int?,
      bpDiastolic: json['bpDiastolic'] as int?,
      spo2: json['spo2'] as int?,
      heartRate: json['heartRate'] as int?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      bloodSugar: (json['bloodSugar'] as num?)?.toDouble(),
      mood: json['mood'] as String?,
      notes: json['notes'] as String?,
      source: json['source'] as String?,
      recordedAt: json['recordedAt'] != null
          ? DateTime.tryParse(json['recordedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class MedicineDetailsModel {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final String time;
  final bool taken;
  final String? notes;

  MedicineDetailsModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.time,
    required this.taken,
    this.notes,
  });

  factory MedicineDetailsModel.fromJson(Map<String, dynamic> json) {
    return MedicineDetailsModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      time: json['time'] as String? ?? '',
      taken: json['taken'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }
}

class IotDeviceDetailsModel {
  final String id;
  final String name;
  final String type;
  final String status;
  final int battery;
  final String? lastReading;

  IotDeviceDetailsModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.battery,
    this.lastReading,
  });

  factory IotDeviceDetailsModel.fromJson(Map<String, dynamic> json) {
    return IotDeviceDetailsModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      battery: json['battery'] as int? ?? 0,
      lastReading: json['lastReading'] as String?,
    );
  }
}

class EmergencyAlertDetailsModel {
  final String id;
  final String type;
  final String severity;
  final String status;
  final String? responder;
  final String? eta;
  final DateTime time;

  EmergencyAlertDetailsModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.status,
    this.responder,
    this.eta,
    required this.time,
  });

  factory EmergencyAlertDetailsModel.fromJson(Map<String, dynamic> json) {
    return EmergencyAlertDetailsModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      severity: json['severity'] as String? ?? '',
      status: json['status'] as String? ?? '',
      responder: json['responder'] as String?,
      eta: json['eta'] as String?,
      time: json['time'] != null
          ? DateTime.tryParse(json['time'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
