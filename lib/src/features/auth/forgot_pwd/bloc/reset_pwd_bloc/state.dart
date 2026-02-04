import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/auth/data/models/forgot_pwd_model.dart';

abstract class ResetPasswordState extends Equatable {
  const ResetPasswordState();

  @override
  List<Object?> get props => [];
}

class ResetPasswordInitial extends ResetPasswordState {
  final String? otpError;
  final String? passwordError;
  final String? confirmPasswordError;
  final bool obscurePassword;
  final bool obscureConfirmPassword;

  const ResetPasswordInitial({
    this.otpError,
    this.passwordError,
    this.confirmPasswordError,
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
  });

  ResetPasswordInitial copyWith({
    String? otpError,
    String? passwordError,
    String? confirmPasswordError,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
    bool clearOtpError = false,
    bool clearPasswordError = false,
    bool clearConfirmPasswordError = false,
  }) {
    return ResetPasswordInitial(
      otpError: clearOtpError ? null : otpError ?? this.otpError,
      passwordError: clearPasswordError
          ? null
          : passwordError ?? this.passwordError,
      confirmPasswordError: clearConfirmPasswordError
          ? null
          : confirmPasswordError ?? this.confirmPasswordError,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
    );
  }

  @override
  List<Object?> get props => [
    otpError,
    passwordError,
    confirmPasswordError,
    obscurePassword,
    obscureConfirmPassword,
  ];
}

class ResetPasswordLoading extends ResetPasswordState {
  final bool obscurePassword;
  final bool obscureConfirmPassword;

  const ResetPasswordLoading({
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
  });

  @override
  List<Object?> get props => [obscurePassword, obscureConfirmPassword];
}

class ResetPasswordValidation extends ResetPasswordState {
  final String? otpError;
  final String? passwordError;
  final String? confirmPasswordError;
  final bool obscurePassword;
  final bool obscureConfirmPassword;

  const ResetPasswordValidation({
    this.otpError,
    this.passwordError,
    this.confirmPasswordError,
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
  });

  @override
  List<Object?> get props => [
    otpError,
    passwordError,
    confirmPasswordError,
    obscurePassword,
    obscureConfirmPassword,
  ];
}

class ResetPasswordSuccess extends ResetPasswordState {
  final ResetPasswordResponse response;
  final String message;

  const ResetPasswordSuccess({required this.response, required this.message});

  @override
  List<Object?> get props => [response, message];
}

enum ResetPasswordErrorType {
  network,
  timeout,
  validation,
  server,
  general,
  invalidOtp,
}

class ResetPasswordError extends ResetPasswordState {
  final String error;
  final ResetPasswordErrorType errorType;
  final bool obscurePassword;
  final bool obscureConfirmPassword;

  const ResetPasswordError({
    required this.error,
    this.errorType = ResetPasswordErrorType.general,
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
  });

  ResetPasswordError copyWith({
    bool? obscurePassword,
    bool? obscureConfirmPassword,
  }) {
    return ResetPasswordError(
      error: error,
      errorType: errorType,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
    );
  }

  @override
  List<Object?> get props => [
    error,
    errorType,
    obscurePassword,
    obscureConfirmPassword,
  ];
}
