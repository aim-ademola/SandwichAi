import 'package:equatable/equatable.dart';

enum ChangePasswordErrorType {
  general,
  network,
  timeout,
  server,
  validation,
  unauthorized,
}

abstract class ChangePasswordState extends Equatable {
  const ChangePasswordState();

  @override
  List<Object?> get props => [];
}

class ChangePasswordInitial extends ChangePasswordState {
  final bool obscureCurrentPassword;
  final bool obscureNewPassword;
  final bool obscureConfirmPassword;
  final String? currentPasswordError;
  final String? newPasswordError;
  final String? confirmPasswordError;

  const ChangePasswordInitial({
    this.obscureCurrentPassword = true,
    this.obscureNewPassword = true,
    this.obscureConfirmPassword = true,
    this.currentPasswordError,
    this.newPasswordError,
    this.confirmPasswordError,
  });

  ChangePasswordInitial copyWith({
    bool? obscureCurrentPassword,
    bool? obscureNewPassword,
    bool? obscureConfirmPassword,
    String? currentPasswordError,
    String? newPasswordError,
    String? confirmPasswordError,
    bool clearCurrentPasswordError = false,
    bool clearNewPasswordError = false,
    bool clearConfirmPasswordError = false,
  }) {
    return ChangePasswordInitial(
      obscureCurrentPassword:
          obscureCurrentPassword ?? this.obscureCurrentPassword,
      obscureNewPassword: obscureNewPassword ?? this.obscureNewPassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
      currentPasswordError: clearCurrentPasswordError
          ? null
          : currentPasswordError ?? this.currentPasswordError,
      newPasswordError: clearNewPasswordError
          ? null
          : newPasswordError ?? this.newPasswordError,
      confirmPasswordError: clearConfirmPasswordError
          ? null
          : confirmPasswordError ?? this.confirmPasswordError,
    );
  }

  @override
  List<Object?> get props => [
    obscureCurrentPassword,
    obscureNewPassword,
    obscureConfirmPassword,
    currentPasswordError,
    newPasswordError,
    confirmPasswordError,
  ];
}

class ChangePasswordLoading extends ChangePasswordState {
  final bool obscureCurrentPassword;
  final bool obscureNewPassword;
  final bool obscureConfirmPassword;

  const ChangePasswordLoading({
    this.obscureCurrentPassword = true,
    this.obscureNewPassword = true,
    this.obscureConfirmPassword = true,
  });

  @override
  List<Object?> get props => [
    obscureCurrentPassword,
    obscureNewPassword,
    obscureConfirmPassword,
  ];
}

class ChangePasswordValidation extends ChangePasswordState {
  final String? currentPasswordError;
  final String? newPasswordError;
  final String? confirmPasswordError;
  final bool obscureCurrentPassword;
  final bool obscureNewPassword;
  final bool obscureConfirmPassword;

  const ChangePasswordValidation({
    this.currentPasswordError,
    this.newPasswordError,
    this.confirmPasswordError,
    this.obscureCurrentPassword = true,
    this.obscureNewPassword = true,
    this.obscureConfirmPassword = true,
  });

  @override
  List<Object?> get props => [
    currentPasswordError,
    newPasswordError,
    confirmPasswordError,
    obscureCurrentPassword,
    obscureNewPassword,
    obscureConfirmPassword,
  ];
}

class ChangePasswordSuccess extends ChangePasswordState {
  final String message;

  const ChangePasswordSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class ChangePasswordError extends ChangePasswordState {
  final String error;
  final ChangePasswordErrorType errorType;
  final bool obscureCurrentPassword;
  final bool obscureNewPassword;
  final bool obscureConfirmPassword;

  const ChangePasswordError({
    required this.error,
    this.errorType = ChangePasswordErrorType.general,
    this.obscureCurrentPassword = true,
    this.obscureNewPassword = true,
    this.obscureConfirmPassword = true,
  });

  ChangePasswordError copyWith({
    String? error,
    ChangePasswordErrorType? errorType,
    bool? obscureCurrentPassword,
    bool? obscureNewPassword,
    bool? obscureConfirmPassword,
  }) {
    return ChangePasswordError(
      error: error ?? this.error,
      errorType: errorType ?? this.errorType,
      obscureCurrentPassword:
          obscureCurrentPassword ?? this.obscureCurrentPassword,
      obscureNewPassword: obscureNewPassword ?? this.obscureNewPassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
    );
  }

  @override
  List<Object?> get props => [
    error,
    errorType,
    obscureCurrentPassword,
    obscureNewPassword,
    obscureConfirmPassword,
  ];
}
