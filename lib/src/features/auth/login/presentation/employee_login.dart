import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/theme/context_theme_extension.dart';
import 'package:sandwich_ai/src/core/config/app_environment.dart';
import 'package:sandwich_ai/src/core/config/dev_login_config.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/config/responsive_config.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/navigation/department_navigation.dart';
import 'package:sandwich_ai/src/features/auth/data/models/login_model.dart';
import 'package:sandwich_ai/src/features/auth/login/presentation/login_textfield.dart';
import 'package:sandwich_ai/src/features/auth/login/presentation/snack_bar.dart';
import 'package:sandwich_ai/src/features/auth/login_bloc/login_bloc.dart';
import 'package:sandwich_ai/src/features/auth/login_bloc/login_event.dart';
import 'package:sandwich_ai/src/features/auth/login_bloc/login_state.dart';

import '../../../../core/config/prod_print.dart';

class EmployeeLoginScreen extends StatefulWidget {
  const EmployeeLoginScreen({super.key});

  @override
  State<EmployeeLoginScreen> createState() => _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends State<EmployeeLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _orgCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    AppLogger.log(
      "INIT LOGIN: flavor = ${AppEnvironment.current.flavor}, devLoginEnabled = ${DevLoginConfig.enabled}, users count = ${DevLoginConfig.users.length}",
    );
    _applyDefaultLoginCredentialsIfEnabled();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _orgCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final authCache = AuthCacheHelper.instance;
      final rememberMe = await authCache.getRememberMe();

