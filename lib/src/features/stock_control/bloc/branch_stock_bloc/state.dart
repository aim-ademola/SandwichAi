import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/branch_stock_model.dart';

enum BranchStockErrorType { network, timeout, server, validation, general }

sealed class BranchStockState extends Equatable {
  const BranchStockState();

  @override
  List<Object?> get props => [];
}

class BranchStockInitial extends BranchStockState {
  const BranchStockInitial();
}

class BranchStockLoading extends BranchStockState {
  const BranchStockLoading();
}

class BranchStockLoaded extends BranchStockState {
  final BranchStockResponse response;
  final List<String> categories;
  final String selectedCategory;
  final String searchQuery;
  final bool isTableView;
  final List<CatalogItem> filteredItems;

  const BranchStockLoaded({
    required this.response,
    required this.categories,
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.isTableView = false,
    required this.filteredItems,
  });

  @override
  List<Object?> get props => [
    response,
    categories,
    selectedCategory,
    searchQuery,
    isTableView,
    filteredItems,
  ];

  BranchStockLoaded copyWith({
    BranchStockResponse? response,
    List<String>? categories,
    String? selectedCategory,
    String? searchQuery,
    bool? isTableView,
    List<CatalogItem>? filteredItems,
  }) {
    return BranchStockLoaded(
      response: response ?? this.response,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      isTableView: isTableView ?? this.isTableView,
      filteredItems: filteredItems ?? this.filteredItems,
    );
  }

  // Helper to get itemId for a specific item
  String? getItemId(String itemName) {
    try {
      final item = response.data.firstWhere(
        (item) => item.item.itemName == itemName,
      );
      return item.itemId;
    } catch (e) {
      return null;
    }
  }

  // Helper to get item by id
  BranchStockItem? getItemById(String itemId) {
    try {
      return response.data.firstWhere((item) => item.itemId == itemId);
    } catch (e) {
      return null;
    }
  }
}

class BranchStockError extends BranchStockState {
  final String error;
  final BranchStockErrorType errorType;

  const BranchStockError({
    required this.error,
    this.errorType = BranchStockErrorType.general,
  });

  @override
  List<Object?> get props => [error, errorType];
}

class BranchStockRefreshing extends BranchStockState {
  final BranchStockResponse currentData;

  const BranchStockRefreshing({required this.currentData});

  @override
  List<Object?> get props => [currentData];
}

class BranchStockEmpty extends BranchStockState {
  const BranchStockEmpty();

  @override
  List<Object?> get props => [];
}
