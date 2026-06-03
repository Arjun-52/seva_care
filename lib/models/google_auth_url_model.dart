class GoogleAuthUrlModel {
  final String url;

  GoogleAuthUrlModel({
    required this.url,
  });

  factory GoogleAuthUrlModel.fromJson(Map<String, dynamic> json) {
    return GoogleAuthUrlModel(
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
    };
  }
}
