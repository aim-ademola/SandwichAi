import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/config/responsive_config.dart';
import 'package:sandwich_ai/src/features/auth/data/models/chnage-pwd-res.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/cnage_pwd_blocs/bloc.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/cnage_pwd_blocs/event.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/cnage_pwd_blocs/state.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/presentation/snack_bar_chnge.dart';

import 'package:sandwich_ai/src/features/auth/login/presentation/login_textfield.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleChangePassword() {
    FocusScope.of(context).unfocus();

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validate confirm password first
    final bloc = context.read<ChangePasswordBloc>();
    final currentState = bloc.state;

    if (currentState is ChangePasswordInitial) {
      bloc.add(
        ValidateConfirmPassword(
          password: newPassword,
          confirmPassword: confirmPassword,
        ),
      );
      if (newPassword != confirmPassword) return;
    }

    bloc.add(
      ChangePassword(
        request: ChangePasswordRequest(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveConfig.instance;
    final screenWidth = context.screenWidth;
    final screenHeight = context.screenHeight;

    return BlocListener<ChangePasswordBloc, ChangePasswordState>(
      listener: (context, state) {
        if (state is ChangePasswordError) {
          showErrorSnackBar(
            state.error,
            context: context,
            errorType: state.errorType,
          );
        }
        if (state is ChangePasswordSuccess) {
          showSuccessSnackBar(state.message, context);
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) context.pop();
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
            title: Text(
              'Change Password',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: responsive.getSubtitleFontSize(screenWidth) * 1.1,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            centerTitle: true,
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
                    minHeight: screenHeight - 150,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Subtitle

                        // Current Password Field
                        BlocBuilder<ChangePasswordBloc, ChangePasswordState>(
                          builder: (context, state) {
                            bool obscure = true;
                            String? errorText;

                            if (state is ChangePasswordInitial) {
                              obscure = state.obscureCurrentPassword;
                              errorText = state.currentPasswordError;
                            } else if (state is ChangePasswordError) {
                              obscure = state.obscureCurrentPassword;
                            } else if (state is ChangePasswordValidation) {
                              obscure = state.obscureCurrentPassword;
                              errorText = state.currentPasswordError;
                            } else if (state is ChangePasswordLoading) {
                              obscure = state.obscureCurrentPassword;
                            }

                            return buildTextField(
                              context: context,
                              controller: _currentPasswordController,
                              hintText: 'Current Password',
                              obscureText: obscure,
                              fontSize: responsive.getInputFontSize(
                                screenWidth,
                              ),
                              textInputAction: TextInputAction.next,
                              errorText: errorText,
                              onChanged: (value) {
                                context.read<ChangePasswordBloc>().add(
                                  ValidateCurrentPassword(password: value),
                                );
                              },
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF9E9E9E),
                                  size: responsive.getIconSize(screenWidth),
                                ),
                                onPressed: () {
                                  context.read<ChangePasswordBloc>().add(
                                    const ToggleCurrentPasswordVisibility(),
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

                        // New Password Field
                        BlocBuilder<ChangePasswordBloc, ChangePasswordState>(
                          builder: (context, state) {
                            bool obscure = true;
                            String? errorText;

                            if (state is ChangePasswordInitial) {
                              obscure = state.obscureNewPassword;
                              errorText = state.newPasswordError;
                            } else if (state is ChangePasswordError) {
                              obscure = state.obscureNewPassword;
                            } else if (state is ChangePasswordValidation) {
                              obscure = state.obscureNewPassword;
                              errorText = state.newPasswordError;
                            } else if (state is ChangePasswordLoading) {
                              obscure = state.obscureNewPassword;
                            }

                            return buildTextField(
                              context: context,
                              controller: _newPasswordController,
                              hintText: 'New Password',
                              obscureText: obscure,
                              fontSize: responsive.getInputFontSize(
                                screenWidth,
                              ),
                              textInputAction: TextInputAction.next,
                              errorText: errorText,
                              onChanged: (value) {
                                context.read<ChangePasswordBloc>().add(
                                  ValidateNewPassword(password: value),
                                );
                              },
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF9E9E9E),
                                  size: responsive.getIconSize(screenWidth),
                                ),
                                onPressed: () {
                                  context.read<ChangePasswordBloc>().add(
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

                        // Confirm New Password Field
                        BlocBuilder<ChangePasswordBloc, ChangePasswordState>(
                          builder: (context, state) {
                            bool obscure = true;
                            String? errorText;

                            if (state is ChangePasswordInitial) {
                              obscure = state.obscureConfirmPassword;
                              errorText = state.confirmPasswordError;
                            } else if (state is ChangePasswordError) {
                              obscure = state.obscureConfirmPassword;
                            } else if (state is ChangePasswordValidation) {
                              obscure = state.obscureConfirmPassword;
                              errorText = state.confirmPasswordError;
                            } else if (state is ChangePasswordLoading) {
                              obscure = state.obscureConfirmPassword;
                            }

                            return buildTextField(
                              context: context,
                              controller: _confirmPasswordController,
                              hintText: 'Confirm New Password',
                              obscureText: obscure,
                              fontSize: responsive.getInputFontSize(
                                screenWidth,
                              ),
                              textInputAction: TextInputAction.done,
                              errorText: errorText,
                              onChanged: (value) {
                                context.read<ChangePasswordBloc>().add(
                                  ValidateConfirmPassword(
                                    password: _newPasswordController.text,
                                    confirmPassword: value,
                                  ),
                                );
                              },
                              onSubmitted: (_) => _handleChangePassword(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF9E9E9E),
                                  size: responsive.getIconSize(screenWidth),
                                ),
                                onPressed: () {
                                  context.read<ChangePasswordBloc>().add(
                                    const ToggleConfirmPasswordVisibility(),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        SizedBox(
                          height:
                              responsive.getVerticalSpacing(screenHeight) * 1.5,
                        ),

                        // Change Password Button
                        BlocBuilder<ChangePasswordBloc, ChangePasswordState>(
                          builder: (context, state) {
                            final isLoading = state is ChangePasswordLoading;

                            return SizedBox(
                              height: responsive.getButtonHeight(screenWidth),
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : _handleChangePassword,
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
                                        'Change Password',
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
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     Image.asset(
                        //       'assets/img/Logo-DqvzRW6_.png',
                        //       width:
                        //           responsive.getSubtitleFontSize(screenWidth) *
                        //           0.85,
                        //     ),
                        //     const SizedBox(width: 5),
                        //     Text(
                        //       'Powered by SandwichAI',
                        //       textAlign: TextAlign.center,
                        //       style: WorkSansAppTextStyles.medium.copyWith(
                        //         fontSize:
                        //             responsive.getSubtitleFontSize(
                        //               screenWidth,
                        //             ) *
                        //             0.85,
                        //         color: kprimaryTextColor2,
                        //         fontWeight: FontWeight.w500,
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        SizedBox(
                          height:
                              responsive.getVerticalSpacing(screenHeight) * 1.0,
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
