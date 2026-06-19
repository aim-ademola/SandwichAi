import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sandwich_ai/src/core/globals/chat/data/model/cht_model.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base-repo.dart';

abstract class ChatRepositoryInterface {
  /// GET /chat/rooms
  Future<ApiResponse<List<ChatRoomModel>>> getChatRooms({
    String? type,
    String? branchId,
    bool includeArchived = false,
    bool starredOnly = false,
  });

  /// GET /chat/rooms/{roomId}
  Future<ApiResponse<ChatRoomModel>> getChatRoom({required String roomId});

  /// PUT /chat/rooms/{roomId}/settings
  Future<ApiResponse<void>> updateRoomSettings({
    required String roomId,
    required UpdateRoomSettingsRequest request,
  });

  /// GET /chat/unread
  Future<ApiResponse<List<UnreadCountModel>>> getUnreadCounts();

  /// POST /chat/read
  Future<ApiResponse<void>> markAsRead({required MarkReadRequest request});

  /// PUT /chat/presence
  Future<ApiResponse<void>> updatePresence({
    required UpdatePresenceRequest request,
  });

  /// GET /chat/messages/search
  Future<ApiResponse<List<ChatMessageModel>>> searchMessages({
    required String query,
    String? chatRoomId,
    String? senderId,
    int limit = 20,
  });

  /// GET /chat/messages
  Future<ApiResponse<List<ChatMessageModel>>> getMessages({
    required String chatRoomId,
    int limit = 50,
    String? cursor,
    String? parentMessageId,
  });

  /// POST /chat/messages
  Future<ApiResponse<ChatMessageModel>> sendMessage({
    required SendMessageRequest request,
  });
}

