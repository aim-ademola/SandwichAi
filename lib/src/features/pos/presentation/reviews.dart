import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/features/pos/data/model/customer_service_feedback_model.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/customer_service_feedback_repo.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final _commentController = TextEditingController();
  int _rating = 5;
  List<CustomerServiceRecord> _reviews = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await context
        .read<CustomerServiceFeedbackRepositoryInterface>()
        .getReviews(limit: 50);

    if (!mounted) return;
    response.when(
      success: (records) {
        setState(() {
          _reviews = records.data;
          _isLoading = false;
        });
      },
      error: (error) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a review')));
      return;
    }

    setState(() => _isSubmitting = true);
    final branchId = await AuthCacheHelper.instance.getBranchID() ?? '';

    if (!mounted) return;
    if (branchId.isEmpty) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Branch not found. Please login again.')),
      );
      return;
    }

    final response = await context
        .read<CustomerServiceFeedbackRepositoryInterface>()
        .createReview({
          'branchId': branchId,
          'overallRating': _rating,
          'comment': _commentController.text.trim(),
        });

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    response.when(
      success: (_) {
        _commentController.clear();
        setState(() => _rating = 5);
        _loadReviews();
      },
      error: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      },
    );
  }

  Future<void> _deleteReview(CustomerServiceRecord review) async {
    final response = await context
        .read<CustomerServiceFeedbackRepositoryInterface>()
        .deleteReview(review.id);

    if (!mounted) return;
    response.when(
      success: (_) => _loadReviews(),
      error: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      },
    );
  }

  void _showEditReview(CustomerServiceRecord review) {
    final commentController = TextEditingController(text: review.details);
    var rating = review.rating ?? 5;
    final repository = context
        .read<CustomerServiceFeedbackRepositoryInterface>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Update Review'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: rating,
                  decoration: const InputDecoration(labelText: 'Rating'),
                  items: List.generate(
                    5,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('${index + 1} star${index == 0 ? '' : 's'}'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => rating = value);
                    }
                  },
                ),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(labelText: 'Review'),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  final branchId =
                      await AuthCacheHelper.instance.getBranchID() ?? '';
                  if (branchId.isEmpty) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Branch not found. Please login again.'),
                      ),
                    );
                    return;
                  }

                  final response = await repository.updateReview(review.id, {
                    'branchId': branchId,
                    'overallRating': rating,
                    'comment': commentController.text.trim(),
                  });

                  if (!mounted) return;
                  response.when(
                    success: (_) => _loadReviews(),
                    error: (error) {
                      ScaffoldMessenger.of(
                        this.context,
                      ).showSnackBar(SnackBar(content: Text(error.toString())));
                    },
                  );
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.modeBackground,
      appBar: AppBar(
        backgroundColor: context.modeSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.modeTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reviews',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.modeTextPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadReviews,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCreateReviewCard(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              _buildMessage(_error!)
            else if (_reviews.isEmpty)
              _buildMessage('No reviews yet')
            else
              ..._reviews.map(_buildReviewCard),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateReviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Review',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _rating,
            decoration: const InputDecoration(labelText: 'Rating'),
            items: List.generate(
              5,
              (index) => DropdownMenuItem(
                value: index + 1,
                child: Text('${index + 1} star${index == 0 ? '' : 's'}'),
              ),
            ),
            onChanged: (value) {
              if (value != null) setState(() => _rating = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Review',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.modePrimary,
                foregroundColor: context.modeTextInverse,
              ),
              child: Text(_isSubmitting ? 'Saving...' : 'Submit Review'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(CustomerServiceRecord review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber.shade700, size: 18),
              const SizedBox(width: 6),
              Text(
                '${review.rating ?? 0}/5',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _showEditReview(review),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: () => _deleteReview(review),
                icon: const Icon(Icons.delete_outline),
                color: context.modeError,
              ),
            ],
          ),
          if (review.customerName != null) ...[
            const SizedBox(height: 4),
            Text(
              review.customerName!,
              style: WorkSansAppTextStyles.medium.copyWith(
                color: context.modeTextSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            review.details.isNotEmpty ? review.details : review.title,
            style: WorkSansAppTextStyles.medium.copyWith(
              color: context.modeTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: WorkSansAppTextStyles.medium.copyWith(
            color: context.modeTextSecondary,
          ),
        ),
      ),
    );
  }
}
