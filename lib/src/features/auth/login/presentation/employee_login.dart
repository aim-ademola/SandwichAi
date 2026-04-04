import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/config/responsive_config.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
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

          // Navigate based on department
          // context.go('/Pos-nav');

          // Uncomment to enable department-based navigation
          if (dpt == null) {
            context.go('/');
            return;
          }

          switch (dpt) {
            case 'KITCHEN':
              context.go('/Kitchen-nav');
              break;
            case 'PROCESSING':
              context.go('/Processing-nav');
              break;
            case 'PROCUREMENT':
              context.go('/Procurement-nav');
              break;
            case 'STOCK_CONTROL':
              context.go('/Stock-control-nav');
              break;
            case 'CUSTOMER_SERVICE':
              context.go('/Pos-nav');
              break;
            default:
              context.go('/');
          }
        }
      },
      child: DefaultTextStyle.merge(
        style: WorkSansAppTextStyles.medium,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F6F6),
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
                        SvgPicture.asset('assets/svg/person.svg'),
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
                            color: kprimaryTextColor1,
                            letterSpacing: -0.5,
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
                            color: kprimaryTextColor2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(
                          height:
                              responsive.getVerticalSpacing(screenHeight) * 1.5,
                        ),

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
                                  color: const Color(0xFF9E9E9E),
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
                                          activeColor: kPrimary,
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
                                                color: kprimaryTextColor2,
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
                                          color: kPrimary,
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
                                  backgroundColor: kPrimary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  disabledBackgroundColor: kPrimary.withOpacity(
                                    0.6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      responsive.getButtonBorderRadius(
                                        screenWidth,
                                      ),
                                    ),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
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
                                              color: kWhite,
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
                                color: kprimaryTextColor2,
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
}
