import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/auth/data/repo/forgot_pwd_repo.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/bloc/reset_pwd_bloc/event.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/bloc/reset_pwd_bloc/state.dart';

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  final ForgotPasswordRepositoryInterface _repository;

  ResetPasswordBloc({required ForgotPasswordRepositoryInterface repository})
    : _repository = repository,
      super(const ResetPasswordInitial()) {
    on<ResetPassword>(_onResetPassword);
    on<ValidateOTP>(_onValidateOTP);
    on<ValidateNewPassword>(_onValidateNewPassword);
    on<ValidateConfirmPassword>(_onValidateConfirmPassword);
    on<ToggleNewPasswordVisibility>(_onToggleNewPasswordVisibility);
    on<ToggleConfirmPasswordVisibility>(_onToggleConfirmPasswordVisibility);
    on<ResetResetPasswordState>(_onResetState);
  }

  /// Handles password reset
  Future<void> _onResetPassword(
    ResetPassword event,
    Emitter<ResetPasswordState> emit,
  ) async {
    try {
      // Validate inputs before making API call
      final otpError = _validateOTP(event.request.otp);
      final passwordError = _validatePassword(event.request.password);

      if (otpError != null || passwordError != null) {
        emit(
          ResetPasswordValidation(
            otpError: otpError,
            passwordError: passwordError,
            obscurePassword: state is ResetPasswordInitial
                ? (state as ResetPasswordInitial).obscurePassword
                : true,
            obscureConfirmPassword: state is ResetPasswordInitial
                ? (state as ResetPasswordInitial).obscureConfirmPassword
                : true,
          ),
        );
        return;
      }

      // Preserve UI state during loading
      final currentObscurePassword = state is ResetPasswordInitial
          ? (state as ResetPasswordInitial).obscurePassword
          : true;
      final currentObscureConfirmPassword = state is ResetPasswordInitial
          ? (state as ResetPasswordInitial).obscureConfirmPassword
          : true;

      emit(
        ResetPasswordLoading(
          obscurePassword: currentObscurePassword,
          obscureConfirmPassword: currentObscureConfirmPassword,
        ),
      );

      // Make API call
      final response = await _repository.resetPassword(event.request);

      await response.when(
        success: (data) async {
          try {
            if (!data.isValid) {
              emit(
                ResetPasswordError(
                  error: 'Invalid response. Please try again.',
                  errorType: ResetPasswordErrorType.validation,
                  obscurePassword: currentObscurePassword,
                  obscureConfirmPassword: currentObscureConfirmPassword,
                ),
              );
              return;
            }

            emit(ResetPasswordSuccess(response: data, message: data.message));
          } catch (e) {
            emit(
              ResetPasswordError(
                error: 'Failed to reset password. Please try again.',
                errorType: ResetPasswordErrorType.general,
                obscurePassword: currentObscurePassword,
                obscureConfirmPassword: currentObscureConfirmPassword,
              ),
            );
          }
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            ResetPasswordError(
              error: error.toString(),
              errorType: errorType,
              obscurePassword: currentObscurePassword,
              obscureConfirmPassword: currentObscureConfirmPassword,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        const ResetPasswordError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: ResetPasswordErrorType.general,
        ),
      );
    }
  }

  /// Validates OTP field
  void _onValidateOTP(ValidateOTP event, Emitter<ResetPasswordState> emit) {
    if (state is! ResetPasswordInitial) return;

    final currentState = state as ResetPasswordInitial;
    final error = _validateOTP(event.otp);

    emit(currentState.copyWith(otpError: error, clearOtpError: error == null));
  }

  /// Validates new password field
  void _onValidateNewPassword(
    ValidateNewPassword event,
    Emitter<ResetPasswordState> emit,
  ) {
    if (state is! ResetPasswordInitial) return;

    final currentState = state as ResetPasswordInitial;
    final error = _validatePassword(event.password);

    emit(
      currentState.copyWith(
        passwordError: error,
        clearPasswordError: error == null,
      ),
    );
  }

  /// Validates confirm password field
  void _onValidateConfirmPassword(
    ValidateConfirmPassword event,
    Emitter<ResetPasswordState> emit,
  ) {
    if (state is! ResetPasswordInitial) return;

    final currentState = state as ResetPasswordInitial;
    final error = _validateConfirmPassword(
      event.password,
      event.confirmPassword,
    );

    emit(
      currentState.copyWith(
        confirmPasswordError: error,
        clearConfirmPasswordError: error == null,
      ),
    );
  }

  /// Toggles new password visibility
  void _onToggleNewPasswordVisibility(
    ToggleNewPasswordVisibility event,
    Emitter<ResetPasswordState> emit,
  ) {
    if (state is ResetPasswordInitial) {
      final currentState = state as ResetPasswordInitial;
      emit(
        currentState.copyWith(obscurePassword: !currentState.obscurePassword),
      );
    } else if (state is ResetPasswordError) {
      final currentState = state as ResetPasswordError;
      emit(
        currentState.copyWith(obscurePassword: !currentState.obscurePassword),
      );
    }
  }

  /// Toggles confirm password visibility
  void _onToggleConfirmPasswordVisibility(
    ToggleConfirmPasswordVisibility event,
    Emitter<ResetPasswordState> emit,
  ) {
    if (state is ResetPasswordInitial) {
      final currentState = state as ResetPasswordInitial;
      emit(
        currentState.copyWith(
          obscureConfirmPassword: !currentState.obscureConfirmPassword,
        ),
      );
    } else if (state is ResetPasswordError) {
      final currentState = state as ResetPasswordError;
      emit(
        currentState.copyWith(
          obscureConfirmPassword: !currentState.obscureConfirmPassword,
        ),
      );
    }
  }

  /// Resets state
  void _onResetState(
    ResetResetPasswordState event,
    Emitter<ResetPasswordState> emit,
  ) {
    emit(const ResetPasswordInitial());
  }

  /// OTP validation logic
  String? _validateOTP(String otp) {
    if (otp.isEmpty) {
      return 'OTP is required';
    }

    if (otp.length != 6) {
      return 'OTP must be 6 digits';
    }

    if (!RegExp(r'^\d+$').hasMatch(otp)) {
      return 'OTP must contain only numbers';
    }

    return null;
  }

  /// Password validation logic
  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  /// Confirm password validation logic
  String? _validateConfirmPassword(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Determines error type from error message
  ResetPasswordErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return ResetPasswordErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return ResetPasswordErrorType.timeout;
    }

    if (lowercaseError.contains('otp') ||
        lowercaseError.contains('invalid') ||
        lowercaseError.contains('expired')) {
      return ResetPasswordErrorType.invalidOtp;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return ResetPasswordErrorType.server;
    }

    if (lowercaseError.contains('validation')) {
      return ResetPasswordErrorType.validation;
    }

    return ResetPasswordErrorType.general;
  }
}
