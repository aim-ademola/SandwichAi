import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/auth/data/models/login_model.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {
  final String? emailError;
  final String? passwordError;
  final String? orgCodeError;
  final bool obscurePassword;
  final bool rememberMe;

  const LoginInitial({
    this.emailError,
    this.passwordError,
    this.orgCodeError,
    this.obscurePassword = true,
    this.rememberMe = false,
  });

  LoginInitial copyWith({
    String? emailError,
    String? passwordError,
    String? orgCodeError,
    bool? obscurePassword,
    bool? rememberMe,
    bool clearEmailError = false,
    bool clearPasswordError = false,
    bool clearOrgCodeError = false,
  }) {
    return LoginInitial(
      emailError: clearEmailError ? null : emailError ?? this.emailError,
      passwordError: clearPasswordError
          ? null
          : passwordError ?? this.passwordError,
      orgCodeError: clearOrgCodeError
          ? null
          : orgCodeError ?? this.orgCodeError,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }

  @override
  List<Object?> get props => [
    emailError,
    passwordError,
    orgCodeError,
    obscurePassword,
    rememberMe,
  ];
}

class LoginLoading extends LoginState {
  final bool obscurePassword;
  final bool rememberMe;

  const LoginLoading({this.obscurePassword = true, this.rememberMe = false});

  @override
  List<Object?> get props => [obscurePassword, rememberMe];
}

class LoginValidation extends LoginState {
  final String? emailError;
  final String? passwordError;
  final String? orgCodeError;
  final bool obscurePassword;
  final bool rememberMe;

  const LoginValidation({
    this.emailError,
    this.passwordError,
    this.orgCodeError,
    this.obscurePassword = true,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [
    emailError,
    passwordError,
    orgCodeError,
    obscurePassword,
    rememberMe,
  ];
}

class LoginSuccess extends LoginState {
  final LoginResponse response;
  final String? message;

  const LoginSuccess({required this.response, this.message});

  @override
  List<Object?> get props => [response, message];
}

enum LoginErrorType {
  network,
  timeout,
  authentication,
  validation,
  server,
  general,
}

class LoginError extends LoginState {
  final String error;
  final LoginErrorType errorType;
  final bool obscurePassword;
  final bool rememberMe;

  const LoginError({
    required this.error,
    this.errorType = LoginErrorType.general,
    this.obscurePassword = true,
    this.rememberMe = false,
  });

  LoginError copyWith({
    String? error,
    LoginErrorType? errorType,
    bool? obscurePassword,
    bool? rememberMe,
  }) {
    return LoginError(
      error: error ?? this.error,
      errorType: errorType ?? this.errorType,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }

  @override
  List<Object?> get props => [error, errorType, obscurePassword, rememberMe];
}
