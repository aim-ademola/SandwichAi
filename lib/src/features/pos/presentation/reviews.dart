import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/utils/debouncer.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/features/auth/login/presentation/snack_bar.dart';
import 'package:sandwich_ai/src/features/pos/data/model/customer_model.dart';
import 'package:sandwich_ai/src/features/pos/data/model/customer_service_feedback_model.dart';
import 'package:sandwich_ai/src/features/pos/data/model/oder_status_model.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/customer_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/customer_service_feedback_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/order_statua_repo.dart';
import 'package:sandwich_ai/src/features/pos/presentation/widgets/pos_design_system.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  static _ReviewDraft? _createReviewDraft;
  static const _newCustomerValue = '__new_customer__';

  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _orderIdController = TextEditingController();
  final _reviewSourceController = TextEditingController(text: 'Internal');
  late final Debouncer _orderLookupDebouncer;
  KitchenOrder? _matchedOrder;
  String? _orderVerificationError;
  String _lastVerifiedOrderInput = '';
  int _orderLookupRequestId = 0;
  int _rating = 5;
  int _foodQuality = 5;
  int _serviceQuality = 5;
  int _cleanliness = 5;
  int _valueForMoney = 5;
  int _ambience = 5;
  bool _wouldRecommend = true;
  bool _isAnonymous = false;
  String _selectedCustomerId = _newCustomerValue;
  List<CustomerModel> _customers = [];
  List<CustomerServiceRecord> _reviews = [];
  bool _isLoadingCustomers = false;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _orderLookupDebouncer = Debouncer(
      delay: const Duration(milliseconds: 350),
    );
    _restoreCreateDraft();
    _orderIdController.addListener(_onOrderIdChanged);
    if (_orderIdController.text.trim().isNotEmpty) {
      _verifyOrderId(_orderIdController.text.trim());
    }
    _loadCustomers();
    _loadReviews();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoadingCustomers = true);

    final response = await context
        .read<CustomerRepositoryInterface>()
        .getCustomers(limit: 100);

    if (!mounted) return;
    response.when(
      success: (customersResponse) {
        setState(() {
          _customers = customersResponse.data;
          _isLoadingCustomers = false;
        });
      },
      error: (_) {
        setState(() => _isLoadingCustomers = false);
      },
    );
  }

  @override
  void dispose() {
    _saveCreateDraft();
    _orderLookupDebouncer.dispose();
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

    final enteredOrderId = _orderIdController.text.trim();
    if (enteredOrderId.isNotEmpty &&
        (_matchedOrder == null || _lastVerifiedOrderInput != enteredOrderId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a valid order before submitting.'),
          backgroundColor: context.modeError,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    if (_matchedOrder != null) {
      payload['orderId'] = _matchedOrder!.id;
    }

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
        showSuccessSnackBar('Review submitted successfully!', context);
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
    _matchedOrder = null;
    _orderVerificationError = null;
    _lastVerifiedOrderInput = '';
    _reviewSourceController.text = 'Internal';
    _selectedCustomerId = _newCustomerValue;
    _rating = 5;
    _foodQuality = 5;
    _serviceQuality = 5;
    _cleanliness = 5;
    _valueForMoney = 5;
    _ambience = 5;
    _wouldRecommend = true;
    _isAnonymous = false;
    _createReviewDraft = null;
  }

  void _saveCreateDraft() {
    if (!_hasCreateDraftContent()) {
      _createReviewDraft = null;
      return;
    }

    _createReviewDraft = _ReviewDraft(
      title: _titleController.text,
      comment: _commentController.text,
      customerName: _customerNameController.text,
      customerPhone: _customerPhoneController.text,
      customerEmail: _customerEmailController.text,
      orderId: _orderIdController.text,
      reviewSource: _reviewSourceController.text,
      selectedCustomerId: _selectedCustomerId,
      rating: _rating,
      foodQuality: _foodQuality,
      serviceQuality: _serviceQuality,
      cleanliness: _cleanliness,
      valueForMoney: _valueForMoney,
      ambience: _ambience,
      wouldRecommend: _wouldRecommend,
      isAnonymous: _isAnonymous,
    );
  }

  bool _hasCreateDraftContent() {
    return _titleController.text.trim().isNotEmpty ||
        _commentController.text.trim().isNotEmpty ||
        _customerNameController.text.trim().isNotEmpty ||
        _customerPhoneController.text.trim().isNotEmpty ||
        _customerEmailController.text.trim().isNotEmpty ||
        _orderIdController.text.trim().isNotEmpty ||
        _selectedCustomerId != _newCustomerValue ||
        (_reviewSourceController.text.trim().isNotEmpty &&
            _reviewSourceController.text.trim() != 'Internal') ||
        _rating != 5 ||
        _foodQuality != 5 ||
        _serviceQuality != 5 ||
        _cleanliness != 5 ||
        _valueForMoney != 5 ||
        _ambience != 5 ||
        !_wouldRecommend ||
        _isAnonymous;
  }

  void _restoreCreateDraft() {
    final draft = _createReviewDraft;
    if (draft == null) return;

    _titleController.text = draft.title;
    _commentController.text = draft.comment;
    _customerNameController.text = draft.customerName;
    _customerPhoneController.text = draft.customerPhone;
    _customerEmailController.text = draft.customerEmail;
    _orderIdController.text = draft.orderId;
    _reviewSourceController.text = draft.reviewSource.trim().isEmpty
        ? 'Internal'
        : draft.reviewSource;
    _selectedCustomerId = draft.selectedCustomerId;
    _rating = draft.rating;
    _foodQuality = draft.foodQuality;
    _serviceQuality = draft.serviceQuality;
    _cleanliness = draft.cleanliness;
    _valueForMoney = draft.valueForMoney;
    _ambience = draft.ambience;
    _wouldRecommend = draft.wouldRecommend;
    _isAnonymous = draft.isAnonymous;
  }

  void _selectCustomer(String? customerId) {
    if (customerId == null) return;

    setState(() {
      _selectedCustomerId = customerId;
      if (customerId == _newCustomerValue) {
        _customerNameController.clear();
        _customerPhoneController.clear();
        _customerEmailController.clear();
        return;
      }

      final customer = _customers.firstWhere(
        (item) => item.id == customerId,
        orElse: () => CustomerModel(
          id: '',
          phone: '',
          email: '',
          name: '',
          organizationId: '',
          totalOrders: 0,
          totalSpent: 0,
          loyaltyPoints: 0,
          membershipTier: '',
          isActive: true,
          isBlacklisted: false,
          allowsMarketing: false,
          allowsSMS: false,
          allowsEmail: false,
          createdAt: '',
          updatedAt: '',
        ),
      );

      if (customer.id.isEmpty) return;
      _customerNameController.text = customer.name;
      _customerPhoneController.text = customer.phone;
      _customerEmailController.text = customer.email;
    });
  }

  void _onOrderIdChanged() {
    final query = _orderIdController.text.trim();
    _orderLookupDebouncer.cancel();

    setState(() {
      _matchedOrder = null;
      _orderVerificationError = null;
      _lastVerifiedOrderInput = '';
    });

    if (query.isEmpty) return;

    _orderLookupDebouncer(() {
      if (!mounted) return;
      _verifyOrderId(query);
    });
  }

  Future<void> _verifyOrderId(String query) async {
    final requestId = ++_orderLookupRequestId;

    setState(() {
      _orderVerificationError = null;
    });

    final branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    if (!mounted || requestId != _orderLookupRequestId) return;

    if (branchId.isEmpty) {
      setState(() {
        _orderVerificationError = 'Branch not found';
      });
      return;
    }

    final response = await context
        .read<KitchenOrdersRepositoryInterface>()
        .getKitchenOrders(branchId: branchId);

    if (!mounted || requestId != _orderLookupRequestId) return;

    response.when(
      success: (orders) {
        final normalizedQuery = query.toLowerCase();
        KitchenOrder? match;
        for (final order in orders) {
          if (order.orderId.toLowerCase() == normalizedQuery ||
              order.id.toLowerCase() == normalizedQuery) {
            match = order;
            break;
          }
        }

        setState(() {
          _matchedOrder = match;
          _lastVerifiedOrderInput = match == null ? '' : query;
          _orderVerificationError = match == null ? 'Order not found' : null;
        });
      },
      error: (error) {
        setState(() {
          _orderVerificationError = error.toString();
        });
      },
    );
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
    return DefaultTabController(
      length: 2,
      child: PosPageScaffold(
        title: 'Reviews',
        body: Column(
          children: [
            Container(
              color: context.modeBackground,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PosSurfaceCard(
                padding: EdgeInsets.zero,
                child: TabBar(
                  labelColor: context.modePrimary,
                  unselectedLabelColor: context.modeTextSecondary,
                  indicatorColor: context.modePrimary,
                  indicatorWeight: 3,
                  labelStyle: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                  unselectedLabelStyle: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Create Review'),
                    Tab(text: 'Review List'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [_buildCreateReviewTab(), _buildReviewsListTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateReviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [_buildCreateReviewCard()],
    );
  }

  Widget _buildReviewsListTab() {
    return RefreshIndicator(
      color: context.modePrimary,
      onRefresh: _loadReviews,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PosSectionHeader(
            title: 'Customer Reviews',
            countLabel:
                '${_reviews.length} item${_reviews.length == 1 ? '' : 's'}',
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            Center(child: CircularProgressIndicator(color: context.modePrimary))
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
              _buildCustomerDropdown(),
              const SizedBox(height: 12),
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
                suffixIcon: _buildOrderIdSuffixIcon(),
                helperText: _matchedOrder == null
                    ? _orderVerificationError
                    : 'Order found: ${_matchedOrder!.orderId}',
                helperStyle: WorkSansAppTextStyles.medium.copyWith(
                  color: _matchedOrder == null
                      ? context.modeError
                      : context.modeSuccess,
                  fontWeight: FontWeight.w600,
                ),
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
    Widget? suffixIcon,
    String? helperText,
    TextStyle? helperStyle,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon,
        helperText: helperText,
        helperStyle: helperStyle,
      ),
    );
  }

  Widget? _buildOrderIdSuffixIcon() {
    final query = _orderIdController.text.trim();
    if (query.isEmpty) return null;

    if (_matchedOrder != null && _lastVerifiedOrderInput == query) {
      return Icon(Icons.check_circle_rounded, color: context.modeSuccess);
    }

    if (_orderVerificationError != null) {
      return Icon(Icons.cancel_rounded, color: context.modeError);
    }

    return Padding(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: context.modePrimary,
        ),
      ),
    );
  }

  Widget _buildCustomerDropdown() {
    final hasSelectedCustomer =
        _selectedCustomerId == _newCustomerValue ||
        _customers.any((customer) => customer.id == _selectedCustomerId);

    return DropdownButtonFormField<String>(
      initialValue: hasSelectedCustomer
          ? _selectedCustomerId
          : _newCustomerValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Customer',
        border: const OutlineInputBorder(),
        suffixIcon: _isLoadingCustomers
            ? Padding(
                padding: const EdgeInsets.all(14),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.modePrimary,
                  ),
                ),
              )
            : null,
      ),
      dropdownColor: context.modeSurface,
      items: [
        const DropdownMenuItem(
          value: _newCustomerValue,
          child: Text('New customer'),
        ),
        ..._customers.map(
          (customer) => DropdownMenuItem(
            value: customer.id,
            child: Text(
              [
                customer.name.trim().isEmpty
                    ? 'Unnamed customer'
                    : customer.name,
                if (customer.phone.trim().isNotEmpty) customer.phone,
              ].join(' - '),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: _selectCustomer,
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

class _ReviewDraft {
  final String title;
  final String comment;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String orderId;
  final String reviewSource;
  final String selectedCustomerId;
  final int rating;
  final int foodQuality;
  final int serviceQuality;
  final int cleanliness;
  final int valueForMoney;
  final int ambience;
  final bool wouldRecommend;
  final bool isAnonymous;

  const _ReviewDraft({
    required this.title,
    required this.comment,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.orderId,
    required this.reviewSource,
    required this.selectedCustomerId,
    required this.rating,
    required this.foodQuality,
    required this.serviceQuality,
    required this.cleanliness,
    required this.valueForMoney,
    required this.ambience,
    required this.wouldRecommend,
    required this.isAnonymous,
  });
}
