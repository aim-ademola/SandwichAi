// lib/core/network/error_handler.dart
import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/network_exception.dart';

class ErrorHandler {
  static void showErrorDialog(BuildContext context, NetworkException error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_getErrorTitle(error.type)),
        content: Text(error.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, NetworkException error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.message),
        backgroundColor: _getErrorColor(error.type),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static String _getErrorTitle(NetworkExceptionType type) {
    switch (type) {
      case NetworkExceptionType.noInternetConnection:
        return 'No Internet Connection';
      case NetworkExceptionType.requestTimeout:
      case NetworkExceptionType.sendTimeout:
      case NetworkExceptionType.receiveTimeout:
        return 'Timeout Error';
      case NetworkExceptionType.unauthorizedRequest:
        return 'Authentication Error';
      case NetworkExceptionType.forbidden:
        return 'Access Denied';
      case NetworkExceptionType.notFound:
        return 'Not Found';
      case NetworkExceptionType.internalServerError:
      case NetworkExceptionType.badGateway:
      case NetworkExceptionType.serviceUnavailable:
      case NetworkExceptionType.gatewayTimeout:
        return 'Server Error';
      case NetworkExceptionType.tooManyRequests:
        return 'Rate Limited';
      default:
        return 'Error';
    }
  }

  static Color _getErrorColor(NetworkExceptionType type) {
    switch (type) {
      case NetworkExceptionType.noInternetConnection:
        return Colors.orange;
      case NetworkExceptionType.unauthorizedRequest:
      case NetworkExceptionType.forbidden:
        return Colors.red[700]!;
      case NetworkExceptionType.internalServerError:
      case NetworkExceptionType.badGateway:
      case NetworkExceptionType.serviceUnavailable:
      case NetworkExceptionType.gatewayTimeout:
        return Colors.red;
      case NetworkExceptionType.tooManyRequests:
        return Colors.amber;
      default:
        return Colors.red;
    }
  }
}
