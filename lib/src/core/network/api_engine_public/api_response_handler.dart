// lib/widgets/api_response_handler.dart
import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/network_exception.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/error_handler.dart';

class ApiResponseHandler<T> extends StatelessWidget {
  final ApiResponse<T>? response;

  final bool isLoading;
  final Widget Function(T data) onSuccess;
  final Widget Function(NetworkException error)? onError;
  final VoidCallback? onRetry;
  final Widget? loadingWidget;
  final bool showErrorDialog;

  const ApiResponseHandler({
    super.key,
    required this.response,
    required this.isLoading,
    required this.onSuccess,
    this.onError,
    this.onRetry,
    this.loadingWidget,
    this.showErrorDialog = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (response == null) {
      return const SizedBox.shrink();
    }

    return response!.when(
      success: onSuccess,
      error: (error) {
        if (showErrorDialog) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ErrorHandler.showErrorDialog(context, error);
          });
        }

        return onError?.call(error) ?? _defaultErrorWidget(context, error);
      },
    );
  }

  Widget _defaultErrorWidget(BuildContext context, NetworkException error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getErrorIcon(error.type), size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            error.message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }

  IconData _getErrorIcon(NetworkExceptionType type) {
    switch (type) {
      case NetworkExceptionType.noInternetConnection:
        return Icons.wifi_off;
      case NetworkExceptionType.requestTimeout:
      case NetworkExceptionType.sendTimeout:
      case NetworkExceptionType.receiveTimeout:
        return Icons.access_time;
      case NetworkExceptionType.notFound:
        return Icons.search_off;
      case NetworkExceptionType.unauthorizedRequest:
        return Icons.lock;
      case NetworkExceptionType.forbidden:
        return Icons.block;
      case NetworkExceptionType.internalServerError:
      case NetworkExceptionType.badGateway:
      case NetworkExceptionType.serviceUnavailable:
      case NetworkExceptionType.gatewayTimeout:
        return Icons.error_outline;
      default:
        return Icons.error;
    }
  }
}
