class VideoScheduleRequest {
  final String seniorId;
  final DateTime scheduledAt;

  VideoScheduleRequest({
    required this.seniorId,
    required this.scheduledAt,
  }) {
    if (seniorId.isEmpty) {
      throw ArgumentError('seniorId must not be empty');
    }
    if (scheduledAt.isBefore(DateTime.now())) {
      throw ArgumentError('scheduledAt must be a future date/time');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'seniorId': seniorId,
      'scheduledAt': scheduledAt.toUtc().toIso8601String(),
    };
  }
}
