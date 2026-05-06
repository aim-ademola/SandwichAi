// lib/src/core/widgets/paginated_list_wrapper.dart

import 'package:flutter/material.dart';

class PaginatedListWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onLoadMore;
  final bool isLoadingMore;
  final bool hasMore;
  final double threshold; // how many px from bottom to trigger

  const PaginatedListWrapper({
    super.key,
    required this.child,
    required this.onLoadMore,
    required this.isLoadingMore,
    required this.hasMore,
    this.threshold = 200,
  });

  @override
  State<PaginatedListWrapper> createState() => _PaginatedListWrapperState();
}

class _PaginatedListWrapperState extends State<PaginatedListWrapper> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!widget.hasMore || widget.isLoadingMore) return;
    final pos = _controller.position;
    if (pos.pixels >= pos.maxScrollExtent - widget.threshold) {
      widget.onLoadMore();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      child: Column(
        children: [
          Expanded(
            // Pass the controller down via a ScrollConfiguration
            // so the child ListView picks it up automatically
            child: PrimaryScrollController(
              controller: _controller,
              child: widget.child,
            ),
          ),
          if (widget.isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
