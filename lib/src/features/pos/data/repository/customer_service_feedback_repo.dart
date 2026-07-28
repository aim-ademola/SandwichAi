import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/model/customer_service_feedback_model.dart';

abstract class CustomerServiceFeedbackRepositoryInterface {
  Future<ApiResponse<CustomerServiceRecordList>> getComplaints({
    int page = 1,
    int limit = 10,
  });

  Future<ApiResponse<CustomerServiceRecord>> createComplaint(
    Map<String, dynamic> data,
  );

  Future<ApiResponse<CustomerServiceRecord>> updateComplaint(
    String id,
    Map<String, dynamic> data,
  );

  Future<ApiResponse<bool>> deleteComplaint(String id);

  Future<ApiResponse<CustomerServiceRecordList>> getReviews({
    int page = 1,
    int limit = 10,
  });

  Future<ApiResponse<CustomerServiceRecord>> createReview(
    Map<String, dynamic> data,
  );

  Future<ApiResponse<CustomerServiceRecord>> updateReview(
    String id,
    Map<String, dynamic> data,
  );

  Future<ApiResponse<bool>> deleteReview(String id);
}

class CustomerServiceFeedbackRepository extends BaseRepository
    implements CustomerServiceFeedbackRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<CustomerServiceRecordList>> getComplaints({
    int page = 1,
    int limit = 10,
  }) {
    return _getList('customer-service/Complaints', page: page, limit: limit);
  }

  @override
  Future<ApiResponse<CustomerServiceRecord>> createComplaint(
    Map<String, dynamic> data,
  ) {
    return _create('customer-service/Complaints', data);
  }

  @override
  Future<ApiResponse<CustomerServiceRecord>> updateComplaint(
    String id,
    Map<String, dynamic> data,
  ) {
    return _update('customer-service/Complaints/$id', data);
  }

  @override
  Future<ApiResponse<bool>> deleteComplaint(String id) {
    return _delete('customer-service/Complaints/$id');
  }

  @override
  Future<ApiResponse<CustomerServiceRecordList>> getReviews({
    int page = 1,
    int limit = 10,
  }) {
    return _getReviewsList(page: page, limit: limit);
  }

  @override
  Future<ApiResponse<CustomerServiceRecord>> createReview(
    Map<String, dynamic> data,
  ) async {
    final normalized = await _normalizeCreateReviewData(data);
    return _create('customer-service/reviews', normalized);
  }

  @override
  Future<ApiResponse<CustomerServiceRecord>> updateReview(
    String id,
    Map<String, dynamic> data,
  ) async {
    final normalized = _normalizeUpdateReviewData(data);
    return _update('customer-service/reviews/$id', normalized);
  }

  @override
  Future<ApiResponse<bool>> deleteReview(String id) {
    return _delete('customer-service/reviews/$id');
  }

  Future<ApiResponse<CustomerServiceRecordList>> _getList(
    String path, {
    required int page,
    required int limit,
    bool includeBranchId = true,
  }) async {
    try {
      final response = await _apiClient
          .get(
            path,
            queryParameters: await _listQuery(
              page: page,
              limit: limit,
              includeBranchId: includeBranchId,
            ),
          )
          .timeout(const Duration(seconds: 30));

      return response.when(
        success: (data) =>
            ApiResponse.success(CustomerServiceRecordList.fromJson(data)),
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
    } on FormatException catch (e) {
      return ApiResponse.errorMessage(e.message);
    } catch (e) {
      return ApiResponse.errorMessage(_messageFor(e));
    }
  }

  Future<ApiResponse<CustomerServiceRecordList>> _getReviewsList({
    required int page,
    required int limit,
  }) async {
    final branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    final response = await _getList(
      'customer-service/reviews',
      page: page,
      limit: limit,
    );

    return response.when(
      success: (records) async {
        if (records.data.isNotEmpty || branchId.trim().isEmpty) {
          return ApiResponse.success(records);
        }

        final fallback = await _getList(
          'customer-service/reviews',
          page: page,
          limit: limit,
          includeBranchId: false,
        );

        return fallback.when(
          success: (fallbackRecords) async {
            final branchReviews = fallbackRecords.data
                .where((record) => record.branchId == branchId.trim())
                .toList();

            if (branchReviews.isEmpty) return ApiResponse.success(records);

            return ApiResponse.success(
              fallbackRecords.copyWith(
                data: branchReviews,
                total: branchReviews.length,
                totalPages: branchReviews.isEmpty ? 0 : 1,
              ),
            );
          },
          error: (_) async => ApiResponse.success(records),
        );
      },
      error: (error) async => ApiResponse.error(error),
    );
  }

  Future<ApiResponse<CustomerServiceRecord>> _create(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient
          .post(path, data: data)
          .timeout(const Duration(seconds: 30));

      return response.when(
        success: (data) => ApiResponse.success(
          CustomerServiceRecord.fromJson(_unwrapRecord(data)),
        ),
        error: (error) => ApiResponse.error(error),
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      return ApiResponse.errorMessage(e.message);
    } catch (e) {
      return ApiResponse.errorMessage(_messageFor(e));
    }
  }

  Future<Map<String, dynamic>> _listQuery({
    required int page,
    required int limit,
    bool includeBranchId = true,
  }) async {
    final branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    return {
      'page': page,
      'limit': limit,
      if (includeBranchId && branchId.trim().isNotEmpty)
        'branchId': branchId.trim(),
    };
  }

  Future<ApiResponse<CustomerServiceRecord>> _update(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient
          .patch(path, data: data)
          .timeout(const Duration(seconds: 30));

      return response.when(
        success: (data) => ApiResponse.success(
          CustomerServiceRecord.fromJson(_unwrapRecord(data)),
        ),
        error: (error) => ApiResponse.error(error),
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      return ApiResponse.errorMessage(e.message);
    } catch (e) {
      return ApiResponse.errorMessage(_messageFor(e));
    }
  }

  Future<ApiResponse<bool>> _delete(String path) async {
    try {
      final response = await _apiClient
          .delete(path)
          .timeout(const Duration(seconds: 30));
      return response.when(
        success: (_) => ApiResponse.success(true),
        error: (error) => ApiResponse.error(error),
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } catch (e) {
      return ApiResponse.errorMessage(_messageFor(e));
    }
  }

  Future<Map<String, dynamic>> _normalizeCreateReviewData(
    Map<String, dynamic> data,
  ) async {
    final normalized = Map<String, dynamic>.from(data);
    final branchId = normalized['branchId']?.toString().trim();
    if (branchId == null || branchId.isEmpty) {
      normalized['branchId'] =
          await AuthCacheHelper.instance.getBranchID() ?? '';
    }

    final ratingSource = normalized['overallRating'] ?? normalized['rating'];
    final rating = _parseRating(ratingSource);
    if (rating == null) {
      throw const FormatException('Review rating must be between 1 and 5.');
    }

    normalized
      ..remove('rating')
      ..['overallRating'] = rating;

    return normalized;
  }

  Map<String, dynamic> _normalizeUpdateReviewData(Map<String, dynamic> data) {
    final normalized = <String, dynamic>{};
    for (final key in const [
      'sentiment',
      'responseText',
      'respondedBy',
      'isPublished',
      'isFlagged',
      'flagReason',
    ]) {
      final value = data[key];
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      normalized[key] = value is String ? value.trim() : value;
    }

    if (normalized.isEmpty) {
      throw const FormatException(
        'Please enter a response or moderation update.',
      );
    }

    return normalized;
  }

  num? _parseRating(dynamic value) {
    num? parsed;
    if (value is num) {
      parsed = value;
    } else if (value is String) {
      parsed = num.tryParse(value);
    }

    if (parsed == null || parsed < 1 || parsed > 5) return null;
    return parsed;
  }

  Map<String, dynamic> _unwrapRecord(dynamic response) {
    if (response is Map<String, dynamic>) {
      final record = response['data'] ?? response['record'] ?? response;
      if (record is Map<String, dynamic>) return record;
      if (record is Map) return Map<String, dynamic>.from(record);
    }
    if (response is Map) return Map<String, dynamic>.from(response);
    throw const FormatException('Invalid record response format');
  }

  String _messageFor(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'] ?? data['error'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }

      if (error.message?.trim().isNotEmpty == true) {
        return error.message!;
      }
    }

    final message = error.toString();
    return message.isEmpty ? 'An error occurred. Please try again.' : message;
  }
}
