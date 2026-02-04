import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/auth/data/models/forgot_pwd_model.dart';

abstract class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();

  @override
  List<Object?> get props => [];
}

class SendOTP extends ForgotPasswordEvent {
  final ForgotPasswordRequest request;

  const SendOTP({required this.request});

  @override
  List<Object?> get props => [request];
}

class ValidateForgotEmail extends ForgotPasswordEvent {
  final String email;

  const ValidateForgotEmail({required this.email});

  @override
  List<Object?> get props => [email];
}

class ResetForgotPasswordState extends ForgotPasswordEvent {
  const ResetForgotPasswordState();
}
