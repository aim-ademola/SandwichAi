import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/cnage_pwd_blocs/state.dart';

void showErrorSnackBar(
  String message, {
  ChangePasswordErrorType? errorType,
  required BuildContext context,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();

  Color backgroundColor;
  IconData icon;

  switch (errorType) {
    case ChangePasswordErrorType.network:
      backgroundColor = Colors.orange;
      icon = Icons.wifi_off;
      break;
    case ChangePasswordErrorType.validation:
      backgroundColor = Colors.red.shade700;
      icon = Icons.lock_outline;
      break;
    case ChangePasswordErrorType.timeout:
      backgroundColor = Colors.amber.shade800;
      icon = Icons.access_time;
      break;
    case ChangePasswordErrorType.server:
      backgroundColor = Colors.red.shade900;
      icon = Icons.cloud_off;
      break;
    default:
      backgroundColor = Colors.red;
      icon = Icons.error_outline;
  }

  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          AppIcon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () => messenger.hideCurrentSnackBar(),
      ),
    ),
  );
}

void showSuccessSnackBar(String message, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const AppIcon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 2),
    ),
  );
}
