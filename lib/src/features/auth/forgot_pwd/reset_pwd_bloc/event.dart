import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/auth/data/models/forgot_pwd_model.dart';

abstract class ResetPasswordEvent extends Equatable {
  const ResetPasswordEvent();

  @override
  List<Object?> get props => [];
}

class ResetPassword extends ResetPasswordEvent {
  final ResetPasswordRequest request;

  const ResetPassword({required this.request});

  @override
  List<Object?> get props => [request];
}

class ValidateOTP extends ResetPasswordEvent {
  final String otp;

  const ValidateOTP({required this.otp});

  @override
  List<Object?> get props => [otp];
}

class ValidateNewPassword extends ResetPasswordEvent {
  final String password;

  const ValidateNewPassword({required this.password});

  @override
  List<Object?> get props => [password];
}

class ValidateConfirmPassword extends ResetPasswordEvent {
  final String password;
  final String confirmPassword;

  const ValidateConfirmPassword({
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [password, confirmPassword];
}

class ToggleNewPasswordVisibility extends ResetPasswordEvent {
  const ToggleNewPasswordVisibility();
}

class ToggleConfirmPasswordVisibility extends ResetPasswordEvent {
  const ToggleConfirmPasswordVisibility();
}

class ResetResetPasswordState extends ResetPasswordEvent {
  const ResetResetPasswordState();
}
