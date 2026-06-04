class Senior {
  final String id, name, zone, city, tier, status, mobility, careAide, avatar, phone;
  final int age;
  final String gender;
  final List<String> conditions;
  final String? nriContact;
  final Map<String, dynamic> vitals;
  final DateTime lastCheckIn;

  Senior({
    required this.id, required this.name, required this.age, required this.gender,
    required this.zone, required this.city, required this.tier, required this.status,
    required this.conditions, required this.mobility, required this.careAide,
    required this.avatar, required this.phone, required this.vitals,
    required this.lastCheckIn, this.nriContact,
  });

  factory Senior.fromJson(Map<String, dynamic> json) {
    String zoneVal = '';
    if (json['zone'] is Map) {
      zoneVal = json['zone']['name'] as String? ?? '';
    } else if (json['zone'] is String) {
      zoneVal = json['zone'] as String;
    }

    String careAideVal = '';
    if (json['careAide'] is Map) {
      careAideVal = json['careAide']['name'] as String? ?? '';
    } else if (json['careAide'] is String) {
      careAideVal = json['careAide'] as String;
    }

    String? nriContactVal;
    if (json['nriContact'] is Map) {
      nriContactVal = json['nriContact']['name'] as String? ?? '';
    } else if (json['nriContact'] is String) {
      nriContactVal = json['nriContact'] as String;
    }

    return Senior(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      gender: json['gender'] as String? ?? '',
      zone: zoneVal,
      city: json['city'] as String? ?? '',
      tier: json['tier'] as String? ?? '',
      status: json['status'] as String? ?? '',
      conditions: (json['conditions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      mobility: json['mobility'] as String? ?? '',
      careAide: careAideVal,
      avatar: json['avatar'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      vitals: json['vitals'] as Map<String, dynamic>? ?? {},
      lastCheckIn: json['lastCheckIn'] != null
          ? DateTime.tryParse(json['lastCheckIn'].toString()) ?? DateTime.now()
          : DateTime.now(),
      nriContact: nriContactVal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'zone': zone,
      'city': city,
      'tier': tier,
      'status': status,
      'conditions': conditions,
      'mobility': mobility,
      'careAide': careAide,
      'avatar': avatar,
      'phone': phone,
      'vitals': vitals,
      'lastCheckIn': lastCheckIn.toIso8601String(),
      'nriContact': nriContact,
    };
  }
}

class CareLog {
  final int id;
  final String seniorId, time, activity, who, status, type, notes;

  CareLog({
    required this.id, required this.seniorId, required this.time,
    required this.activity, required this.who, required this.status,
    required this.type, required this.notes,
  });
}

class EmergencyAlert {
  final String id, seniorId, seniorName, type, severity, zone, city, status, responder;
  final String? eta;
  final DateTime time;

  EmergencyAlert({
    required this.id, required this.seniorId, required this.seniorName,
    required this.type, required this.severity, required this.time,
    required this.zone, required this.city, required this.status,
    required this.responder, this.eta,
  });
}

class Medicine {
  final String id, name, dosage, frequency, time, seniorId;
  final bool taken;
  final String? notes;

  Medicine({
    required this.id, required this.name, required this.dosage,
    required this.frequency, required this.time, required this.seniorId,
    this.taken = false, this.notes,
  });
}

class SevaNotification {
  final String id, title, body, type;
  final DateTime time;
  final bool read;

  SevaNotification({
    required this.id, required this.title, required this.body,
    required this.type, required this.time, this.read = false,
  });
}

class SevaDocument {
  final String id, name, category, uploadedBy;
  final DateTime uploadDate;
  final String size;
  final String? url;

  SevaDocument({
    required this.id, required this.name, required this.category,
    required this.uploadedBy, required this.uploadDate, required this.size,
    this.url,
  });
}

class SubscriptionPlan {
  final String id, name, price, period;
  final List<String> features;
  final bool isCurrent, isPopular;
  final int maxSeniors;
  final bool active;
  final String createdAt;

  SubscriptionPlan({
    required this.id, required this.name, required this.price,
    required this.period, required this.features,
    this.isCurrent = false, this.isPopular = false,
    this.maxSeniors = 1,
    this.active = true,
    this.createdAt = '',
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    final priceInr = json['priceInr'] as int? ?? 0;
    final apiPeriod = json['period'] as String? ?? 'monthly';
    final displayPeriod = apiPeriod.toLowerCase() == 'monthly' ? ' /month' : ' /$apiPeriod';

    return SubscriptionPlan(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: '₹$priceInr',
      period: displayPeriod,
      features: (json['features'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isCurrent: false, // will be evaluated dynamically based on current user plan, or defaults to false
      isPopular: json['isPopular'] as bool? ?? false,
      maxSeniors: json['maxSeniors'] as int? ?? 1,
      active: json['active'] as bool? ?? true,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'period': period,
      'features': features,
      'isCurrent': isCurrent,
      'isPopular': isPopular,
      'maxSeniors': maxSeniors,
      'active': active,
      'createdAt': createdAt,
    };
  }
}

class EmergencyContact {
  final String name, relation, phone, avatar;
  final bool isPrimary;

  EmergencyContact({
    required this.name, required this.relation, required this.phone,
    required this.avatar, this.isPrimary = false,
  });
}

class IoTDevice {
  final String id, name, type, status;
  final int battery;
  final String? lastReading;

  IoTDevice({
    required this.id, required this.name, required this.type,
    required this.status, required this.battery, this.lastReading,
  });
}

class MockData {
  static final seniors = [
    Senior(id: "SR001", name: "Kamla Devi Sharma", age: 78, gender: "Female",
      zone: "Vaishali Nagar", city: "Jaipur", tier: "BPL Subsidized", status: "stable",
      conditions: ["Diabetes Type 2", "Hypertension"], mobility: "Immobile",
      careAide: "Priya Meena", nriContact: "Rajesh Sharma (USA)",
      lastCheckIn: DateTime(2025, 5, 20, 7, 30), avatar: "KD", phone: "+91 94XXX XXXXX",
      vitals: {"bp": "130/82", "spo2": 96, "heartRate": 72, "temp": 98.2}),
    Senior(id: "SR002", name: "Raghunath Prasad Joshi", age: 82, gender: "Male",
      zone: "Civil Lines", city: "Jaipur", tier: "NRI Full Guardian", status: "attention",
      conditions: ["COPD", "Arthritis"], mobility: "Limited",
      careAide: "Sunita Yadav", nriContact: "Vikram Joshi (Dubai)",
      lastCheckIn: DateTime(2025, 5, 20, 8, 15), avatar: "RP", phone: "+91 98XXX XXXXX",
      vitals: {"bp": "145/90", "spo2": 93, "heartRate": 88, "temp": 98.6}),
    Senior(id: "SR003", name: "Saraswati Bai Patel", age: 75, gender: "Female",
      zone: "Mansarovar", city: "Jaipur", tier: "Care Plus", status: "stable",
      conditions: ["Osteoporosis"], mobility: "Assisted",
      careAide: "Rekha Kumari", nriContact: "Amit Patel (UK)",
      lastCheckIn: DateTime(2025, 5, 20, 7, 45), avatar: "SB", phone: "+91 97XXX XXXXX",
      vitals: {"bp": "125/78", "spo2": 97, "heartRate": 68, "temp": 98.4}),
    Senior(id: "SR004", name: "Venkateshwara Rao", age: 80, gender: "Male",
      zone: "Jubilee Hills", city: "Hyderabad", tier: "NRI Full Guardian", status: "critical",
      conditions: ["Heart Disease", "Diabetes Type 2", "CKD Stage 3"], mobility: "Immobile",
      careAide: "Lakshmi Reddy", nriContact: "Srinivas Rao (USA)",
      lastCheckIn: DateTime(2025, 5, 20, 6, 0), avatar: "VR", phone: "+91 96XXX XXXXX",
      vitals: {"bp": "158/95", "spo2": 91, "heartRate": 95, "temp": 99.1}),
  ];

  static final careLogs = [
    CareLog(id: 1, seniorId: "SR001", time: "07:30 AM", activity: "Morning wellness call",
      who: "Priya Meena", status: "completed", type: "check-in", notes: "Cheerful mood. Slept well."),
    CareLog(id: 2, seniorId: "SR001", time: "08:00 AM", activity: "Morning medicines",
      who: "Priya Meena", status: "completed", type: "medicine", notes: "Metformin 500mg, Amlodipine 5mg"),
    CareLog(id: 3, seniorId: "SR001", time: "09:30 AM", activity: "Sponge bath & oral care",
      who: "Priya Meena", status: "completed", type: "hygiene", notes: "Full routine completed"),
    CareLog(id: 4, seniorId: "SR001", time: "11:30 AM", activity: "Breakfast - Poha & chai",
      who: "Priya Meena", status: "completed", type: "meal", notes: "Good appetite"),
    CareLog(id: 5, seniorId: "SR001", time: "12:00 PM", activity: "Physiotherapy session",
      who: "Physio Rajan", status: "completed", type: "therapy", notes: "Good progress"),
    CareLog(id: 6, seniorId: "SR001", time: "01:00 PM", activity: "Vitals check - BP & SpO2",
      who: "Priya Meena", status: "completed", type: "vitals", notes: "BP 130/82, SpO2 96%"),
    CareLog(id: 7, seniorId: "SR001", time: "02:00 PM", activity: "Rest period - IoT monitoring",
      who: "Automated", status: "active", type: "monitoring", notes: "Sensors active"),
    CareLog(id: 8, seniorId: "SR001", time: "05:00 PM", activity: "Evening visit - fluids",
      who: "Volunteer", status: "pending", type: "check-in", notes: ""),
    CareLog(id: 9, seniorId: "SR001", time: "07:00 PM", activity: "Night medicines",
      who: "Priya Meena", status: "pending", type: "medicine", notes: ""),
  ];

  static final emergencyAlerts = [
    EmergencyAlert(id: "EM001", seniorId: "SR004", seniorName: "Venkateshwara Rao",
      type: "Fall Detected", severity: "critical", time: DateTime(2025, 5, 20, 5, 45),
      zone: "Jubilee Hills", city: "Hyderabad", status: "responding",
      responder: "Lakshmi Reddy", eta: "8 min"),
    EmergencyAlert(id: "EM002", seniorId: "SR002", seniorName: "Raghunath Prasad Joshi",
      type: "High BP Alert", severity: "warning", time: DateTime(2025, 5, 20, 8, 15),
      zone: "Civil Lines", city: "Jaipur", status: "monitoring",
      responder: "Sunita Yadav"),
    EmergencyAlert(id: "EM003", seniorId: "SR006", seniorName: "Mohan Lal Gupta",
      type: "Wandering Alert", severity: "warning", time: DateTime(2025, 5, 20, 6, 30),
      zone: "Jhotwara", city: "Jaipur", status: "resolved",
      responder: "Priya Meena"),
  ];

  static final vitalsHistory = [
    {"time": "6 AM", "bp_sys": 128.0, "bp_dia": 80.0, "spo2": 97.0, "hr": 70.0},
    {"time": "8 AM", "bp_sys": 132.0, "bp_dia": 84.0, "spo2": 96.0, "hr": 72.0},
    {"time": "10 AM", "bp_sys": 126.0, "bp_dia": 78.0, "spo2": 97.0, "hr": 68.0},
    {"time": "12 PM", "bp_sys": 130.0, "bp_dia": 82.0, "spo2": 96.0, "hr": 74.0},
    {"time": "2 PM", "bp_sys": 134.0, "bp_dia": 86.0, "spo2": 95.0, "hr": 76.0},
    {"time": "4 PM", "bp_sys": 128.0, "bp_dia": 80.0, "spo2": 97.0, "hr": 71.0},
    {"time": "6 PM", "bp_sys": 130.0, "bp_dia": 82.0, "spo2": 96.0, "hr": 73.0},
  ];

  static final medicines = [
    Medicine(id: "M001", name: "Metformin", dosage: "500mg", frequency: "Twice daily",
      time: "08:00 AM", seniorId: "SR001", taken: true, notes: "Take after breakfast"),
    Medicine(id: "M002", name: "Amlodipine", dosage: "5mg", frequency: "Once daily",
      time: "08:00 AM", seniorId: "SR001", taken: true, notes: "For blood pressure"),
    Medicine(id: "M003", name: "Metformin", dosage: "500mg", frequency: "Twice daily",
      time: "01:00 PM", seniorId: "SR001", taken: false, notes: "Take after lunch"),
    Medicine(id: "M004", name: "Clopidogrel", dosage: "75mg", frequency: "Once daily",
      time: "07:00 PM", seniorId: "SR001", taken: false, notes: "Blood thinner"),
    Medicine(id: "M005", name: "Calcium + Vitamin D", dosage: "500mg", frequency: "Once daily",
      time: "07:00 PM", seniorId: "SR001", taken: false, notes: "For bone health"),
    Medicine(id: "M006", name: "Pantoprazole", dosage: "40mg", frequency: "Once daily",
      time: "07:30 AM", seniorId: "SR001", taken: true, notes: "Before breakfast"),
  ];

  static final notifications = [
    SevaNotification(id: "N001", title: "Vitals Recorded", body: "BP 130/82, SpO2 96% — All normal for Kamla Devi.",
      type: "vitals", time: DateTime(2025, 5, 20, 13, 5)),
    SevaNotification(id: "N002", title: "Physiotherapy Complete", body: "Today's session went well. Good range of motion improvement.",
      type: "care", time: DateTime(2025, 5, 20, 12, 15)),
    SevaNotification(id: "N003", title: "Morning Medicines Given", body: "Metformin 500mg and Amlodipine 5mg administered on time.",
      type: "medicine", time: DateTime(2025, 5, 20, 8, 5)),
    SevaNotification(id: "N004", title: "Fall Alert - Resolved", body: "Venkateshwara Rao - Fall detected by smartwatch. Care aide responded in 8 min.",
      type: "emergency", time: DateTime(2025, 5, 20, 5, 50), read: true),
    SevaNotification(id: "N005", title: "Weekly Health Report", body: "Your mother's weekly health summary is ready. Tap to view.",
      type: "report", time: DateTime(2025, 5, 19, 18, 0), read: true),
    SevaNotification(id: "N006", title: "IoT Sensor Update", body: "Gas sensor battery replaced. All sensors online.",
      type: "iot", time: DateTime(2025, 5, 19, 10, 30), read: true),
    SevaNotification(id: "N007", title: "Care Aide Check-in", body: "Priya Meena started morning visit at 7:30 AM.",
      type: "care", time: DateTime(2025, 5, 20, 7, 30)),
    SevaNotification(id: "N008", title: "Payment Received", body: "Monthly subscription of ₹2,999 processed successfully.",
      type: "payment", time: DateTime(2025, 5, 15, 9, 0), read: true),
  ];

  static final documents = [
    SevaDocument(id: "D001", name: "Aadhaar Card", category: "Identity",
      uploadedBy: "Rajesh Sharma", uploadDate: DateTime(2025, 1, 15), size: "2.1 MB"),
    SevaDocument(id: "D002", name: "Blood Test Report - May", category: "Medical Reports",
      uploadedBy: "Priya Meena", uploadDate: DateTime(2025, 5, 10), size: "1.4 MB"),
    SevaDocument(id: "D003", name: "Diabetes Treatment Plan", category: "Treatment Plans",
      uploadedBy: "Dr. Agarwal", uploadDate: DateTime(2025, 3, 22), size: "890 KB"),
    SevaDocument(id: "D004", name: "Insurance Policy", category: "Insurance",
      uploadedBy: "Rajesh Sharma", uploadDate: DateTime(2025, 2, 1), size: "3.2 MB"),
    SevaDocument(id: "D005", name: "X-Ray - Left Knee", category: "Medical Reports",
      uploadedBy: "City Hospital", uploadDate: DateTime(2025, 4, 5), size: "5.6 MB"),
    SevaDocument(id: "D006", name: "Monthly Vitals Report - Apr", category: "Reports",
      uploadedBy: "Seva System", uploadDate: DateTime(2025, 4, 30), size: "1.1 MB"),
    SevaDocument(id: "D007", name: "Prescription - Dr. Agarwal", category: "Prescriptions",
      uploadedBy: "Priya Meena", uploadDate: DateTime(2025, 5, 8), size: "420 KB"),
  ];

  static final subscriptionPlans = [
    SubscriptionPlan(id: "P001", name: "Basic Connect", price: "₹2,999", period: "/month",
      isCurrent: true,
      features: [
        "Daily wellness call",
        "Weekly vitals report",
        "IoT basic monitoring",
        "Emergency SOS",
        "Monthly care summary",
      ]),
    SubscriptionPlan(id: "P002", name: "Care Plus", price: "₹4,999", period: "/month",
      isPopular: true,
      features: [
        "Everything in Basic Connect",
        "Daily aide visits",
        "Weekly video reports",
        "Real-time vitals dashboard",
        "Document vault (5GB)",
        "Priority emergency response",
        "Physiotherapy sessions (2/week)",
      ]),
    SubscriptionPlan(id: "P003", name: "Full Guardian", price: "₹7,999", period: "/month",
      features: [
        "Everything in Care Plus",
        "Dedicated care aide",
        "24/7 IoT monitoring",
        "Unlimited video calls",
        "Document vault (unlimited)",
        "Specialist consultations",
        "Night care support",
        "Family coordination calls",
      ]),
  ];

  static final emergencyContacts = [
    EmergencyContact(name: "Rajesh Sharma", relation: "Son (NRI)", phone: "+1 (201) 555-0148",
      avatar: "RS", isPrimary: true),
    EmergencyContact(name: "Priya Meena", relation: "Care Aide", phone: "+91 94XXX XXXXX",
      avatar: "PM"),
    EmergencyContact(name: "Dr. R.K. Agarwal", relation: "Family Doctor", phone: "+91 98XXX XXXXX",
      avatar: "RA"),
    EmergencyContact(name: "Seva Emergency", relation: "Helpline", phone: "1800-XXX-XXXX",
      avatar: "SE"),
    EmergencyContact(name: "Sunita Sharma", relation: "Neighbour", phone: "+91 97XXX XXXXX",
      avatar: "SS"),
  ];

  static final iotDevices = [
    IoTDevice(id: "IOT001", name: "GPS Smartwatch", type: "wearable",
      status: "online", battery: 72, lastReading: "Location: Home"),
    IoTDevice(id: "IOT002", name: "BP Monitor", type: "medical",
      status: "online", battery: 85, lastReading: "130/82 mmHg"),
    IoTDevice(id: "IOT003", name: "SpO2 Sensor", type: "medical",
      status: "online", battery: 90, lastReading: "96%"),
    IoTDevice(id: "IOT004", name: "Gas/Smoke Sensor", type: "safety",
      status: "online", battery: 95, lastReading: "Normal"),
    IoTDevice(id: "IOT005", name: "Door Sensor", type: "safety",
      status: "online", battery: 88, lastReading: "Closed"),
    IoTDevice(id: "IOT006", name: "Zigbee Hub", type: "hub",
      status: "online", battery: 100, lastReading: "5 devices connected"),
  ];
}
