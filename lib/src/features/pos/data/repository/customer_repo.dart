import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart'; // Add this import
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base-repo.dart';
import 'package:sandwich_ai/src/features/pos/data/model/customer_model.dart';

abstract class CustomerRepositoryInterface {
  Future<ApiResponse<CustomersListResponse>> getCustomers({
    int page = 1,
    int limit = 10,
    String? search,
  });

  Future<ApiResponse<CustomerModel>> getCustomerById(String id);

  Future<ApiResponse<CustomerModel>> createCustomer({
    required String phone,
    required String email,
    required String name,
    String? dateOfBirth,
    String? address,
    String? city,
    String? dietaryRestrictions,
    bool? allowsMarketing,
    bool? allowsSMS,
    bool? allowsEmail,
  });

  Future<ApiResponse<CustomerModel>> updateCustomer({
    required String id,
    String? phone,
    String? email,
    String? name,
    String? dateOfBirth,
    String? address,
    String? city,
    String? dietaryRestrictions,
    bool? allowsMarketing,
    bool? allowsSMS,
    bool? allowsEmail,
  });

  Future<ApiResponse<bool>> deleteCustomer(String id);
}

class CustomerRepository extends BaseRepository
    implements CustomerRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<CustomersListResponse>> getCustomers({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      // final Map<String, dynamic> queryParams = {'page': page, 'limit': limit};

      // if (search != null && search.isNotEmpty) {
      //   queryParams['search'] = search;
      // }

      final response = await _apiClient
          .get('customer-service/customers')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      if (response.data == null) {
        return ApiResponse.errorMessage('Failed to fetch customers');
      }

      AppLogger.log('API Response: ${response.data}');

      final customersResponse = CustomersListResponse.fromJson(response.data);
      return ApiResponse.success(customersResponse);
    } on DioException catch (e) {
      return ApiResponse.errorMessage(_handleDioError(e));
    } on SocketException catch (e) {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException catch (e) {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      return ApiResponse.errorMessage(e.message);
    } catch (e) {
      AppLogger.log('Error in getCustomers: $e');
      return ApiResponse.errorMessage(_parseErrorMessage(e));
    }
  }

  @override
  Future<ApiResponse<CustomerModel>> getCustomerById(String id) async {
    try {
      _validateId(id);

      final response = await _apiClient
          .get('customer-service/customers/$id')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      if (response.data == null) {
        return ApiResponse.errorMessage('Customer not found');
      }

      final customer = CustomerModel.fromJson(response.data);
      return ApiResponse.success(customer);
    } on DioException catch (e) {
      return ApiResponse.errorMessage(_handleDioError(e));
    } on SocketException catch (e) {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException catch (e) {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      return ApiResponse.errorMessage(e.message);
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e));
    }
  }

  @override
  Future<ApiResponse<CustomerModel>> createCustomer({
    required String phone,
    required String email,
    required String name,
    String? dateOfBirth,
    String? address,
    String? city,
    String? dietaryRestrictions,
    bool? allowsMarketing,
    bool? allowsSMS,
    bool? allowsEmail,
  }) async {
    try {
      _validateCustomerData(phone: phone, email: email, name: name);

      final Map<String, dynamic> data = {
        'phone': phone,
        'email': email,
        'name': name,
      };

      if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
        data['dateOfBirth'] = dateOfBirth;
      }
      if (address != null && address.isNotEmpty) {
        data['address'] = address;
      }
      if (city != null && city.isNotEmpty) {
        data['city'] = city;
      }
      if (dietaryRestrictions != null && dietaryRestrictions.isNotEmpty) {
        data['dietaryRestrictions'] = dietaryRestrictions;
      }
      if (allowsMarketing != null) {
        data['allowsMarketing'] = allowsMarketing;
      }
      if (allowsSMS != null) {
        data['allowsSMS'] = allowsSMS;
      }
      if (allowsEmail != null) {
        data['allowsEmail'] = allowsEmail;
      }

      AppLogger.log('Creating customer with data: $data');

      final response = await _apiClient
          .post('customer-service/customers', data: data)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      AppLogger.log('Create customer response: ${response.data}');

      if (response.data == null) {
        return ApiResponse.errorMessage('Failed to create customer');
      }

      final customer = CustomerModel.fromJson(response.data);
      return ApiResponse.success(customer);
    } on DioException catch (e) {
      AppLogger.log('DioException in createCustomer: ${e.response?.data}');
      return ApiResponse.errorMessage(_handleDioError(e));
    } on SocketException catch (e) {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException catch (e) {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      return ApiResponse.errorMessage(e.message);
    } catch (e) {
      AppLogger.log('Exception in createCustomer: $e');
      return ApiResponse.errorMessage(_parseErrorMessage(e));
    }
  }

  @override
  Future<ApiResponse<CustomerModel>> updateCustomer({
    required String id,
    String? phone,
    String? email,
    String? name,
    String? dateOfBirth,
    String? address,
    String? city,
    String? dietaryRestrictions,
    bool? allowsMarketing,
    bool? allowsSMS,
    bool? allowsEmail,
  }) async {
    try {
      _validateId(id);

      final Map<String, dynamic> data = {};

      if (phone != null && phone.isNotEmpty) {
        data['phone'] = phone;
      }
      if (email != null && email.isNotEmpty) {
        data['email'] = email;
      }
      if (name != null && name.isNotEmpty) {
        data['name'] = name;
      }
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
        data['dateOfBirth'] = dateOfBirth;
      }
      if (address != null && address.isNotEmpty) {
        data['address'] = address;
      }
      if (city != null && city.isNotEmpty) {
        data['city'] = city;
      }
      if (dietaryRestrictions != null && dietaryRestrictions.isNotEmpty) {
        data['dietaryRestrictions'] = dietaryRestrictions;
      }
      if (allowsMarketing != null) {
        data['allowsMarketing'] = allowsMarketing;
      }
      if (allowsSMS != null) {
        data['allowsSMS'] = allowsSMS;
      }
      if (allowsEmail != null) {
        data['allowsEmail'] = allowsEmail;
      }

      final response = await _apiClient
          .patch('customer-service/customers/$id', data: data)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      if (response.data == null) {
        return ApiResponse.errorMessage('Failed to update customer');
      }

      final customer = CustomerModel.fromJson(response.data);
      return ApiResponse.success(customer);
    } on DioException catch (e) {
      return ApiResponse.errorMessage(_handleDioError(e));
    } on SocketException catch (e) {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException catch (e) {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      return ApiResponse.errorMessage(e.message);
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e));
    }
  }

  @override
  Future<ApiResponse<bool>> deleteCustomer(String id) async {
    try {
      _validateId(id);

      await _apiClient
          .delete('customer-service/customers/$id')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return ApiResponse.success(true);
    } on DioException catch (e) {
      return ApiResponse.errorMessage(_handleDioError(e));
    } on SocketException catch (e) {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException catch (e) {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      return ApiResponse.errorMessage(e.message);
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e));
    }
  }

  // Validation methods
  void _validateId(String id) {
    if (id.isEmpty) {
      throw FormatException('Customer ID cannot be empty');
    }
  }

  void _validateCustomerData({
    required String phone,
    required String email,
    required String name,
  }) {
    if (phone.isEmpty) {
      throw FormatException('Phone number cannot be empty');
    }
    if (email.isEmpty) {
      throw FormatException('Email cannot be empty');
    }
    if (name.isEmpty) {
      throw FormatException('Name cannot be empty');
    }
  }

  // Handle DioException specifically
  String _handleDioError(DioException error) {
    AppLogger.log('DioException type: ${error.type}');
    AppLogger.log('DioException response: ${error.response?.data}');

    // Check if there's a response with error data
    if (error.response?.data != null) {
      try {
        final errorData = error.response!.data;

        // If it's already a Map
        if (errorData is Map<String, dynamic> && errorData['message'] != null) {
          return errorData['message'].toString();
        }

        // If it's a String, try to parse it as JSON
        if (errorData is String) {
          final parsed = json.decode(errorData) as Map<String, dynamic>;
          if (parsed['message'] != null) {
            return parsed['message'].toString();
          }
        }
      } catch (e) {
        AppLogger.log('Error parsing DioException response: $e');
      }
    }

    // Fallback to status code based messages
    switch (error.response?.statusCode) {
      case 401:
        return 'Unauthorized access. Please login again.';
      case 403:
        return 'Access denied. You do not have permission.';
      case 404:
        return 'Customer not found.';
      case 409:
        return 'Customer with this phone or email already exists.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return _parseErrorMessage(error.toString());
    }
  }

  // Parse error response from various formats
  Map<String, dynamic>? _parseErrorResponse(dynamic error) {
    try {
      if (error is Map<String, dynamic>) {
        return error;
      }

      final errorString = error.toString();
      if (errorString.contains('{') && errorString.contains('}')) {
        final jsonStart = errorString.indexOf('{');
        final jsonEnd = errorString.lastIndexOf('}') + 1;
        final jsonString = errorString.substring(jsonStart, jsonEnd);
        return json.decode(jsonString) as Map<String, dynamic>;
      }
    } catch (e) {
      AppLogger.log('Error parsing error response: $e');
    }
    return null;
  }

  // Generic error message parser
  String _parseErrorMessage(dynamic error) {
    final errorData = _parseErrorResponse(error);
    if (errorData != null && errorData['message'] != null) {
      return errorData['message'].toString();
    }

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Unauthorized access. Please login again.';
    }
    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'Access denied. You do not have permission.';
    }
    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Customer not found.';
    }
    if (errorString.contains('409') || errorString.contains('conflict')) {
      return 'Customer with this phone or email already exists.';
    }
    if (errorString.contains('500') ||
        errorString.contains('internal server')) {
      return 'Server error. Please try again later.';
    }
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error. Please check your connection.';
    }
    if (errorString.contains('timeout')) {
      return 'Request timeout. Please try again.';
    }

    return 'An error occurred. Please try again.';
  }
}