class ChatRepository extends BaseRepository implements ChatRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<List<ChatRoomModel>>> getChatRooms({
    String? type,
    String? branchId,
    bool includeArchived = false,
    bool starredOnly = false,
  }) async {
    try {
      final response = await _apiClient
          .get(
            'chat/rooms',
            queryParameters: {
              if (type != null) 'type': type,
              if (branchId != null) 'branchId': branchId,
              'includeArchived': includeArchived,
              'starredOnly': starredOnly,
            },
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      // ✅ Use .when() like KitchenDashboardRepository does
      return response.when(
        success: (data) {
          if (data == null)
            return ApiResponse.errorMessage('Failed to fetch chat rooms');
          final list = (data as List<dynamic>)
              .map((e) => ChatRoomModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return ApiResponse.success(list);
        },
        error: (error) => ApiResponse.errorMessage(error.toString()),
      );
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on DioException catch (e) {
      return ApiResponse.errorMessage(_parseDioError(e));
    } catch (e) {
      return ApiResponse.errorMessage(_parseError(e.toString()));
    }
  }

  @override
  Future<ApiResponse<ChatRoomModel>> getChatRoom({
    required String roomId,
  }) async {
    try {
      final response = await _apiClient
          .get('chat/rooms/$roomId')
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return response.when(
        success: (data) {
          if (data == null)
            return ApiResponse.errorMessage('Failed to fetch chat room');
          return ApiResponse.success(
            ChatRoomModel.fromJson(data as Map<String, dynamic>),
          );
        },
        error: (error) => ApiResponse.errorMessage(error.toString()),
      );
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on DioException catch (e) {
      return ApiResponse.errorMessage(_parseDioError(e));
    } catch (e) {
      return ApiResponse.errorMessage(_parseError(e.toString()));
    }
  }

  @override
  Future<ApiResponse<List<UnreadCountModel>>> getUnreadCounts() async {
    try {
      final response = await _apiClient
          .get('chat/unread')
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return response.when(
        success: (data) {
          if (data == null)
            return ApiResponse.errorMessage('Failed to fetch unread counts');
          final list = (data as List<dynamic>)
              .map((e) => UnreadCountModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return ApiResponse.success(list);
        },
        error: (error) => ApiResponse.errorMessage(error.toString()),
      );
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on DioException catch (e) {
      return ApiResponse.errorMessage(_parseDioError(e));
    } catch (e) {
      return ApiResponse.errorMessage(_parseError(e.toString()));
    }
  }

  @override
  Future<ApiResponse<List<ChatMessageModel>>> searchMessages({
    required String query,
    String? chatRoomId,
    String? senderId,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient
          .get(
            'chat/messages/search',
            queryParameters: {
              'query': query,
              if (chatRoomId != null) 'chatRoomId': chatRoomId,
              if (senderId != null) 'senderId': senderId,
              'limit': limit,
            },
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return response.when(
        success: (data) {
          if (data == null) return ApiResponse.errorMessage('No results found');
          final list = (data as List<dynamic>)
              .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return ApiResponse.success(list);
        },
        error: (error) => ApiResponse.errorMessage(error.toString()),
      );
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on DioException catch (e) {
      return ApiResponse.errorMessage(_parseDioError(e));
    } catch (e) {
      return ApiResponse.errorMessage(_parseError(e.toString()));
    }
  }

  @override
  Future<ApiResponse<List<ChatMessageModel>>> getMessages({
    required String chatRoomId,
    int limit = 50,
    String? cursor,
    String? parentMessageId,
  }) async {
    try {
      final response = await _apiClient
          .get(
            'chat/messages',
            queryParameters: {
              'chatRoomId': chatRoomId,
              'limit': limit,
              if (cursor != null) 'cursor': cursor,
              if (parentMessageId != null) 'parentMessageId': parentMessageId,
            },
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return response.when(
        success: (data) {
          if (data == null)
            return ApiResponse.errorMessage('Failed to load messages');
          final list = (data as List<dynamic>)
              .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return ApiResponse.success(list);
        },
        error: (error) => ApiResponse.errorMessage(error.toString()),
      );
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on DioException catch (e) {
      return ApiResponse.errorMessage(_parseDioError(e));
    } catch (e) {
      return ApiResponse.errorMessage(_parseError(e.toString()));
    }
  }

  @override
  Future<ApiResponse<ChatMessageModel>> sendMessage({
    required SendMessageRequest request,
  }) async {
    try {
      final response = await _apiClient
          .post('chat/messages', data: request.toJson())
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return response.when(
        success: (data) {
          if (data == null)
            return ApiResponse.errorMessage('Failed to send message');
          return ApiResponse.success(
            ChatMessageModel.fromJson(data as Map<String, dynamic>),
          );
        },
        error: (error) => ApiResponse.errorMessage(error.toString()),
      );
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on DioException catch (e) {
      return ApiResponse.errorMessage(_parseDioError(e));
    } catch (e) {
      return ApiResponse.errorMessage(_parseError(e.toString()));
    }
  }

  @override
  Future<ApiResponse<void>> updateRoomSettings({
    required String roomId,
    required UpdateRoomSettingsRequest request,
  }) async {
    try {
      await _apiClient
          .put('chat/rooms/$roomId/settings', data: request.toJson())
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return ApiResponse.success(null);
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on DioException catch (e) {
      return ApiResponse.errorMessage(_parseDioError(e));
    } catch (e) {
      return ApiResponse.errorMessage(_parseError(e.toString()));
    }
  }

  @override
  Future<ApiResponse<void>> markAsRead({
    required MarkReadRequest request,
  }) async {
    try {
      await _apiClient
          .post('chat/read', data: request.toJson())
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return ApiResponse.success(null);
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on DioException catch (e) {
      return ApiResponse.errorMessage(_parseDioError(e));
    } catch (e) {
      return ApiResponse.errorMessage(_parseError(e.toString()));
    }
  }

  @override
  Future<ApiResponse<void>> updatePresence({
    required UpdatePresenceRequest request,
  }) async {
    try {
      await _apiClient
          .put('chat/presence', data: request.toJson())
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return ApiResponse.success(null);
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on DioException catch (e) {
      return ApiResponse.errorMessage(_parseDioError(e));
    } catch (e) {
      return ApiResponse.errorMessage(_parseError(e.toString()));
    }
  }

  // ─── Error helpers ──────────────────────────────────────────────────────────

  String _parseDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet and try again.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please check your network settings.';
    }

    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    //  Extract raw message from body first
    String? rawMessage;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        rawMessage = message;
      } else if (message is List && message.isNotEmpty) {
        rawMessage = message.map((m) => m.toString()).join(', ');
      }
      // fallback to 'error' field if 'message' is absent
      rawMessage ??= data['error']?.toString();
    } else if (data is String && data.isNotEmpty) {
      rawMessage = data;
    }

    rawMessage ??= e.message;

    return _parseErrorMessage(rawMessage ?? '', statusCode: statusCode);
  }

  String _parseErrorMessage(String error, {int? statusCode}) {
    const fallback = 'An error occurred. Please try again.';
    final code = statusCode ?? 0;
    final lower = error.toLowerCase();

    if (code == 400) return 'Invalid request. Please check your input.';

    if (code == 401 || lower.contains('unauthorized')) {
      return 'Unauthorized access. Please login again.';
    }

    if (code == 403 || lower.contains('forbidden')) {
      //  Surfaces exact permission e.g. "Missing permission: chat:read"
      if (lower.contains('missing permission')) {
        return 'Permission denied: $error';
      }
      return 'Access denied. You do not have permission.';
    }

    if (code == 404 || lower.contains('not found')) {
      return 'Resource not found.';
    }

    if (code >= 500 || lower.contains('internal server')) {
      return 'Server error. Please try again later.';
    }

    if (lower.contains('network') || lower.contains('connection')) {
      return 'Network error. Please check your connection.';
    }

    if (lower.contains('timeout')) {
      return 'Request timeout. Please try again.';
    }

    // If we got a raw message from the server but no status matched, surface it
    if (error.isNotEmpty) return error;

    return fallback;
  }

  String _parseError(String error) => _parseErrorMessage(error);
}
