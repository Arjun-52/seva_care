class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String avatar;
  final String? country;
  final String? timezone;
  final String? language;
  final String? status;
  final String? lastLogin;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    required this.avatar,
    this.country,
    this.timezone,
    this.language,
    this.status,
    this.lastLogin,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      country: json['country'] as String?,
      timezone: json['timezone'] as String?,
      language: json['language'] as String?,
      status: json['status'] as String?,
      lastLogin: json['lastLogin'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'avatar': avatar,
      'country': country,
      'timezone': timezone,
      'language': language,
      'status': status,
      'lastLogin': lastLogin,
      'createdAt': createdAt,
    };
  }
}

class LoginResponse {
  final String token;
  final String refreshToken;
  final UserModel user;

  LoginResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : UserModel(id: '', name: '', email: '', role: '', phone: '', avatar: ''),
    );
  }
}
