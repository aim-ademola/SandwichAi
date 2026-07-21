import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/features/pos/data/model/customer_service_feedback_model.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/customer_service_feedback_repo.dart';
import 'package:sandwich_ai/src/features/pos/presentation/widgets/pos_design_system.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _orderIdController = TextEditingController();
  final _reviewSourceController = TextEditingController(text: 'Internal');
  int _rating = 5;
  int _foodQuality = 5;
  int _serviceQuality = 5;
  int _cleanliness = 5;
  int _valueForMoney = 5;
  int _ambience = 5;
  bool _wouldRecommend = true;
  bool _isAnonymous = false;
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
    _titleController.dispose();
    _commentController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _orderIdController.dispose();
    _reviewSourceController.dispose();
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

    final payload = <String, dynamic>{
      'branchId': branchId,
      'overallRating': _rating,
      'foodQuality': _foodQuality,
      'serviceQuality': _serviceQuality,
      'cleanliness': _cleanliness,
      'valueForMoney': _valueForMoney,
      'ambience': _ambience,
      'comment': _commentController.text.trim(),
      'wouldRecommend': _wouldRecommend,
      'isAnonymous': _isAnonymous,
      'reviewSource': _reviewSourceController.text.trim().isEmpty
          ? 'Internal'
          : _reviewSourceController.text.trim(),
    };
    _putIfNotEmpty(payload, 'title', _titleController.text);
    _putIfNotEmpty(payload, 'customerName', _customerNameController.text);
    _putIfNotEmpty(payload, 'customerPhone', _customerPhoneController.text);
    _putIfNotEmpty(payload, 'customerEmail', _customerEmailController.text);
    _putIfNotEmpty(payload, 'orderId', _orderIdController.text);

    final response = await context
        .read<CustomerServiceFeedbackRepositoryInterface>()
        .createReview(payload);

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    response.when(
      success: (review) {
        _clearCreateForm();
        setState(() {
          _reviews = _upsertReview(_reviews, review);
        });
        _loadReviews();
      },
      error: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      },
    );
  }

  void _putIfNotEmpty(Map<String, dynamic> payload, String key, String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) payload[key] = trimmed;
  }

  void _clearCreateForm() {
    _titleController.clear();
    _commentController.clear();
    _customerNameController.clear();
    _customerPhoneController.clear();
    _customerEmailController.clear();
    _orderIdController.clear();
    _reviewSourceController.text = 'Internal';
    _rating = 5;
    _foodQuality = 5;
    _serviceQuality = 5;
    _cleanliness = 5;
    _valueForMoney = 5;
    _ambience = 5;
    _wouldRecommend = true;
    _isAnonymous = false;
  }

  Future<void> _deleteReview(CustomerServiceRecord review) async {
    final response = await context
        .read<CustomerServiceFeedbackRepositoryInterface>()
        .deleteReview(review.id);

    if (!mounted) return;
    response.when(
      success: (_) {
        setState(() {
          _reviews = _reviews.where((item) => item.id != review.id).toList();
        });
        _loadReviews();
      },
      error: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      },
    );
  }

  void _showEditReview(CustomerServiceRecord review) {
    final responseController = TextEditingController(
      text: review.responseText ?? '',
    );
    final flagReasonController = TextEditingController(
      text: review.flagReason ?? '',
    );
    final validSentiments = const ['POSITIVE', 'NEUTRAL', 'NEGATIVE'];
    var sentiment = validSentiments.contains(review.sentiment)
        ? review.sentiment
        : null;
    var isPublished = review.isPublished ?? true;
    var isFlagged = review.isFlagged ?? false;
    final repository = context
        .read<CustomerServiceFeedbackRepositoryInterface>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Respond to Review'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: sentiment,
                    decoration: const InputDecoration(labelText: 'Sentiment'),
                    items: validSentiments
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(_sentimentLabel(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() => sentiment = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: responseController,
                    decoration: const InputDecoration(
                      labelText: 'Response',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isPublished,
                    title: const Text('Published'),
                    onChanged: (value) {
                      setDialogState(() => isPublished = value);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isFlagged,
                    title: const Text('Flag review'),
                    onChanged: (value) {
                      setDialogState(() => isFlagged = value);
                    },
                  ),
                  if (isFlagged) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: flagReasonController,
                      decoration: const InputDecoration(
                        labelText: 'Flag reason',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  final employeeId =
                      await AuthCacheHelper.instance.getEmpID() ?? '';
                  final responseText = responseController.text.trim();
                  final payload = <String, dynamic>{
                    'isPublished': isPublished,
                    'isFlagged': isFlagged,
                  };
                  if (sentiment != null) payload['sentiment'] = sentiment;
                  if (responseText.isNotEmpty) {
                    payload['responseText'] = responseText;
                    if (employeeId.isNotEmpty) {
                      payload['respondedBy'] = employeeId;
                    }
                  }
                  if (isFlagged) {
                    payload['flagReason'] = flagReasonController.text;
                  }

                  final response = await repository.updateReview(
                    review.id,
                    payload,
                  );

                  if (!mounted) return;
                  response.when(
                    success: (updatedReview) {
                      setState(() {
                        _reviews = _upsertReview(_reviews, updatedReview);
                      });
                      _loadReviews();
                    },
                    error: (error) {
                      ScaffoldMessenger.of(
                        this.context,
                      ).showSnackBar(SnackBar(content: Text(error.toString())));
                    },
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _sentimentLabel(String value) {
    return switch (value) {
      'POSITIVE' => 'Positive',
      'NEUTRAL' => 'Neutral',
      'NEGATIVE' => 'Negative',
      _ => value,
    };
  }

  @override
  Widget build(BuildContext context) {
    return PosPageScaffold(
      title: 'Reviews',
      body: RefreshIndicator(
        color: context.modePrimary,
        onRefresh: _loadReviews,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCreateReviewCard(),
            const SizedBox(height: 22),
            PosSectionHeader(
              title: 'Customer Reviews',
              countLabel:
                  '${_reviews.length} item${_reviews.length == 1 ? '' : 's'}',
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(color: context.modePrimary),
              )
            else if (_error != null)
              _buildMessage('Failed to load reviews', _error!)
            else if (_reviews.isEmpty)
              const PosEmptyState(
                icon: HugeIcons.strokeRoundedStar,
                title: 'No reviews yet',
                message: 'Submitted customer reviews will appear here.',
              )
            else
              ..._reviews.map(_buildReviewCard),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateReviewCard() {
    return PosSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Review',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildRatingDropdown(
            label: 'Overall Rating',
            value: _rating,
            onChanged: (value) {
              setState(() {
                _rating = value;
                _foodQuality = value;
                _serviceQuality = value;
                _cleanliness = value;
                _valueForMoney = value;
                _ambience = value;
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Comment',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: Text(
              'Customer and details',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontWeight: FontWeight.w700,
                color: context.modeTextPrimary,
              ),
            ),
            children: [
              const SizedBox(height: 8),
              _buildTextField(
                controller: _customerNameController,
                label: 'Customer Name',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _customerPhoneController,
                label: 'Customer Phone',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _customerEmailController,
                label: 'Customer Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _orderIdController,
                label: 'Order ID',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _reviewSourceController,
                label: 'Review Source',
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isAnonymous,
                title: const Text('Anonymous review'),
                onChanged: (value) => setState(() => _isAnonymous = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _wouldRecommend,
                title: const Text('Would recommend'),
                onChanged: (value) => setState(() => _wouldRecommend = value),
              ),
            ],
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: Text(
              'Detailed ratings',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontWeight: FontWeight.w700,
                color: context.modeTextPrimary,
              ),
            ),
            children: [
              _buildRatingDropdown(
                label: 'Food Quality',
                value: _foodQuality,
                onChanged: (value) => setState(() => _foodQuality = value),
              ),
              const SizedBox(height: 12),
              _buildRatingDropdown(
                label: 'Service Quality',
                value: _serviceQuality,
                onChanged: (value) => setState(() => _serviceQuality = value),
              ),
              const SizedBox(height: 12),
              _buildRatingDropdown(
                label: 'Cleanliness',
                value: _cleanliness,
                onChanged: (value) => setState(() => _cleanliness = value),
              ),
              const SizedBox(height: 12),
              _buildRatingDropdown(
                label: 'Value For Money',
                value: _valueForMoney,
                onChanged: (value) => setState(() => _valueForMoney = value),
              ),
              const SizedBox(height: 12),
              _buildRatingDropdown(
                label: 'Ambience',
                value: _ambience,
                onChanged: (value) => setState(() => _ambience = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.modePrimary,
                foregroundColor: context.modeTextInverse,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isSubmitting ? 'Saving...' : 'Submit Review',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.modeTextInverse,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildRatingDropdown({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      dropdownColor: context.modeSurface,
      items: List.generate(
        5,
        (index) => DropdownMenuItem(
          value: index + 1,
          child: Text('${index + 1} star${index == 0 ? '' : 's'}'),
        ),
      ),
      onChanged: (nextValue) {
        if (nextValue != null) onChanged(nextValue);
      },
    );
  }

  List<CustomerServiceRecord> _upsertReview(
    List<CustomerServiceRecord> current,
    CustomerServiceRecord review,
  ) {
    return [review, ...current.where((item) => item.id != review.id)];
  }

  Widget _buildReviewCard(CustomerServiceRecord review) {
    return PosSurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedStar,
                color: Colors.amber.shade700,
                size: 18 * AppIcon.sizeScale,
                strokeWidth: 1.9,
              ),
              const SizedBox(width: 6),
              Text(
                '${review.rating ?? 0}/5',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
              ),
              const Spacer(),
              PosIconActionButton(
                icon: HugeIcons.strokeRoundedEdit02,
                color: context.modePrimary,
                tooltip: 'Respond to review',
                onPressed: () => _showEditReview(review),
              ),
              const SizedBox(width: 8),
              PosIconActionButton(
                icon: HugeIcons.strokeRoundedDelete02,
                color: context.modeError,
                tooltip: 'Delete review',
                onPressed: () => _deleteReview(review),
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
          if (_reviewTags(review).isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reviewTags(
                review,
              ).map((tag) => _buildReviewTag(tag)).toList(),
            ),
          ],
          if (review.sentiment != null) ...[
            const SizedBox(height: 8),
            Text(
              _sentimentLabel(review.sentiment!),
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.modeTextSecondary,
              ),
            ),
          ],
          if (review.responseText != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.modePrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                review.responseText!,
                style: WorkSansAppTextStyles.medium.copyWith(
                  color: context.modeTextPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _reviewTags(CustomerServiceRecord review) {
    final tags = <String>[];
    if (review.foodQuality != null) {
      tags.add('Food ${review.foodQuality}/5');
    }
    if (review.serviceQuality != null) {
      tags.add('Service ${review.serviceQuality}/5');
    }
    if (review.cleanliness != null) {
      tags.add('Clean ${review.cleanliness}/5');
    }
    if (review.valueForMoney != null) {
      tags.add('Value ${review.valueForMoney}/5');
    }
    if (review.ambience != null) {
      tags.add('Ambience ${review.ambience}/5');
    }
    if (review.wouldRecommend != null) {
      tags.add(review.wouldRecommend! ? 'Recommend' : 'No recommend');
    }
    if (review.reviewSource != null) {
      tags.add(review.reviewSource!);
    }
    return tags;
  }

  Widget _buildReviewTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.modeSurfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.modeBorder),
      ),
      child: Text(
        label,
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: context.modeTextSecondary,
        ),
      ),
    );
  }

  Widget _buildMessage(String title, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlert02,
              color: context.modeError,
              size: 32 * AppIcon.sizeScale,
              strokeWidth: 1.9,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontWeight: FontWeight.w800,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                color: context.modeTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
