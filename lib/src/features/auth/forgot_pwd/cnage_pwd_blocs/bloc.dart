import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/auth/data/repo/chnage_pwd_repo.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/cnage_pwd_blocs/event.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/cnage_pwd_blocs/state.dart';

class ChangePasswordBloc
    extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  final ChangePasswordRepositoryInterface _repository;

  ChangePasswordBloc({required ChangePasswordRepositoryInterface repository})
    : _repository = repository,
      super(const ChangePasswordInitial()) {
    on<ChangePassword>(_onChangePassword);
    on<ValidateCurrentPassword>(_onValidateCurrentPassword);
    on<ValidateNewPassword>(_onValidateNewPassword);
    on<ValidateConfirmPassword>(_onValidateConfirmPassword);
    on<ToggleCurrentPasswordVisibility>(_onToggleCurrentPasswordVisibility);
    on<ToggleNewPasswordVisibility>(_onToggleNewPasswordVisibility);
    on<ToggleConfirmPasswordVisibility>(_onToggleConfirmPasswordVisibility);
    on<ResetChangePasswordState>(_onResetState);
  }

  Future<void> _onChangePassword(
    ChangePassword event,
    Emitter<ChangePasswordState> emit,
  ) async {
    try {
      final currentPasswordError = _validatePassword(
        event.request.currentPassword,
        isCurrentPwd: true,
      );
      final newPasswordError = _validatePassword(
        event.request.newPassword,
        isCurrentPwd: false,
      );
      final samePasswordError =
          event.request.currentPassword == event.request.newPassword
          ? 'New password must be different from current password'
          : null;

      if (currentPasswordError != null ||
          newPasswordError != null ||
          samePasswordError != null) {
        emit(
          ChangePasswordValidation(
            currentPasswordError: currentPasswordError,
            newPasswordError: newPasswordError ?? samePasswordError,
            obscureCurrentPassword: state is ChangePasswordInitial
                ? (state as ChangePasswordInitial).obscureCurrentPassword
                : true,
            obscureNewPassword: state is ChangePasswordInitial
                ? (state as ChangePasswordInitial).obscureNewPassword
                : true,
            obscureConfirmPassword: state is ChangePasswordInitial
                ? (state as ChangePasswordInitial).obscureConfirmPassword
                : true,
          ),
        );
        return;
      }
      final (
        currentObscureCurrentPassword,
        currentObscureNewPassword,
        currentObscureConfirmPassword,
      ) = _getVisibilityState();

      emit(
        ChangePasswordLoading(
          obscureCurrentPassword: currentObscureCurrentPassword,
          obscureNewPassword: currentObscureNewPassword,
          obscureConfirmPassword: currentObscureConfirmPassword,
        ),
      );

      final response = await _repository.changePassword(event.request);

      await response.when(
        success: (data) async {
          try {
            if (!data.isValid) {
              emit(
                ChangePasswordError(
                  error: 'Invalid response. Please try again.',
                  errorType: ChangePasswordErrorType.validation,
                  obscureCurrentPassword: currentObscureCurrentPassword,
                  obscureNewPassword: currentObscureNewPassword,
                  obscureConfirmPassword: currentObscureConfirmPassword,
                ),
              );
              return;
            }
            emit(ChangePasswordSuccess(message: data.message));
          } catch (e) {
            emit(
              ChangePasswordError(
                error: 'Failed to change password. Please try again.',
                errorType: ChangePasswordErrorType.general,
                obscureCurrentPassword: currentObscureCurrentPassword,
                obscureNewPassword: currentObscureNewPassword,
                obscureConfirmPassword: currentObscureConfirmPassword,
              ),
            );
          }
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            ChangePasswordError(
              error: error.toString(),
              errorType: errorType,
              obscureCurrentPassword: currentObscureCurrentPassword,
              obscureNewPassword: currentObscureNewPassword,
              obscureConfirmPassword: currentObscureConfirmPassword,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        const ChangePasswordError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: ChangePasswordErrorType.general,
        ),
      );
    }
  }

  void _onValidateCurrentPassword(
    ValidateCurrentPassword event,
    Emitter<ChangePasswordState> emit,
  ) {
    if (state is! ChangePasswordInitial) return;
    final currentState = state as ChangePasswordInitial;
    final error = _validatePassword(event.password, isCurrentPwd: true);
    emit(
      currentState.copyWith(
        currentPasswordError: error,
        clearCurrentPasswordError: error == null,
      ),
    );
  }

  void _onValidateNewPassword(
    ValidateNewPassword event,
    Emitter<ChangePasswordState> emit,
  ) {
    if (state is! ChangePasswordInitial) return;
    final currentState = state as ChangePasswordInitial;
    final error = _validatePassword(event.password, isCurrentPwd: false);
    emit(
      currentState.copyWith(
        newPasswordError: error,
        clearNewPasswordError: error == null,
      ),
    );
  }

  void _onValidateConfirmPassword(
    ValidateConfirmPassword event,
    Emitter<ChangePasswordState> emit,
  ) {
    if (state is! ChangePasswordInitial) return;
    final currentState = state as ChangePasswordInitial;
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

  void _onToggleCurrentPasswordVisibility(
    ToggleCurrentPasswordVisibility event,
    Emitter<ChangePasswordState> emit,
  ) {
    if (state is ChangePasswordInitial) {
      final s = state as ChangePasswordInitial;
      emit(s.copyWith(obscureCurrentPassword: !s.obscureCurrentPassword));
    } else if (state is ChangePasswordError) {
      final s = state as ChangePasswordError;
      emit(s.copyWith(obscureCurrentPassword: !s.obscureCurrentPassword));
    }
  }

  void _onToggleNewPasswordVisibility(
    ToggleNewPasswordVisibility event,
    Emitter<ChangePasswordState> emit,
  ) {
    if (state is ChangePasswordInitial) {
      final s = state as ChangePasswordInitial;
      emit(s.copyWith(obscureNewPassword: !s.obscureNewPassword));
    } else if (state is ChangePasswordError) {
      final s = state as ChangePasswordError;
      emit(s.copyWith(obscureNewPassword: !s.obscureNewPassword));
    }
  }

  void _onToggleConfirmPasswordVisibility(
    ToggleConfirmPasswordVisibility event,
    Emitter<ChangePasswordState> emit,
  ) {
    if (state is ChangePasswordInitial) {
      final s = state as ChangePasswordInitial;
      emit(s.copyWith(obscureConfirmPassword: !s.obscureConfirmPassword));
    } else if (state is ChangePasswordError) {
      final s = state as ChangePasswordError;
      emit(s.copyWith(obscureConfirmPassword: !s.obscureConfirmPassword));
    }
  }

  void _onResetState(
    ResetChangePasswordState event,
    Emitter<ChangePasswordState> emit,
  ) {
    emit(const ChangePasswordInitial());
  }

  String? _validatePassword(String password, {required bool isCurrentPwd}) {
    if (password.isEmpty) {
      return isCurrentPwd
          ? 'Current password is required'
          : 'New password is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) {
      return 'Please confirm your new password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  ChangePasswordErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return ChangePasswordErrorType.network;
    }
    if (lowercaseError.contains('timeout')) {
      return ChangePasswordErrorType.timeout;
    }
    if (lowercaseError.contains('401') ||
        lowercaseError.contains('unauthorized') ||
        lowercaseError.contains('incorrect')) {
      return ChangePasswordErrorType.unauthorized;
    }
    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return ChangePasswordErrorType.server;
    }
    if (lowercaseError.contains('validation')) {
      return ChangePasswordErrorType.validation;
    }
    return ChangePasswordErrorType.general;
  }

  (bool, bool, bool) _getVisibilityState() {
    if (state is ChangePasswordInitial) {
      final s = state as ChangePasswordInitial;
      return (
        s.obscureCurrentPassword,
        s.obscureNewPassword,
        s.obscureConfirmPassword,
      );
    } else if (state is ChangePasswordError) {
      final s = state as ChangePasswordError;
      return (
        s.obscureCurrentPassword,
        s.obscureNewPassword,
        s.obscureConfirmPassword,
      );
    } else if (state is ChangePasswordLoading) {
      final s = state as ChangePasswordLoading;
      return (
        s.obscureCurrentPassword,
        s.obscureNewPassword,
        s.obscureConfirmPassword,
      );
    }

    return (true, true, true);
  }
}
