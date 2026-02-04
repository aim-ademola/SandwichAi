import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/auth/data/models/forgot_pwd_model.dart';

abstract class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object?> get props => [];
}

class ForgotPasswordInitial extends ForgotPasswordState {
  final String? emailError;

  const ForgotPasswordInitial({this.emailError});

  ForgotPasswordInitial copyWith({
    String? emailError,
    bool clearEmailError = false,
  }) {
    return ForgotPasswordInitial(
      emailError: clearEmailError ? null : emailError ?? this.emailError,
    );
  }

  @override
  List<Object?> get props => [emailError];
}

class ForgotPasswordLoading extends ForgotPasswordState {
  const ForgotPasswordLoading();
}

class ForgotPasswordValidation extends ForgotPasswordState {
  final String? emailError;

  const ForgotPasswordValidation({this.emailError});

  @override
  List<Object?> get props => [emailError];
}

class ForgotPasswordSuccess extends ForgotPasswordState {
  final ForgotPasswordResponse response;
  final String message;
  final String email;
  final String organizationCode;

  const ForgotPasswordSuccess({
    required this.response,
    required this.message,
    required this.email,
    required this.organizationCode,
  });

  @override
  List<Object?> get props => [response, message, email, organizationCode];
}

enum ForgotPasswordErrorType { network, timeout, validation, server, general }

class ForgotPasswordError extends ForgotPasswordState {
  final String error;
  final ForgotPasswordErrorType errorType;

  const ForgotPasswordError({
    required this.error,
    this.errorType = ForgotPasswordErrorType.general,
  });

  @override
  List<Object?> get props => [error, errorType];
}
