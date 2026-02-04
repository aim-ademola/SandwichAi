// lib/src/features/auth/bloc/login_event.dart

import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/auth/data/models/login_model.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initiate login
class LoginUser extends LoginEvent {
  final LoginRequest request;

  const LoginUser({required this.request});

  @override
  List<Object?> get props => [request];
}

/// Event to validate email field
class ValidateEmail extends LoginEvent {
  final String email;

  const ValidateEmail({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Event to validate password field
class ValidatePassword extends LoginEvent {
  final String password;

  const ValidatePassword({required this.password});

  @override
  List<Object?> get props => [password];
}

/// Event to validate organization code field
class ValidateOrgCode extends LoginEvent {
  final String orgCode;

  const ValidateOrgCode({required this.orgCode});

  @override
  List<Object?> get props => [orgCode];
}

/// Event to toggle password visibility
class TogglePasswordVisibility extends LoginEvent {
  const TogglePasswordVisibility();
}

/// Event to toggle remember me
class ToggleRememberMe extends LoginEvent {
  final bool value;

  const ToggleRememberMe({required this.value});

  @override
  List<Object?> get props => [value];
}

/// Event to reset login state
class ResetLoginState extends LoginEvent {
  const ResetLoginState();
}

/// Event to logout
class LogoutUser extends LoginEvent {
  const LogoutUser();
}
