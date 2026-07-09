import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base_repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/supplier_model.dart';

abstract class SupplierRepositoryInterface {
  Future<ApiResponse<List<SupplierResponse>>> getSuppliers({
    String? status,
    String? supplierType,
    String? city,
    String? state,
    String? country,
    bool? isVerified,
    String? search,
    double? minRating,
    int page = 1,
    int limit = 10,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  });

  Future<ApiResponse<List<SupplierProductResponse>>> getSupplierProducts({
    required String supplierId,
    String? search,
    String? category,
    String? status,
    bool? isActive,
    bool? isFeatured,
    double? minPrice,
    double? maxPrice,
    int page = 1,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  });
}

class SupplierRepository extends BaseRepository
    implements SupplierRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<List<SupplierResponse>>> getSuppliers({
    String? status,
    String? supplierType,
    String? city,
    String? state,
    String? country,
    bool? isVerified,
    String? search,
    double? minRating,
    int page = 1,
    int limit = 10,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (supplierType != null && supplierType.isNotEmpty) {
        queryParams['supplierType'] = supplierType;
      }
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (state != null && state.isNotEmpty) queryParams['state'] = state;
      if (country != null && country.isNotEmpty) {
        queryParams['country'] = country;
      }
      if (isVerified != null) queryParams['isVerified'] = isVerified;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (minRating != null) queryParams['minRating'] = minRating;

      final response = await _apiClient
          .get(
            'suppliers',
            //  queryParameters: queryParams,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      // Check for error response
      if (response.data is Map && response.data['statusCode'] != null) {
        final statusCode = response.data['statusCode'];
        if (statusCode >= 400) {
          return ApiResponse.errorMessage(
            _parseErrorFromResponse(response.data),
          );
        }
      }

      final listResponse = await handleListResponse<SupplierResponse>(
        Future.value(ApiResponse.success(response.data)),
        (json) => SupplierResponse.fromJson(json),
      );

      return listResponse;
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      return ApiResponse.errorMessage(e.message);
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<List<SupplierProductResponse>>> getSupplierProducts({
    required String supplierId,
    String? search,
    String? category,
    String? status,
    bool? isActive,
    bool? isFeatured,
    double? minPrice,
    double? maxPrice,
    int page = 1,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    try {
      _validateSupplierId(supplierId);

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (isActive != null) queryParams['isActive'] = isActive;
      if (isFeatured != null) queryParams['isFeatured'] = isFeatured;
      if (minPrice != null) queryParams['minPrice'] = minPrice;
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice;

      final response = await _apiClient
          .get(
            'suppliers/$supplierId/products',
            //  queryParameters: queryParams
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      // Check for error response
      if (response.data is Map && response.data['statusCode'] != null) {
        final statusCode = response.data['statusCode'];
        if (statusCode >= 400) {
          return ApiResponse.errorMessage(
            _parseErrorFromResponse(response.data),
          );
        }
      }

      final listResponse = await handleListResponse<SupplierProductResponse>(
        Future.value(ApiResponse.success(response.data)),
        (json) => SupplierProductResponse.fromJson(json),
      );

      return listResponse;
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      return ApiResponse.errorMessage(e.message);
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  void _validateSupplierId(String supplierId) {
    if (supplierId.isEmpty) {
      throw FormatException('Supplier ID cannot be empty');
    }
  }

  String _parseErrorFromResponse(Map<String, dynamic> data) {
    final statusCode = data['statusCode'];
    final message = data['message'] ?? 'An error occurred';

    if (statusCode == 500) {
      return 'Server error. Please try again later.';
    } else if (statusCode == 404) {
      return 'Resource not found.';
    } else if (statusCode == 401) {
      return 'Unauthorized. Please login again.';
    } else if (statusCode == 403) {
      return 'Access forbidden.';
    }

    return message;
  }

  String _parseErrorMessage(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('401') ||
        lowercaseError.contains('unauthorized')) {
      return 'Unauthorized access. Please login again.';
    }

    if (lowercaseError.contains('403') ||
        lowercaseError.contains('forbidden')) {
      return 'Access denied. Please contact support.';
    }

    if (lowercaseError.contains('404') ||
        lowercaseError.contains('not found')) {
      return 'Suppliers not found.';
    }

    if (lowercaseError.contains('500') ||
        lowercaseError.contains('internal server')) {
      return 'Server error. Please try again later.';
    }

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection')) {
      return 'Network error. Please check your connection.';
    }

    if (lowercaseError.contains('timeout')) {
      return 'Request timeout. Please try again.';
    }

    return 'Failed to load suppliers. Please try again later.';
  }
}
