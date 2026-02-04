// presentation/product_intake_history_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/processing/bloc/product_intake_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/product_intake_bloc/event.dart';
import 'package:sandwich_ai/src/features/processing/bloc/product_intake_bloc/state.dart';
import 'package:sandwich_ai/src/features/processing/data/model/product_intake_model.dart';
import 'package:sandwich_ai/src/features/processing/presentation/product_intake_details.dart';

class ProductIntakeHistoryScreen extends StatefulWidget {
  const ProductIntakeHistoryScreen({super.key});

  @override
  State<ProductIntakeHistoryScreen> createState() =>
      _ProductIntakeHistoryScreenState();
}

class _ProductIntakeHistoryScreenState
    extends State<ProductIntakeHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load product intakes when the screen is first shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductIntakeBloc>().add(LoadProductIntakes());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<ProductIntakeBloc>().add(SearchProductIntakes(query: query));
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<ProductIntakeBloc>().add(ClearProductIntakeSearch());
  }

  Future<void> _onRefresh() async {
    context.read<ProductIntakeBloc>().add(RefreshProductIntakes());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductIntakeBloc, ProductIntakeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F6F6),
          body: Column(
            children: [
              // Search Bar
              _buildSearchBar(),

              // Content
              Expanded(child: _buildContent(state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        cursorColor: kPrimary,
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 15,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: 'Search by product name, batch ID, or issued by...',
          hintStyle: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 15,
            color: Colors.grey.shade500,
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF9E9E9E)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF9E9E9E)),
                  onPressed: _clearSearch,
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ProductIntakeState state) {
    if (state is ProductIntakeLoading) {
      return const Center(child: CircularProgressIndicator(color: kPrimary));
    }

    if (state is ProductIntakeError) {
      return _buildErrorWidget(state);
    }

    if (state is ProductIntakeLoaded) {
      if (state.filteredIntakes.isEmpty) {
        return _buildEmptyState(state.searchQuery.isNotEmpty);
      }

      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: kPrimary,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.filteredIntakes.length,
          itemBuilder: (context, index) {
            final intake = state.filteredIntakes[index];
            return _buildIntakeCard(intake);
          },
        ),
      );
    }

    if (state is ProductIntakeRefreshing) {
      return Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.currentData.length,
            itemBuilder: (context, index) {
              final intake = state.currentData[index];
              return _buildIntakeCard(intake);
            },
          ),
          Container(
            color: Colors.black12,
            child: const Center(
              child: CircularProgressIndicator(color: kPrimary),
            ),
          ),
        ],
      );
    }

    return _buildEmptyState(false);
  }

  Widget _buildIntakeCard(ProductIntake intake) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => ProductIntakeDetailsScreen(intake: intake),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      intake.productName,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildQualityBadge(intake.qualityStatus),
                ],
              ),
              const SizedBox(height: 12),

              // Product Type Badge
              _buildProductTypeBadge(intake.productType),
              const SizedBox(height: 12),

              // Quantity Row
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${intake.qtyReceived} ${intake.unit.displayName}',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Batch ID
              Row(
                children: [
                  Icon(Icons.qr_code, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Batch: ${intake.stockBatchId}',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat(
                      'MMM dd, yyyy • hh:mm a',
                    ).format(intake.intakeDate),
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),

              // Issued By
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Issued by: ${intake.issuedBy}',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQualityBadge(bool qualityStatus) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: qualityStatus ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: qualityStatus ? Colors.green.shade600 : Colors.red.shade600,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            qualityStatus ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: qualityStatus ? Colors.green.shade600 : Colors.red.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            qualityStatus ? 'Passed' : 'Failed',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: qualityStatus
                  ? Colors.green.shade700
                  : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTypeBadge(ProductType productType) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (productType) {
      case ProductType.rawMaterial:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        icon = Icons.grass;
        break;
      case ProductType.semiProcessed:
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        icon = Icons.settings;
        break;
      case ProductType.finishedProduct:
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        icon = Icons.check_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            productType.displayName,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'No results found' : 'No product intakes yet',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try adjusting your search terms'
                  : 'Product intakes will appear here once created',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(ProductIntakeError state) {
    String title = 'Something went wrong';
    String message = state.error;
    IconData icon = Icons.error_outline;

    switch (state.errorType) {
      case ProductIntakeErrorType.network:
        title = 'No Internet Connection';
        icon = Icons.wifi_off;
        break;
      case ProductIntakeErrorType.timeout:
        title = 'Request Timeout';
        icon = Icons.access_time;
        break;
      case ProductIntakeErrorType.server:
        title = 'Server Error';
        icon = Icons.dns_outlined;
        break;
      default:
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<ProductIntakeBloc>().add(LoadProductIntakes());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
