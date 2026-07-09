import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/globals/analytics/analytics_service.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/auth/data/repo/login_repo.dart';
import 'package:sandwich_ai/src/features/auth/login_bloc/login_event.dart';
import 'package:sandwich_ai/src/features/auth/login_bloc/login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginRepositoryInterface _loginRepository;
  final AuthCacheHelper _authCacheHelper = AuthCacheHelper.instance;

  LoginBloc({required LoginRepositoryInterface loginRepository})
    : _loginRepository = loginRepository,
      super(const LoginInitial()) {
    on<LoginUser>(_onLoginUser);
    on<ValidateEmail>(_onValidateEmail);
    on<ValidatePassword>(_onValidatePassword);
    on<ValidateOrgCode>(_onValidateOrgCode);
    on<TogglePasswordVisibility>(_onTogglePasswordVisibility);
    on<ToggleRememberMe>(_onToggleRememberMe);
    on<ResetLoginState>(_onResetLoginState);
    on<LogoutUser>(_onLogoutUser);
  }

  /// Handles user login
  Future<void> _onLoginUser(LoginUser event, Emitter<LoginState> emit) async {
    try {
      // Validate inputs before making API call
      final emailError = _validateEmail(event.request.email);
      final passwordError = _validatePassword(event.request.password);
      final orgCodeError = _validateOrgCode(event.request.organizationCode);

      if (emailError != null || passwordError != null || orgCodeError != null) {
        emit(
          LoginValidation(
            emailError: emailError,
            passwordError: passwordError,
            orgCodeError: orgCodeError,
            obscurePassword: _getObscurePassword(),
            rememberMe: _getRememberMe(),
          ),
        );
        return;
      }

      // Preserve UI state during loading
      final currentObscurePassword = _getObscurePassword();
      final currentRememberMe = _getRememberMe();

      emit(
        LoginLoading(
          obscurePassword: currentObscurePassword,
          rememberMe: currentRememberMe,
        ),
      );

      // Make API call
      final response = await _loginRepository.loginUser(event.request);

      await response.when(
        success: (data) async {
          try {
            // Validate response data
            if (!data.isValid) {
              emit(
                LoginError(
                  error: 'Invalid login response. Please try again.',
                  errorType: LoginErrorType.validation,
                  obscurePassword: currentObscurePassword,
                  rememberMe: currentRememberMe,
                ),
              );
              return;
            }

            // Store auth data
            await _authCacheHelper.storeAuthData(data);

            // Store remember me preference and credentials if needed
            if (currentRememberMe) {
              await _authCacheHelper.setRememberMe(true);
              // Credentials are already stored in the screen's _saveCredentials method
            }

            // Log successful login to Firebase Analytics
            await AnalyticsService.instance.logLogin(
              email: event.request.email,
              orgCode: event.request.organizationCode,
            );

            emit(
              LoginSuccess(
                response: data,
                message:
                    'Login successful! Welcome back, ${data.user.fullName ?? data.user.email}',
              ),
            );
          } catch (e) {
            emit(
              LoginError(
                error: 'Failed to save login data. Please try again.',
                errorType: LoginErrorType.general,
                obscurePassword: currentObscurePassword,
                rememberMe: currentRememberMe,
              ),
            );
          }
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            LoginError(
              error: error.toString(),
              errorType: errorType,
              obscurePassword: currentObscurePassword,
              rememberMe: currentRememberMe,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        LoginError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: LoginErrorType.general,
        ),
      );
    }
  }

  /// Validates email field
  void _onValidateEmail(ValidateEmail event, Emitter<LoginState> emit) {
    if (state is! LoginInitial) return;

    final currentState = state as LoginInitial;
    final error = _validateEmail(event.email);

    emit(
      currentState.copyWith(emailError: error, clearEmailError: error == null),
    );
  }

  /// Validates password field
  void _onValidatePassword(ValidatePassword event, Emitter<LoginState> emit) {
    if (state is! LoginInitial) return;

    final currentState = state as LoginInitial;
    final error = _validatePassword(event.password);

    emit(
      currentState.copyWith(
        passwordError: error,
        clearPasswordError: error == null,
      ),
    );
  }

  /// Validates organization code field
  void _onValidateOrgCode(ValidateOrgCode event, Emitter<LoginState> emit) {
    if (state is! LoginInitial) return;

    final currentState = state as LoginInitial;
    final error = _validateOrgCode(event.orgCode);

    emit(
      currentState.copyWith(
        orgCodeError: error,
        clearOrgCodeError: error == null,
      ),
    );
  }

  /// Toggles password visibility
  void _onTogglePasswordVisibility(
    TogglePasswordVisibility event,
    Emitter<LoginState> emit,
  ) {
    if (state is LoginInitial) {
      final currentState = state as LoginInitial;
      emit(
        currentState.copyWith(obscurePassword: !currentState.obscurePassword),
      );
    } else if (state is LoginError) {
      final currentState = state as LoginError;
      emit(
        currentState.copyWith(obscurePassword: !currentState.obscurePassword),
      );
    } else if (state is LoginValidation) {
      final currentState = state as LoginValidation;
      emit(
        LoginInitial(
          obscurePassword: !currentState.obscurePassword,
          rememberMe: currentState.rememberMe,
          emailError: currentState.emailError,
          passwordError: currentState.passwordError,
          orgCodeError: currentState.orgCodeError,
        ),
      );
    } else if (state is LoginLoading) {
      final currentState = state as LoginLoading;
      emit(
        LoginLoading(
          obscurePassword: !currentState.obscurePassword,
          rememberMe: currentState.rememberMe,
        ),
      );
    }
  }

  /// Toggles remember me
  void _onToggleRememberMe(ToggleRememberMe event, Emitter<LoginState> emit) {
    if (state is LoginInitial) {
      final currentState = state as LoginInitial;
      emit(currentState.copyWith(rememberMe: event.value));
    } else if (state is LoginError) {
      final currentState = state as LoginError;
      emit(
        LoginInitial(
          obscurePassword: currentState.obscurePassword,
          rememberMe: event.value,
        ),
      );
    } else if (state is LoginValidation) {
      final currentState = state as LoginValidation;
      emit(
        LoginInitial(
          obscurePassword: currentState.obscurePassword,
          rememberMe: event.value,
          emailError: currentState.emailError,
          passwordError: currentState.passwordError,
          orgCodeError: currentState.orgCodeError,
        ),
      );
    } else if (state is LoginLoading) {
      final currentState = state as LoginLoading;
      emit(
        LoginLoading(
          obscurePassword: currentState.obscurePassword,
          rememberMe: event.value,
        ),
      );
    }
  }

  /// Resets login state
  void _onResetLoginState(ResetLoginState event, Emitter<LoginState> emit) {
    emit(const LoginInitial());
  }

  /// Handles logout
  Future<void> _onLogoutUser(LogoutUser event, Emitter<LoginState> emit) async {
    try {
      // Log logout to Firebase Analytics
      await AnalyticsService.instance.logLogout();
      await _authCacheHelper.clearAuthData();
      emit(const LoginInitial());
    } catch (e) {
      // Even if clearing fails, reset to initial state
      emit(const LoginInitial());
    }
  }

  /// Helper method to get current obscurePassword state
  bool _getObscurePassword() {
    if (state is LoginInitial) {
      return (state as LoginInitial).obscurePassword;
    } else if (state is LoginError) {
      return (state as LoginError).obscurePassword;
    } else if (state is LoginValidation) {
      return (state as LoginValidation).obscurePassword;
    } else if (state is LoginLoading) {
      return (state as LoginLoading).obscurePassword;
    }
    return true; // Default
  }

  /// Helper method to get current rememberMe state
  bool _getRememberMe() {
    if (state is LoginInitial) {
      return (state as LoginInitial).rememberMe;
    } else if (state is LoginError) {
      return (state as LoginError).rememberMe;
    } else if (state is LoginValidation) {
      return (state as LoginValidation).rememberMe;
    } else if (state is LoginLoading) {
      return (state as LoginLoading).rememberMe;
    }
    return false; // Default
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

  /// Organization code validation logic
  String? _validateOrgCode(String orgCode) {
    if (orgCode.isEmpty) {
      return 'Organization code is required';
    }

    if (orgCode.length < 3) {
      return 'Organization code must be at least 3 characters';
    }

    return null;
  }

  /// Determines error type from error message
  LoginErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return LoginErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return LoginErrorType.timeout;
    }

    if (lowercaseError.contains('invalid') ||
        lowercaseError.contains('unauthorized') ||
        lowercaseError.contains('credentials') ||
        lowercaseError.contains('password') ||
        lowercaseError.contains('organization')) {
      return LoginErrorType.authentication;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return LoginErrorType.server;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return LoginErrorType.validation;
    }

    return LoginErrorType.general;
  }
}
