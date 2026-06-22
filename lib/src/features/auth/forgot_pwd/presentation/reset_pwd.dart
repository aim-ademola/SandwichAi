import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/config/responsive_config.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sandwich_ai/src/features/auth/data/models/forgot_pwd_model.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/reset_pwd_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/reset_pwd_bloc/event.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/reset_pwd_bloc/state.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/presentation/shw-rst_snack.dart'
    show showErrorSnackBar;
import 'package:sandwich_ai/src/features/auth/forgot_pwd/presentation/snackbar.dart'
    show showSuccessSnackBar;
import 'package:sandwich_ai/src/features/auth/login/presentation/login_textfield.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String organizationCode;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.organizationCode,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    FocusScope.of(context).unfocus();

    final otp = _otpController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validate confirm password matches
    final currentState = context.read<ResetPasswordBloc>().state;
    if (currentState is ResetPasswordInitial) {
      context.read<ResetPasswordBloc>().add(
        ValidateConfirmPassword(
          password: password,
          confirmPassword: confirmPassword,
        ),
      );

      // Check if there are any validation errors
      if (password != confirmPassword) {
        return;
      }
    }

    final request = ResetPasswordRequest(
      email: widget.email,
      organizationCode: widget.organizationCode,
      type: 'EMPLOYEE',
      otp: otp,
      password: password,
    );

    context.read<ResetPasswordBloc>().add(ResetPassword(request: request));
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveConfig.instance;
    final screenWidth = context.screenWidth;
    final screenHeight = context.screenHeight;

    return BlocListener<ResetPasswordBloc, ResetPasswordState>(
      listener: (context, state) {
        if (state is ResetPasswordError) {
          showErrorSnackBar(
            state.error,
            context: context,
            errorType: state.errorType,
          );
        }
        if (state is ResetPasswordSuccess) {
          showSuccessSnackBar(state.message, context);

          // Navigate back to login after successful reset
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              // Pop until we get back to login
              context.go('/');
            }
          });
        }
      },
      child: DefaultTextStyle.merge(
        style: WorkSansAppTextStyles.medium,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F6F6),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8F6F6),
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: kprimaryTextColor1,
                size: responsive.getIconSize(screenWidth),
              ),
              onPressed: () => context.pop(),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.getHorizontalPadding(screenWidth),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: responsive.getMaxContentWidth(screenWidth),
                    minHeight: screenHeight - 100,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Icon
                        SvgPicture.asset('assets/svg/person.svg'),
                        SizedBox(
                          height:
                              responsive.getVerticalSpacing(screenHeight) * 0.8,
                        ),

                        // Title
                        Text(
                          'Reset Password',
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
                          'Enter the OTP sent to ${widget.email} and create a new password.',
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

                        // OTP Field
                        BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
                          builder: (context, state) {
                            String? errorText;
                            if (state is ResetPasswordValidation) {
                              errorText = state.otpError;
                            } else if (state is ResetPasswordInitial) {
                              errorText = state.otpError;
                            }

                            return buildTextField(
                              context: context,
                              controller: _otpController,
                              hintText: 'Enter 6-digit OTP',
                              fontSize: responsive.getInputFontSize(
                                screenWidth,
                              ),
                              textInputAction: TextInputAction.next,
                              errorText: errorText,
                              keyboardType: TextInputType.number,

                              onChanged: (value) {
                                context.read<ResetPasswordBloc>().add(
                                  ValidateOTP(otp: value),
                                );
                              },
                            );
                          },
                        ),
                        SizedBox(
                          height:
                              responsive.getVerticalSpacing(screenHeight) * 0.8,
                        ),

                        // New Password Field
                        BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
                          builder: (context, state) {
                            bool obscurePassword = true;
                            String? errorText;

                            if (state is ResetPasswordInitial) {
                              obscurePassword = state.obscurePassword;
                              errorText = state.passwordError;
                            } else if (state is ResetPasswordError) {
                              obscurePassword = state.obscurePassword;
                            } else if (state is ResetPasswordValidation) {
                              obscurePassword = state.obscurePassword;
                              errorText = state.passwordError;
                            } else if (state is ResetPasswordLoading) {
                              obscurePassword = state.obscurePassword;
                            }

                            return buildTextField(
                              context: context,
                              controller: _passwordController,
                              hintText: 'New Password',
                              obscureText: obscurePassword,
                              fontSize: responsive.getInputFontSize(
                                screenWidth,
                              ),
                              textInputAction: TextInputAction.next,
                              errorText: errorText,
                              onChanged: (value) {
                                context.read<ResetPasswordBloc>().add(
                                  ValidateNewPassword(password: value),
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
                                  context.read<ResetPasswordBloc>().add(
                                    const ToggleNewPasswordVisibility(),
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

                        // Confirm Password Field
                        BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
                          builder: (context, state) {
                            bool obscureConfirmPassword = true;
                            String? errorText;

                            if (state is ResetPasswordInitial) {
                              obscureConfirmPassword =
                                  state.obscureConfirmPassword;
                              errorText = state.confirmPasswordError;
                            } else if (state is ResetPasswordError) {
                              obscureConfirmPassword =
                                  state.obscureConfirmPassword;
                            } else if (state is ResetPasswordValidation) {
                              obscureConfirmPassword =
                                  state.obscureConfirmPassword;
                              errorText = state.confirmPasswordError;
                            } else if (state is ResetPasswordLoading) {
                              obscureConfirmPassword =
                                  state.obscureConfirmPassword;
                            }

                            return buildTextField(
                              context: context,
                              controller: _confirmPasswordController,
                              hintText: 'Confirm New Password',
                              obscureText: obscureConfirmPassword,
                              fontSize: responsive.getInputFontSize(
                                screenWidth,
                              ),
                              textInputAction: TextInputAction.done,
                              errorText: errorText,
                              onChanged: (value) {
                                context.read<ResetPasswordBloc>().add(
                                  ValidateConfirmPassword(
                                    password: _passwordController.text,
                                    confirmPassword: value,
                                  ),
                                );
                              },
                              onSubmitted: (_) => _handleResetPassword(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF9E9E9E),
                                  size: responsive.getIconSize(screenWidth),
                                ),
                                onPressed: () {
                                  context.read<ResetPasswordBloc>().add(
                                    const ToggleConfirmPasswordVisibility(),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        SizedBox(
                          height:
                              responsive.getVerticalSpacing(screenHeight) * 1.2,
                        ),

                        // Reset Password Button
                        BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
                          builder: (context, state) {
                            final isLoading = state is ResetPasswordLoading;

                            return SizedBox(
                              height: responsive.getButtonHeight(screenWidth),
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : _handleResetPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  disabledBackgroundColor: kPrimary.withValues(
                                    alpha: 0.6,
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
                                        'Reset Password',
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
                              responsive.getVerticalSpacing(screenHeight) * 1.0,
                        ),

                        // Back to Login
                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/'),
                            child: Text(
                              'Back to Login',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize:
                                    responsive.getSubtitleFontSize(
                                      screenWidth,
                                    ) *
                                    0.95,
                                color: kPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
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
