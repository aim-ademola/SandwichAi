import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/auth/data/models/chnage-pwd-res.dart';

abstract class ChangePasswordEvent extends Equatable {
  const ChangePasswordEvent();

  @override
  List<Object?> get props => [];
}

class ChangePassword extends ChangePasswordEvent {
  final ChangePasswordRequest request;

  const ChangePassword({required this.request});

  @override
  List<Object?> get props => [request];
}

class ValidateCurrentPassword extends ChangePasswordEvent {
  final String password;

  const ValidateCurrentPassword({required this.password});

  @override
  List<Object?> get props => [password];
}

class ValidateNewPassword extends ChangePasswordEvent {
  final String password;

  const ValidateNewPassword({required this.password});

  @override
  List<Object?> get props => [password];
}

class ValidateConfirmPassword extends ChangePasswordEvent {
  final String password;
  final String confirmPassword;

  const ValidateConfirmPassword({
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [password, confirmPassword];
}

class ToggleCurrentPasswordVisibility extends ChangePasswordEvent {
  const ToggleCurrentPasswordVisibility();
}

class ToggleNewPasswordVisibility extends ChangePasswordEvent {
  const ToggleNewPasswordVisibility();
}

class ToggleConfirmPasswordVisibility extends ChangePasswordEvent {
  const ToggleConfirmPasswordVisibility();
}

class ResetChangePasswordState extends ChangePasswordEvent {
  const ResetChangePasswordState();
}