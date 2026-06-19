// data/repo/inventory_items_repo.dart

import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/network_exception.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base-repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class InventoryItemsRepositoryInterface {
  Future<ApiResponse<List<InventoryItem>>> getInventoryItems({
    required String organizationId,
  });
}

class InventoryItemsRepository extends BaseRepository
    implements InventoryItemsRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<List<InventoryItem>>> getInventoryItems({
    required String organizationId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient
          .get(
            'inventory-items',
            queryParameters: {
              'page': page,
              'limit': limit,
              // 'organizationId': organizationId,
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return response.when(
        success: (data) {
          try {
            if (data is Map<String, dynamic> && data.containsKey('data')) {
              final List<dynamic> itemsList = data['data'] as List<dynamic>;
              final items = itemsList
                  .map(
                    (item) =>
                        InventoryItem.fromJson(item as Map<String, dynamic>),
                  )
                  .toList();
              return ApiResponse.success(items);
            } else {
              return ApiResponse.error(
                NetworkException.formatException(
                  'Expected wrapped data but got ${data.runtimeType}',
                ),
              );
            }
          } catch (e) {
            return ApiResponse.error(
              NetworkException.formatException(
                'Failed to parse inventory items: $e',
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
        'Failed to load inventory items. Please try again later.',
      );
    }
  }
} // data/model/inventory_item.dart

class InventoryItem {
  final String id;
  final String itemName;
  final String category;
  final String unit;
  final String description;
  final String sku;
  final String organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItem({
    required this.id,
    required this.itemName,
    required this.category,
    required this.unit,
    required this.description,
    required this.sku,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] ?? '',
      itemName: json['itemName'] ?? '',
      category: json['category'] ?? '',
      unit: json['unit'] ?? '',
      description: json['description'] ?? '',
      sku: json['sku'] ?? '',
      organizationId: json['organizationId'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemName': itemName,
      'category': category,
      'unit': unit,
      'description': description,
      'sku': sku,
      'organizationId': organizationId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Convenience getters for compatibility
  String get name => itemName;
  String get storage => unit;
}

// Category enum for better type safety
enum InventoryCategory {
  PROTEIN,
  GRAIN,
  VEGETABLE,
  DAIRY,
  OIL,
  SPICES,
  SEASONING,
}

extension InventoryCategoryExtension on InventoryCategory {
  String get displayName {
    switch (this) {
      case InventoryCategory.PROTEIN:
        return 'Protein';
      case InventoryCategory.GRAIN:
        return 'Grain';
      case InventoryCategory.VEGETABLE:
        return 'Vegetable';
      case InventoryCategory.DAIRY:
        return 'Dairy';
      case InventoryCategory.OIL:
        return 'Oil';
      case InventoryCategory.SPICES:
        return 'Spices';
      case InventoryCategory.SEASONING:
        return 'Seasoning';
    }
  }
}

abstract class InventoryItemsEvent {}

class LoadInventoryItems extends InventoryItemsEvent {
  final String organizationId;
  final int page;
  final int limit;

  LoadInventoryItems({
    required this.organizationId,
    this.page = 1,
    this.limit = 20,
  });
}

// Add a new event for loading more (infinite scroll)
class LoadMoreInventoryItems extends InventoryItemsEvent {
  final String organizationId;

  LoadMoreInventoryItems({required this.organizationId});
}

abstract class InventoryItemsState {}

class InventoryItemsInitial extends InventoryItemsState {}

class InventoryItemsLoading extends InventoryItemsState {}

class InventoryItemsLoaded extends InventoryItemsState {
  final List<InventoryItem> items;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  InventoryItemsLoaded({
    required this.items,
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  InventoryItemsLoaded copyWith({
    List<InventoryItem>? items,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return InventoryItemsLoaded(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class InventoryItemsError extends InventoryItemsState {
  final String error;
  InventoryItemsError({required this.error});
}

class InventoryItemsBloc
    extends Bloc<InventoryItemsEvent, InventoryItemsState> {
  final InventoryItemsRepository _repository;
  static const int _limit = 20;

  InventoryItemsBloc({required InventoryItemsRepository repository})
    : _repository = repository,
      super(InventoryItemsInitial()) {
    on<LoadInventoryItems>(_onLoadInventoryItems);
    on<LoadMoreInventoryItems>(_onLoadMoreInventoryItems);
  }

  Future<void> _onLoadInventoryItems(
    LoadInventoryItems event,
    Emitter<InventoryItemsState> emit,
  ) async {
    emit(InventoryItemsLoading());

    final response = await _repository.getInventoryItems(
      organizationId: event.organizationId,
      page: event.page,
      limit: event.limit,
    );

    response.when(
      success: (items) => emit(
        InventoryItemsLoaded(
          items: items,
          currentPage: event.page,
          hasMore:
              items.length >= event.limit, // if less than limit, no more pages
        ),
      ),
      error: (error) => emit(InventoryItemsError(error: error.message)),
    );
  }

  Future<void> _onLoadMoreInventoryItems(
    LoadMoreInventoryItems event,
    Emitter<InventoryItemsState> emit,
  ) async {
    // Only load more if currently in loaded state and has more pages
    final currentState = state;
    if (currentState is! InventoryItemsLoaded || !currentState.hasMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final nextPage = currentState.currentPage + 1;

    final response = await _repository.getInventoryItems(
      organizationId: event.organizationId,
      page: nextPage,
      limit: _limit,
    );

    response.when(
      success: (newItems) => emit(
        currentState.copyWith(
          items: [
            ...currentState.items,
            ...newItems,
          ], // append to existing list
          currentPage: nextPage,
          hasMore: newItems.length >= _limit,
          isLoadingMore: false,
        ),
      ),
      error: (_) => emit(currentState.copyWith(isLoadingMore: false)),
    );
  }
}
