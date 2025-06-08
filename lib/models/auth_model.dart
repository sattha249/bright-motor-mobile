class AuthResponse {
  final String type;
  final String token;

  AuthResponse({
    required this.type,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      type: json['type'] as String,
      token: json['token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'token': token,
    };
  }
} 