import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base-repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/processing_transfer_model.dart';

abstract class ProcessingTransferRepositoryInterface {
  Future<ApiResponse<ProcessingTransferResponse>> createTransfer(
    ProcessingTransferRequest request,
  );

  Future<ApiResponse<List<ProcessingTransferResponse>>> getTransfers({
    required String branchId,
    String? status,
  });
  Future<ApiResponse<ProcessingTransferResponse>> receiveTransfer({
    required String transferId,
    required ReceiveTransferRequest request,
  });
  Future<ApiResponse<Map<String, dynamic>>> completeStockRequest({
    required String requestId,
  });
}

class ProcessingTransferRepository extends BaseRepository
    implements ProcessingTransferRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<Map<String, dynamic>>> completeStockRequest({
    required String requestId,
  }) async {
    try {
      if (requestId.isEmpty) {
        throw FormatException('Request ID is required');
      }

      AppLogger.log('=== COMPLETE STOCK REQUEST ===');
      AppLogger.log('Request ID: $requestId');
      AppLogger.log('Endpoint: /stock-requests/$requestId/complete');
      AppLogger.log('==============================');

      final response = await _apiClient
          .patch('/stock-requests/$requestId/complete')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      AppLogger.log('=== COMPLETE REQUEST RESPONSE ===');
      AppLogger.log('Response type: ${response.runtimeType}');
      AppLogger.log('=================================');

      return response.when(
        success: (data) {
          try {
            return ApiResponse.success(data as Map<String, dynamic>);
          } catch (e, stackTrace) {
            AppLogger.log('Error parsing response: $e');
            AppLogger.log('Stack trace: $stackTrace');
            return ApiResponse.errorMessage(
              'Failed to parse server response: $e',
            );
          }
        },
        error: (error) {
          AppLogger.log('Error response: $error');
          return ApiResponse.errorMessage(_parseErrorMessage(error.toString()));
        },
      );
    } on SocketException catch (e) {
      AppLogger.log('SocketException: $e');
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException catch (e) {
      AppLogger.log('TimeoutException: $e');
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      AppLogger.log('FormatException: $e');
      return ApiResponse.errorMessage('Invalid data format. ${e.message}');
    } catch (e, stackTrace) {
      AppLogger.log('General Exception: $e');
      AppLogger.log('Stack trace: $stackTrace');
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<ProcessingTransferResponse>> receiveTransfer({
    required String transferId,
    required ReceiveTransferRequest request,
  }) async {
    try {
      if (transferId.isEmpty) {
        throw FormatException('Transfer ID is required');
      }

      if (request.receivedBy.isEmpty) {
        throw FormatException('Receiver information is required');
      }

      if (request.items.isEmpty) {
        throw FormatException('At least one item is required');
      }

      for (final item in request.items) {
        if (item.itemId.isEmpty) {
          throw FormatException('Item ID is required for all items');
        }
        if (item.qtyReceived < 0) {
          throw FormatException('Quantity received cannot be negative');
        }
      }

      AppLogger.log('=== RECEIVE TRANSFER REQUEST ===');
      AppLogger.log('Transfer ID: $transferId');
      AppLogger.log(
        'Endpoint: kitchen/processing-transfers/$transferId/receive',
      );
      AppLogger.log('Request Data: ${request.toJson()}');
      AppLogger.log('===============================');

      final response = await _apiClient
          .patch(
            'kitchen/processing-transfers/$transferId/receive',
            data: request.toJson(),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      AppLogger.log('=== RECEIVE TRANSFER RESPONSE ===');
      AppLogger.log('Response type: ${response.runtimeType}');
      AppLogger.log('=================================');

      return response.when(
        success: (data) {
          try {
            final transferResponse = ProcessingTransferResponse.fromJson(
              data as Map<String, dynamic>,
            );
            return ApiResponse.success(transferResponse);
          } catch (e, stackTrace) {
            AppLogger.log('Error parsing response: $e');
            AppLogger.log('Stack trace: $stackTrace');
            return ApiResponse.errorMessage(
              'Failed to parse server response: $e',
            );
          }
        },
        error: (error) {
          AppLogger.log('Error response: $error');
          return ApiResponse.errorMessage(_parseErrorMessage(error.toString()));
        },
      );

      return handleObjectResponse(
        Future.value(response),
        (json) => ProcessingTransferResponse.fromJson(json),
      );
    } on SocketException catch (e) {
      AppLogger.log('SocketException: $e');
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException catch (e) {
      AppLogger.log('TimeoutException: $e');
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      AppLogger.log('FormatException: $e');
      return ApiResponse.errorMessage('Invalid data format. ${e.message}');
    } catch (e, stackTrace) {
      AppLogger.log('General Exception: $e');
      AppLogger.log('Stack trace: $stackTrace');
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<ProcessingTransferResponse>> createTransfer(
    ProcessingTransferRequest request,
  ) async {
    try {
      _validateTransferRequest(request);

      AppLogger.log('=== API REQUEST ===');
      AppLogger.log('Endpoint: kitchen/processing-transfers');
      AppLogger.log('Request Data: ${request.toJson()}');
      AppLogger.log('==================');

      final response = await _apiClient
          .post('kitchen/processing-transfers', data: request.toJson())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      AppLogger.log('=== API RESPONSE ===');
      AppLogger.log('Response: $response');
      AppLogger.log('Response type: ${response.runtimeType}');
      AppLogger.log('===================');

      // Check if response is already an ApiResponse
      AppLogger.log('=== RESPONSE IS ApiResponse ===');
      return response.when(
        success: (data) {
          AppLogger.log('Success data: $data');
          AppLogger.log('Data type: ${data.runtimeType}');

          try {
            // Parse the data into ProcessingTransferResponse
            final transferResponse = ProcessingTransferResponse.fromJson(
              data as Map<String, dynamic>,
            );
            return ApiResponse.success(transferResponse);
          } catch (e, stackTrace) {
            AppLogger.log('Error parsing response: $e');
            AppLogger.log('Stack trace: $stackTrace');
            return ApiResponse.errorMessage(
              'Failed to parse server response: $e',
            );
          }
        },
        error: (error) {
          AppLogger.log('=== ERROR RESPONSE ===');
          AppLogger.log('Error: $error');
          AppLogger.log('Error type: ${error.runtimeType}');
          AppLogger.log('=====================');

          // Extract meaningful error message
          String errorMessage = error.toString();

          // Try to parse if it's a JSON string
          try {
            if (error is Map) {
              final errorMap = error as Map<String, dynamic>;
              if (errorMap.containsKey('message')) {
                errorMessage = errorMap['message'].toString();
              } else if (errorMap.containsKey('error')) {
                errorMessage = errorMap['error'].toString();
              }

              // Check for specific status codes
              if (errorMap.containsKey('statusCode')) {
                final statusCode = errorMap['statusCode'];
                AppLogger.log('Status Code: $statusCode');

                if (statusCode == 500) {
                  errorMessage =
                      'Server error: The backend encountered an issue processing your request. This may be due to:\n• Invalid item IDs\n• Missing required data\n• Database constraints\n\nPlease contact support if this persists.';
                }
              }
            }
          } catch (e) {
            AppLogger.log('Could not parse error details: $e');
          }

          return ApiResponse.errorMessage(_parseErrorMessage(errorMessage));
        },
      );

      // If response is raw data (Map), wrap it
      AppLogger.log('=== RESPONSE IS RAW DATA ===');
      return handleObjectResponse(
        Future.value(response),
        (json) => ProcessingTransferResponse.fromJson(json),
      );
    } on SocketException catch (e) {
      AppLogger.log('SocketException: $e');
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException catch (e) {
      AppLogger.log('TimeoutException: $e');
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      AppLogger.log('FormatException: $e');
      return ApiResponse.errorMessage('Invalid data format. ${e.message}');
    } catch (e, stackTrace) {
      AppLogger.log('General Exception: $e');
      AppLogger.log('Stack trace: $stackTrace');
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<List<ProcessingTransferResponse>>> getTransfers({
    required String branchId,
    String? status,
  }) async {
    try {
      _validateBranchId(branchId);

      final queryParams = <String, String>{
        'branchId': branchId,
        if (status != null && status.isNotEmpty) 'status': status,
      };

      AppLogger.log('=== GET TRANSFERS REQUEST ===');
      AppLogger.log('Query params: $queryParams');
      AppLogger.log('============================');

      final response = await _apiClient
          .get('kitchen/processing-transfers', queryParameters: queryParams)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      AppLogger.log('=== GET TRANSFERS RESPONSE ===');
      AppLogger.log('Response type: ${response.runtimeType}');
      AppLogger.log('=============================');

      // Check if response is already an ApiResponse
      return response.when(
        success: (data) {
          try {
            final List<dynamic> listData = data as List<dynamic>;
            final transfers = listData
                .map(
                  (item) => ProcessingTransferResponse.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList();
            return ApiResponse.success(transfers);
          } catch (e, stackTrace) {
            AppLogger.log('Error parsing list response: $e');
            AppLogger.log('Stack trace: $stackTrace');
            return ApiResponse.errorMessage(
              'Failed to parse server response: $e',
            );
          }
        },
        error: (error) {
          return ApiResponse.errorMessage(error.toString());
        },
      );

      // If response is raw data, wrap it
      return handleListResponse(
        Future.value(response),
        (json) => ProcessingTransferResponse.fromJson(json),
      );
    } on SocketException catch (e) {
      AppLogger.log('SocketException: $e');
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException catch (e) {
      AppLogger.log('TimeoutException: $e');
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      AppLogger.log('FormatException: $e');
      return ApiResponse.errorMessage('Invalid response format. ${e.message}');
    } catch (e, stackTrace) {
      AppLogger.log('General Exception: $e');
      AppLogger.log('Stack trace: $stackTrace');
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  void _validateBranchId(String branchId) {
    if (branchId.isEmpty) {
      throw FormatException('Branch ID cannot be empty');
    }
  }

  void _validateTransferRequest(ProcessingTransferRequest request) {
    if (request.branchId.isEmpty) {
      throw FormatException('Branch ID is required. Please restart the app.');
    }
    if (request.batchCode.isEmpty) {
      throw FormatException('Batch code is required');
    }
    if (request.sentBy.isEmpty) {
      throw FormatException('Employee ID is required. Please restart the app.');
    }
    if (request.items.isEmpty) {
      throw FormatException('At least one item is required');
    }
    for (final item in request.items) {
      if (item.itemId.isEmpty) {
        throw FormatException('Item ID is required for all items');
      }
      if (item.qtySent <= 0) {
        throw FormatException('Quantity must be greater than 0 for all items');
      }
    }
  }

  String _parseErrorMessage(String error) {
    final lowercaseError = error.toLowerCase();

    // Check for specific status codes first
    if (lowercaseError.contains('401') ||
        lowercaseError.contains('unauthorized')) {
      return 'Unauthorized access. Please login again.';
    }

    if (lowercaseError.contains('403') ||
        lowercaseError.contains('forbidden')) {
      return 'Access denied. You do not have permission for this action.';
    }

    if (lowercaseError.contains('404') ||
        lowercaseError.contains('not found')) {
      return 'Resource not found. Please check your data.';
    }

    if (lowercaseError.contains('422') ||
        lowercaseError.contains('unprocessable')) {
      return 'Invalid data provided. Please check your input.';
    }

    if (lowercaseError.contains('429') ||
        lowercaseError.contains('too many requests')) {
      return 'Too many requests. Please try again later.';
    }

    if (lowercaseError.contains('500') ||
        lowercaseError.contains('internal server')) {
      return 'Server error. This may be a data validation issue. Please check all required fields and try again.';
    }

    if (lowercaseError.contains('503') ||
        lowercaseError.contains('service unavailable')) {
      return 'Service temporarily unavailable. Please try again in a few moments.';
    }

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection')) {
      return 'Network error. Please check your connection.';
    }

    if (lowercaseError.contains('timeout')) {
      return 'Request timeout. Please try again.';
    }

    if (lowercaseError.contains('format') || lowercaseError.contains('parse')) {
      return 'Invalid response format. Please try again.';
    }

    // Return the original error if no pattern matches
    return 'Failed to process transfer: $error';
  }
}
