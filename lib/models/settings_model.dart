class SettingsModel {
  final UserSettings settings;
  final UserIntegrations integrations;

  SettingsModel({
    required this.settings,
    required this.integrations,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      settings: UserSettings.fromJson(json['settings'] as Map<String, dynamic>? ?? {}),
      integrations: UserIntegrations.fromJson(json['integrations'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'settings': settings.toJson(),
      'integrations': integrations.toJson(),
    };
  }
}

class UserSettings {
  final String timezone;
  final String language;

  UserSettings({
    required this.timezone,
    required this.language,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      timezone: json['timezone'] as String? ?? '',
      language: json['language'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timezone': timezone,
      'language': language,
    };
  }
}

class UserIntegrations {
  final bool googleCalendar;

  UserIntegrations({
    required this.googleCalendar,
  });

  factory UserIntegrations.fromJson(Map<String, dynamic> json) {
    return UserIntegrations(
      googleCalendar: json['googleCalendar'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'googleCalendar': googleCalendar,
    };
  }
}
