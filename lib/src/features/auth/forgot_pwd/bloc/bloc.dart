import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/auth/data/repo/forgot_pwd_repo.dart';

import 'package:sandwich_ai/src/features/auth/forgot_pwd/bloc/event.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/bloc/state.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final ForgotPasswordRepositoryInterface _repository;

  ForgotPasswordBloc({required ForgotPasswordRepositoryInterface repository})
    : _repository = repository,
      super(const ForgotPasswordInitial()) {
    on<SendOTP>(_onSendOTP);
    on<ValidateForgotEmail>(_onValidateEmail);
    on<ResetForgotPasswordState>(_onResetState);
  }

  /// Handles sending OTP
  Future<void> _onSendOTP(
    SendOTP event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    try {
      // Validate email before making API call
      final emailError = _validateEmail(event.request.email);

      if (emailError != null) {
        emit(ForgotPasswordValidation(emailError: emailError));
        return;
      }

      emit(const ForgotPasswordLoading());

      // Make API call
      final response = await _repository.forgotPassword(event.request);

      await response.when(
        success: (data) async {
          try {
            if (!data.isValid) {
              emit(
                const ForgotPasswordError(
                  error: 'Invalid response. Please try again.',
                  errorType: ForgotPasswordErrorType.validation,
                ),
              );
              return;
            }

            emit(
              ForgotPasswordSuccess(
                response: data,
                message: data.message,
                email: event.request.email,
                organizationCode: event.request.organizationCode,
              ),
            );
          } catch (e) {
            emit(
              const ForgotPasswordError(
                error: 'Failed to process response. Please try again.',
                errorType: ForgotPasswordErrorType.general,
              ),
            );
          }
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            ForgotPasswordError(error: error.toString(), errorType: errorType),
          );
        },
      );
    } catch (e) {
      emit(
        const ForgotPasswordError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: ForgotPasswordErrorType.general,
        ),
      );
    }
  }

  /// Validates email field
  void _onValidateEmail(
    ValidateForgotEmail event,
    Emitter<ForgotPasswordState> emit,
  ) {
    if (state is! ForgotPasswordInitial) return;

    final currentState = state as ForgotPasswordInitial;
    final error = _validateEmail(event.email);

    emit(
      currentState.copyWith(emailError: error, clearEmailError: error == null),
    );
  }

  /// Resets state
  void _onResetState(
    ResetForgotPasswordState event,
    Emitter<ForgotPasswordState> emit,
  ) {
    emit(const ForgotPasswordInitial());
  }

  /// Email validation logic
  String? _validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Determines error type from error message
  ForgotPasswordErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return ForgotPasswordErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return ForgotPasswordErrorType.timeout;
    }

    if (lowercaseError.contains('invalid') ||
        lowercaseError.contains('not found') ||
        lowercaseError.contains('email')) {
      return ForgotPasswordErrorType.validation;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return ForgotPasswordErrorType.server;
    }

    return ForgotPasswordErrorType.general;
  }
}
