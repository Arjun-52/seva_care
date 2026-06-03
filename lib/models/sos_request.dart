class SosRequest {
  final String seniorId;
  final String triggeredBy;

  SosRequest({
    required this.seniorId,
    this.triggeredBy = 'family',
  });

  Map<String, dynamic> toJson() {
    return {
      'seniorId': seniorId,
      'triggeredBy': triggeredBy,
    };
  }
}
