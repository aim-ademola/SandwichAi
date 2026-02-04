class ForgotPasswordRequest {
  final String email;
  final String type;
  final String organizationCode;

  const ForgotPasswordRequest({
    required this.email,
    required this.type,
    required this.organizationCode,
  });

  Map<String, dynamic> toJson() {
    return {'email': email, 'type': type, 'organizationCode': organizationCode};
  }
}

class ForgotPasswordResponse {
  final String message;

  const ForgotPasswordResponse({required this.message});

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(message: json['message'] ?? 'OTP sent');
  }

  bool get isValid => message.isNotEmpty;
}

class ResetPasswordRequest {
  final String email;
  final String type;
  final String otp;
  final String password;
  final String organizationCode;

  const ResetPasswordRequest({
    required this.email,
    required this.type,
    required this.otp,
    required this.password,
    required this.organizationCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'type': type,
      'otp': otp,
      'password': password,
      'organizationCode': organizationCode,
    };
  }
}

class ResetPasswordResponse {
  final String message;

  const ResetPasswordResponse({required this.message});

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponse(
      message: json['message'] ?? 'Password reset successful',
    );
  }

  bool get isValid => message.isNotEmpty;
}