      if (rememberMe) {
        final savedEmail = await authCache.getRememberedEmail();
        final savedPassword = await authCache.getRememberedPassword();
        final savedOrgCode = await authCache.getRememberedOrgCode();

        if (savedEmail != null &&
            savedPassword != null &&
            savedOrgCode != null &&
            savedEmail.isNotEmpty &&
            savedPassword.isNotEmpty &&
            savedOrgCode.isNotEmpty) {
          _usernameController.text = savedEmail;
          _passwordController.text = savedPassword;
          _orgCodeController.text = savedOrgCode;

          // Update the bloc state to reflect remember me is checked
          if (mounted) {
            context.read<LoginBloc>().add(ToggleRememberMe(value: true));
          }
        }
      }
    } catch (e) {
      AppLogger.log('Error loading saved credentials: $e');
    }
  }

  void _applyDefaultLoginCredentialsIfEnabled() {
    if (!DevLoginConfig.enabled || DevLoginConfig.users.isEmpty) return;

    _setDevLoginFields(DevLoginConfig.users.first, validate: false);
  }

  void _applyDevLoginUser(DevLoginUser user, {required bool submit}) {
    _setDevLoginFields(user, validate: true);

    if (submit) {
      _handleLogin();
    }
  }

  void _setDevLoginFields(DevLoginUser user, {required bool validate}) {
    _usernameController.text = user.email;
    _passwordController.text = user.password;
    _orgCodeController.text = DevLoginConfig.organizationCode;

    if (!validate) return;

    context.read<LoginBloc>().add(ValidateEmail(email: user.email));
    context.read<LoginBloc>().add(ValidatePassword(password: user.password));
    context.read<LoginBloc>().add(
      ValidateOrgCode(orgCode: DevLoginConfig.organizationCode),
    );
  }

  Future<void> _saveCredentials(
    String email,
    String password,
    String organizationCode,
    bool rememberMe,
  ) async {
    try {
      final authCache = AuthCacheHelper.instance;
      await authCache.storeRememberedCredentials(
        email: email,
        password: password,
        organizationCode: organizationCode,
        rememberMe: rememberMe,
      );
    } catch (e) {
      AppLogger.log('Error saving credentials: $e');
    }
  }

  bool _getRememberMeState() {
    final currentState = context.read<LoginBloc>().state;

    if (currentState is LoginInitial) {
      return currentState.rememberMe;
    } else if (currentState is LoginError) {
      return currentState.rememberMe;
    } else if (currentState is LoginLoading) {
      return currentState.rememberMe;
    } else if (currentState is LoginValidation) {
      return currentState.rememberMe;
    }

    return false;
  }

  void _handleLogin() async {
    HapticFeedback.selectionClick();
    // Clear any existing errors
    FocusScope.of(context).unfocus();

    final email = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final orgCode = _orgCodeController.text.trim();

    // Get current remember me state
    final rememberMe = _getRememberMeState();

    // Save or clear credentials based on remember me checkbox
    await _saveCredentials(email, password, orgCode, rememberMe);

    if (!mounted) return;

    final request = LoginRequest(
      email: email,
      password: password,
      organizationCode: orgCode,
      type: 'EMPLOYEE',
    );

    context.read<LoginBloc>().add(LoginUser(request: request));
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveConfig.instance;
    final screenWidth = context.screenWidth;
    final screenHeight = context.screenHeight;
    final loginIconSize = responsive
        .getLargeIconSize(screenWidth)
        .clamp(56.0, 72.0)
        .toDouble();

    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginError) {
          showErrorSnackBar(
            state.error,
            context: context,
            errorType: state.errorType,
          );
        }
        if (state is LoginSuccess) {
          showSuccessSnackBar(state.message ?? 'Login successful!', context);

          final dpt = state.response.user.department;
          AppLogger.log('Department: $dpt');
          AppLogger.log(
            'Organization: ${state.response.user.organizationName}',
          );
          AppLogger.log('Branch: ${state.response.user.branch?.name}');

          final route = DepartmentNavigation.routeForDepartment(dpt);
          context.go(route ?? '/');
        }
      },
      child: DefaultTextStyle.merge(
        style: WorkSansAppTextStyles.medium,
        child: Scaffold(
          backgroundColor: context.modeBackground,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.getHorizontalPadding(screenWidth),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: responsive.getMaxContentWidth(screenWidth),
                    minHeight: screenHeight - 48,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo/Icon
                        Center(
                          child: SizedBox(
                            width: loginIconSize,
                            height: loginIconSize,
                            child: SvgPicture.asset(
                              'assets/svg/person.svg',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(
                          height:
                              responsive.getVerticalSpacing(screenHeight) * 0.8,
                        ),

                        // Title
                        Text(
                          'Employee Login',
                          textAlign: TextAlign.center,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: responsive.getTitleFontSize(screenWidth),
                            fontWeight: FontWeight.bold,
                            color: context.modeTextPrimary,
                          ),
                        ),
                        SizedBox(
                          height:
                              responsive.getVerticalSpacing(screenHeight) * 0.3,
                        ),

                        // Subtitle
                        Text(
                          'Welcome back, please sign in.',
                          textAlign: TextAlign.center,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: responsive.getSubtitleFontSize(
                              screenWidth,
                            ),
                            color: context.modeTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(
                          height:
                              responsive.getVerticalSpacing(screenHeight) *
                              (DevLoginConfig.enabled ? 0.9 : 1.5),
                        ),

                        if (DevLoginConfig.enabled) ...[
                          BlocBuilder<LoginBloc, LoginState>(
                            builder: (context, state) {
                              return _buildDevLoginPanel(
                                screenWidth: screenWidth,
                                isLoading: state is LoginLoading,
                              );
                            },
                          ),
                          SizedBox(
                            height:
                                responsive.getVerticalSpacing(screenHeight) *
                                0.9,
                          ),
                        ],

                        // Username/Email Field
                        BlocBuilder<LoginBloc, LoginState>(
                          buildWhen: (previous, current) {
                            // Rebuild when state changes or errors change
                            return previous.runtimeType !=
                                    current.runtimeType ||
                                (previous is LoginInitial &&
                                    current is LoginInitial &&
                                    previous.emailError !=
                                        current.emailError) ||
                                (previous is LoginValidation &&
                                    current is LoginValidation &&
                                    previous.emailError != current.emailError);
                          },
                          builder: (context, state) {
                            String? errorText;
                            if (state is LoginValidation) {
                              errorText = state.emailError;
                            } else if (state is LoginInitial) {
                              errorText = state.emailError;
                            }

                            return buildTextField(
                              context: context,
                              controller: _usernameController,
                              hintText: 'Email',
                              fontSize: responsive.getInputFontSize(
                                screenWidth,
                              ),
                              textInputAction: TextInputAction.next,
                              errorText: errorText,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (value) {
                                context.read<LoginBloc>().add(
                                  ValidateEmail(email: value),
                                );
                              },
                            );
                          },
                        ),
                        SizedBox(
                          height:
                              responsive.getVerticalSpacing(screenHeight) * 0.8,
                        ),

                        // Password Field
                        BlocBuilder<LoginBloc, LoginState>(
                          buildWhen: (previous, current) {
                            // Always rebuild for password visibility changes
                            return true;
                          },
                          builder: (context, state) {
                            bool obscurePassword = true;
                            String? errorText;

                            if (state is LoginInitial) {
                              obscurePassword = state.obscurePassword;
                              errorText = state.passwordError;
                            } else if (state is LoginError) {
                              obscurePassword = state.obscurePassword;
                            } else if (state is LoginValidation) {
                              obscurePassword = state.obscurePassword;
                              errorText = state.passwordError;
                            } else if (state is LoginLoading) {
                              obscurePassword = state.obscurePassword;
                            }

                            return buildTextField(
                              context: context,
                              controller: _passwordController,
                              hintText: 'Password',
                              obscureText: obscurePassword,
                              fontSize: responsive.getInputFontSize(
                                screenWidth,
                              ),
                              textInputAction: TextInputAction.next,
                              errorText: errorText,
                              onChanged: (value) {
                                context.read<LoginBloc>().add(
                                  ValidatePassword(password: value),
                                );
                              },
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: context.modeTextMuted,
                                  size: responsive.getIconSize(screenWidth),
                                ),
                                onPressed: () {
                                  context.read<LoginBloc>().add(
                                    const TogglePasswordVisibility(),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        SizedBox(
                          height:
                              responsive.getVerticalSpacing(screenHeight) * 0.8,
                        ),

                        // Organization Code Field
                        BlocBuilder<LoginBloc, LoginState>(
                          buildWhen: (previous, current) {
                            // Rebuild when state changes or errors change
                            return previous.runtimeType !=
                                    current.runtimeType ||
                                (previous is LoginInitial &&
                                    current is LoginInitial &&
                                    previous.orgCodeError !=
                                        current.orgCodeError) ||
                                (previous is LoginValidation &&
                                    current is LoginValidation &&
                                    previous.orgCodeError !=
                                        current.orgCodeError);
                          },
                          builder: (context, state) {
                            String? errorText;
                            if (state is LoginValidation) {
                              errorText = state.orgCodeError;
                            } else if (state is LoginInitial) {
                              errorText = state.orgCodeError;
                            }

                            return buildTextField(
                              context: context,
                              controller: _orgCodeController,
                              hintText: 'Organization Code',
                              fontSize: responsive.getInputFontSize(
                                screenWidth,
                              ),
                              textInputAction: TextInputAction.done,
                              errorText: errorText,
                              keyboardType: TextInputType.text,
                              onChanged: (value) {
                                context.read<LoginBloc>().add(
                                  ValidateOrgCode(orgCode: value),
                                );
                              },
                              onSubmitted: (_) => _handleLogin(),
                            );
                          },
                        ),
                        SizedBox(
                          height:
                              responsive.getVerticalSpacing(screenHeight) * 0.8,
                        ),

                        // Remember Me & Forgot Password
                        BlocBuilder<LoginBloc, LoginState>(
                          buildWhen: (previous, current) {
                            // Always rebuild for checkbox changes
                            return true;
                          },
                          builder: (context, state) {
                            bool rememberMe = false;
                            if (state is LoginInitial) {
                              rememberMe = state.rememberMe;
                            } else if (state is LoginError) {
                              rememberMe = state.rememberMe;
                            } else if (state is LoginLoading) {
                              rememberMe = state.rememberMe;
                            } else if (state is LoginValidation) {
                              rememberMe = state.rememberMe;
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: responsive.getCheckboxSize(
                                          screenWidth,
                                        ),
                                        height: responsive.getCheckboxSize(
                                          screenWidth,
                                        ),
                                        child: Checkbox(
                                          value: rememberMe,
                                          onChanged: (value) {
                                            context.read<LoginBloc>().add(
                                              ToggleRememberMe(
                                                value: value ?? false,
                                              ),
                                            );
                                          },
                                          activeColor: context.modePrimary,
                                          checkColor: context.modeTextInverse,
                                          side: BorderSide(
                                            color: context.modeBorder,
                                          ),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Remember me',
                                          style: WorkSansAppTextStyles.medium
                                              .copyWith(
                                                fontSize:
                                                    responsive
                                                        .getSubtitleFontSize(
                                                          screenWidth,
                                                        ) *
                                                    0.9,
                                                color:
                                                    context.modeTextSecondary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.push('/forgot-password');
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot password?',
                                    style: WorkSansAppTextStyles.medium
                                        .copyWith(
                                          fontSize:
                                              responsive.getSubtitleFontSize(
                                                screenWidth,
                                              ) *
                                              0.9,
                                          color: context.modePrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(
                          height:
                              responsive.getVerticalSpacing(screenHeight) * 1.2,
                        ),

                        // Login Button
                        BlocBuilder<LoginBloc, LoginState>(
                          builder: (context, state) {
                            final isLoading = state is LoginLoading;

                            return SizedBox(
                              height: responsive.getButtonHeight(screenWidth),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.modePrimary,
                                  foregroundColor: context.modeTextInverse,
                                  elevation: 0,
                                  disabledBackgroundColor: context.modePrimary
                                      .withValues(alpha: 0.6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      responsive.getButtonBorderRadius(
                                        screenWidth,
                                      ),
                                    ),
                                  ),
                                ),
                                child: isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                context.modeTextInverse,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        'Login',
                                        style: WorkSansAppTextStyles.medium
                                            .copyWith(
                                              fontSize: responsive
                                                  .getButtonFontSize(
                                                    screenWidth,
                                                  ),
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                              color: context.modeTextInverse,
                                            ),
                                      ),
                              ),
                            );
                          },
                        ),
                        SizedBox(
                          height:
                              responsive.getVerticalSpacing(screenHeight) * 1.5,
                        ),

                        // Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/img/Logo-DqvzRW6_.png',
                              width:
                                  responsive.getSubtitleFontSize(screenWidth) *
                                  0.85,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Powered by SandwichAI',
                              textAlign: TextAlign.center,
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize:
                                    responsive.getSubtitleFontSize(
                                      screenWidth,
                                    ) *
                                    0.85,
                                color: context.modeTextSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDevLoginPanel({
    required double screenWidth,
    required bool isLoading,
  }) {
    final panelBorderColor = context.isDarkMode
        ? context.modeBorder
        : context.modePrimary.withValues(alpha: 0.18);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? context.modeSurfaceAlt
            : context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: panelBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.modePrimary.withValues(
                    alpha: context.isDarkMode ? 0.16 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.science_outlined,
                  color: context.modePrimary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test users',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: screenWidth < 360 ? 13 : 14,
                        fontWeight: FontWeight.w700,
                        color: context.isDarkMode
                            ? Colors.white
                            : context.modeTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Tap a department to login with its token',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: screenWidth < 360 ? 11 : 12,
                        fontWeight: FontWeight.w500,
                        color: context.isDarkMode
                            ? Colors.white.withValues(alpha: 0.78)
                            : context.modeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DevLoginConfig.users.map((user) {
              return SizedBox(
                width: screenWidth < 390 ? double.infinity : null,
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () => _applyDevLoginUser(user, submit: true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.isDarkMode
                        ? Colors.white
                        : context.modePrimary,
                    disabledForegroundColor: context.modeTextMuted,
                    backgroundColor: context.modeSurface,
                    disabledBackgroundColor: context.modeSurfaceMuted
                        .withValues(alpha: 0.55),
                    side: BorderSide(
                      color: isLoading
                          ? context.modeBorder
                          : context.modePrimary.withValues(
                              alpha: context.isDarkMode ? 0.42 : 0.28,
                            ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    user.department,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: screenWidth < 360 ? 11 : 12,
                      fontWeight: FontWeight.w700,
                      color: context.isDarkMode
                          ? Colors.white
                          : context.modePrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
