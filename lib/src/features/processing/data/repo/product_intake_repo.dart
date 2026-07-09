import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/network_exception.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/model/product_intake_model.dart';

abstract class ProductIntakeRepositoryInterface {
  Future<ApiResponse<ProductIntake>> createProductIntake(
    CreateProductIntakeRequest request,
  );

  Future<ApiResponse<List<ProductIntake>>> getProductIntakes();
}

class ProductIntakeRepository extends BaseRepository
    implements ProductIntakeRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<ProductIntake>> createProductIntake(
    CreateProductIntakeRequest request,
  ) async {
    try {
      final response = await _apiClient
          .post('processing/product-intakes', data: request.toJson())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return response.when(
        success: (data) {
          try {
            final intake = ProductIntake.fromJson(data as Map<String, dynamic>);
            return ApiResponse.success(intake);
          } catch (e) {
            return ApiResponse.error(
              NetworkException.formatException(
                'Failed to parse product intake: $e',
              ),
            );
          }
        },
        error: (error) => ApiResponse.error(error),
      );
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } catch (e) {
      return ApiResponse.errorMessage(
        'Failed to create product intake. Please try again later.',
      );
    }
  }

  @override
  Future<ApiResponse<List<ProductIntake>>> getProductIntakes() async {
    try {
      final response = await _apiClient
          .get('processing/product-intakes')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return response.when(
        success: (data) {
          try {
            final List<dynamic> intakesList = data as List<dynamic>;
            final intakes = intakesList
                .map(
                  (item) =>
                      ProductIntake.fromJson(item as Map<String, dynamic>),
                )
                .toList();
            return ApiResponse.success(intakes);
          } catch (e) {
            return ApiResponse.error(
              NetworkException.formatException(
                'Failed to parse product intakes: $e',
              ),
            );
          }
        },
        error: (error) => ApiResponse.error(error),
      );
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } catch (e) {
      return ApiResponse.errorMessage(
        'Failed to load product intakes. Please try again later.',
      );
    }
  }
}
