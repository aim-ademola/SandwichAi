import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/config/responsive_config.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/auth/data/models/forgot_pwd_model.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/bloc/bloc.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/bloc/event.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/bloc/state.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/presentation/snackbar.dart';

import 'package:sandwich_ai/src/features/auth/login/presentation/login_textfield.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _organizationCode = '';

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    try {
      final authCache = AuthCacheHelper.instance;

      // Get saved organization code
      final savedOrgCode = await authCache.getRememberedOrgCode();
      if (savedOrgCode != null && savedOrgCode.isNotEmpty) {
        setState(() {
          _organizationCode = savedOrgCode;
        });
      }

      // Get saved email
      final savedEmail = await authCache.getRememberedEmail();
      if (savedEmail != null && savedEmail.isNotEmpty) {
        _emailController.text = savedEmail;
      }
    } catch (e) {
      AppLogger.log('Error loading saved data: $e');
    }
  }

  void _handleSendOTP() {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();

    // Check if organization code is available
    if (_organizationCode.isEmpty) {
      showErrorSnackBar(
        'Organization code not found. Please login first.',
        context: context,
        errorType: ForgotPasswordErrorType.validation,
      );
      return;
    }

    final request = ForgotPasswordRequest(
      email: email,
      organizationCode: _organizationCode,
      type: 'EMPLOYEE',
    );

    context.read<ForgotPasswordBloc>().add(SendOTP(request: request));
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveConfig.instance;
    final screenWidth = context.screenWidth;
    final screenHeight = context.screenHeight;

    return BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
      listener: (context, state) {
        if (state is ForgotPasswordError) {
          showErrorSnackBar(
            state.error,
            context: context,
            errorType: state.errorType,
          );
        }
        if (state is ForgotPasswordSuccess) {
          showSuccessSnackBar(state.message, context);

          // Navigate to reset password screen with email and org code
          context.push(
            '/reset-password',
            extra: {
              'email': state.email,
              'organizationCode': state.organizationCode,
            },
          );
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
              icon: AppIcon(
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
                        AppIcon(
                          Icons.person_outline_rounded,
                          color: kPrimary,
                          size: responsive.getLargeIconSize(screenWidth),
                        ),
                        SizedBox(
                          height:
                              responsive.getVerticalSpacing(screenHeight) * 0.8,
                        ),

                        // Title
                        Text(
                          'Forgot Password',
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
                          'Enter your email address to receive an OTP.',
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

                        // Email Field
                        BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
                          builder: (context, state) {
                            String? errorText;
                            if (state is ForgotPasswordValidation) {
                              errorText = state.emailError;
                            } else if (state is ForgotPasswordInitial) {
                              errorText = state.emailError;
                            }

                            return buildTextField(
                              context: context,
                              controller: _emailController,
                              hintText: 'Email',
                              fontSize: responsive.getInputFontSize(
                                screenWidth,
                              ),
                              textInputAction: TextInputAction.done,
                              errorText: errorText,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (value) {
                                context.read<ForgotPasswordBloc>().add(
                                  ValidateForgotEmail(email: value),
                                );
                              },
                              onSubmitted: (_) => _handleSendOTP(),
                            );
                          },
                        ),
                        SizedBox(
                          height:
                              responsive.getVerticalSpacing(screenHeight) * 1.2,
                        ),

                        // Send OTP Button
                        BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
                          builder: (context, state) {
                            final isLoading = state is ForgotPasswordLoading;

                            return SizedBox(
                              height: responsive.getButtonHeight(screenWidth),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleSendOTP,
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
                                        'Send OTP',
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
                            onPressed: () => context.pop(),
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
