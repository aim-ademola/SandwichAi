import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/pos/data/model/customer_service_feedback_model.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/customer_service_feedback_repo.dart';
import 'package:sandwich_ai/src/features/pos/presentation/widgets/pos_design_system.dart';
import 'package:sandwich_ai/src/features/pos/presentation/widgets/pos_icon_tile.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final List<File> _attachedFiles = [];
  final ImagePicker _picker = ImagePicker();
  String _selectedCategory = 'OTHERS';
  String _selectedSource = 'POS_COUNTER';
  List<CustomerServiceRecord> _complaints = [];
  bool _isLoadingComplaints = false;
  bool _isSubmittingComplaint = false;
  String? _complaintsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadComplaints();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customerNameController.dispose();
    _subjectController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final File file = File(image.path);
        final int fileSize = await file.length();

        if (fileSize > 5 * 1024 * 1024) {
          // 5MB limit
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'File size exceeds 5MB limit',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    color: context.modeTextInverse,
                  ),
                ),
                backgroundColor: context.modeError,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          return;
        }

        setState(() {
          _attachedFiles.add(file);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error picking file: $e',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextInverse,
              ),
            ),
            backgroundColor: context.modeError,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
  }

  Future<void> _loadComplaints() async {
    setState(() {
      _isLoadingComplaints = true;
      _complaintsError = null;
    });

    final response = await context
        .read<CustomerServiceFeedbackRepositoryInterface>()
        .getComplaints(limit: 50);

    if (!mounted) return;
    response.when(
      success: (records) {
        setState(() {
          _complaints = records.data;
          _isLoadingComplaints = false;
        });
      },
      error: (error) {
        setState(() {
          _complaintsError = error.toString();
          _isLoadingComplaints = false;
        });
      },
    );
  }

  Future<void> _submitComplaint() async {
    if (_customerNameController.text.trim().isEmpty ||
        _subjectController.text.trim().isEmpty ||
        _detailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all required fields',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: context.modeTextInverse,
            ),
          ),
          backgroundColor: context.modeError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmittingComplaint = true);
    final branchId = await AuthCacheHelper.instance.getBranchID() ?? '';

    if (!mounted) return;
    if (branchId.isEmpty) {
      setState(() => _isSubmittingComplaint = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Branch not found. Please login again.',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: context.modeTextInverse,
            ),
          ),
          backgroundColor: context.modeError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final response = await context
        .read<CustomerServiceFeedbackRepositoryInterface>()
        .createComplaint({
          'branchId': branchId,
          'customerName': _customerNameController.text.trim(),
          'category': _selectedCategory,
          'source': _selectedSource,
          'description': _detailsController.text.trim(),
          'subject': _subjectController.text.trim(),
          if (_attachedFiles.isNotEmpty)
            'attachments': _attachedFiles.map((file) => file.path).toList(),
        });

    if (!mounted) return;
    setState(() => _isSubmittingComplaint = false);

    response.when(
      success: (_) {
        _customerNameController.clear();
        _subjectController.clear();
        _detailsController.clear();
        setState(() {
          _selectedCategory = 'OTHERS';
          _selectedSource = 'POS_COUNTER';
          _attachedFiles.clear();
        });
        _loadComplaints();
      },
      error: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.toString(),
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextInverse,
              ),
            ),
            backgroundColor: context.modeError,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );

    if (!response.isSuccess) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: context.modeSuccess.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: AppIcon(
                Icons.check_circle,
                color: context.modeSuccess,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Complaint Submitted',
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your complaint has been submitted successfully. We\'ll get back to you soon.',
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _tabController.animateTo(1);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: context.modePrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Done',
                textAlign: TextAlign.center,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.modeTextInverse,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PosPageScaffold(
      title: 'Complaints',
      body: Column(
        children: [
          // Tab bar
          Container(
            color: context.modeBackground,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PosSurfaceCard(
              padding: EdgeInsets.zero,
              child: TabBar(
                controller: _tabController,
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
                  Tab(text: 'Lodge Complaint'),
                  Tab(text: 'My Complaints'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildLodgeComplaintTab(), _buildMyComplaintsTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLodgeComplaintTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Name',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: context.modeSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.modeBorder),
            ),
            child: TextField(
              controller: _customerNameController,
              cursorColor: context.modePrimary,
              decoration: InputDecoration(
                hintText: 'Enter customer name',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: context.modeTextMuted,
                ),
                border: InputBorder.none,
              ),
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Category',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: context.modeSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.modeBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                dropdownColor: context.modeSurface,
                iconEnabledColor: context.modeTextSecondary,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: context.modeTextPrimary,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'LATE_ORDER',
                    child: Text('Late order'),
                  ),
                  DropdownMenuItem(
                    value: 'WRONG_ITEM',
                    child: Text('Wrong item'),
                  ),
                  DropdownMenuItem(
                    value: 'WRONG_ORDER',
                    child: Text('Wrong order'),
                  ),
                  DropdownMenuItem(
                    value: 'POOR_QUALITY',
                    child: Text('Poor quality'),
                  ),
                  DropdownMenuItem(
                    value: 'STAFF_ATTITUDE',
                    child: Text('Staff attitude'),
                  ),
                  DropdownMenuItem(
                    value: 'PAYMENT_ISSUES',
                    child: Text('Payment issues'),
                  ),
                  DropdownMenuItem(
                    value: 'DELIVERY_APP',
                    child: Text('Delivery app'),
                  ),
                  DropdownMenuItem(value: 'HYGIENE', child: Text('Hygiene')),
                  DropdownMenuItem(value: 'PRICING', child: Text('Pricing')),
                  DropdownMenuItem(value: 'OTHERS', child: Text('Others')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Source',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: context.modeSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.modeBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSource,
                isExpanded: true,
                dropdownColor: context.modeSurface,
                iconEnabledColor: context.modeTextSecondary,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: context.modeTextPrimary,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'POS_COUNTER',
                    child: Text('POS counter'),
                  ),
                  DropdownMenuItem(
                    value: 'DELIVERY_APP',
                    child: Text('Delivery app'),
                  ),
                  DropdownMenuItem(
                    value: 'CALL_CENTER',
                    child: Text('Call center'),
                  ),
                  DropdownMenuItem(
                    value: 'SOCIAL_MEDIA',
                    child: Text('Social media'),
                  ),
                  DropdownMenuItem(value: 'EMAIL', child: Text('Email')),
                  DropdownMenuItem(
                    value: 'IN_PERSON',
                    child: Text('In person'),
                  ),
                  DropdownMenuItem(value: 'ONLINE', child: Text('Online')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSource = value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Complaint Subject
          Text(
            'Complaint Subject',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: context.modeSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.modeBorder),
            ),
            child: TextField(
              controller: _subjectController,
              cursorColor: context.modePrimary,
              decoration: InputDecoration(
                hintText: 'Enter a brief subject for your complaint',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: context.modeTextMuted,
                ),
                border: InputBorder.none,
              ),
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Detailed Complaint
          Text(
            'Detailed Complaint',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.modeSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.modeBorder),
            ),
            child: TextField(
              controller: _detailsController,
              cursorColor: context.modePrimary,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Describe the issue in detail here...',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: context.modeTextMuted,
                ),
                border: InputBorder.none,
              ),
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Attach Files
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: context.modeSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.modeBorder),
              ),
              child: Row(
                children: [
                  AppIcon(
                    Icons.attach_file,
                    color: context.modePrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attach Files/Images',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.modeTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Accepted file types: jpg, png, pdf. Max size 5MB.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 12,
                            color: context.modeTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Display attached files
          if (_attachedFiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...List.generate(
              _attachedFiles.length,
              (index) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.modeSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.modeBorder),
                ),
                child: Row(
                  children: [
                    AppIcon(Icons.image, color: context.modePrimary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _attachedFiles[index].path.split('/').last,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 14,
                          color: context.modeTextPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const AppIcon(Icons.close, size: 20),
                      onPressed: () => _removeFile(index),
                      color: context.modeError,
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          // Submit button
          GestureDetector(
            onTap: _isSubmittingComplaint ? null : _submitComplaint,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: context.modePrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isSubmittingComplaint
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.modeTextInverse,
                        ),
                      ),
                    )
                  : Text(
                      'Submit Complaint',
                      textAlign: TextAlign.center,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.modeTextInverse,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyComplaintsTab() {
    if (_isLoadingComplaints) {
      return Center(
        child: CircularProgressIndicator(color: context.modePrimary),
      );
    }

    if (_complaintsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(Icons.error_outline, size: 64, color: context.modeError),
              const SizedBox(height: 16),
              Text(
                'Failed to load complaints',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _complaintsError!,
                textAlign: TextAlign.center,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: context.modeTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadComplaints,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.modePrimary,
                  foregroundColor: context.modeTextInverse,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_complaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(
              Icons.feedback_outlined,
              size: 80,
              color: context.modeTextMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No Complaints Yet',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.modeTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your submitted complaints will appear here',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadComplaints,
      color: context.modePrimary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _complaints.length,
        itemBuilder: (context, index) {
          final complaint = _complaints[index];
          final statusColor = _statusColor(complaint.status);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.modeSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.modeBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        complaint.title,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.modeTextPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        complaint.status,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendar03,
                      size: 15 * AppIcon.sizeScale,
                      color: context.modeTextMuted,
                      strokeWidth: 1.8,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatRecordDate(complaint.createdAt),
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        color: context.modeTextSecondary,
                      ),
                    ),
                    const Spacer(),
                    _ComplaintActionButton(
                      icon: HugeIcons.strokeRoundedEdit02,
                      color: context.modePrimary,
                      tooltip: 'Edit complaint',
                      onPressed: () => _showEditComplaintDialog(complaint),
                    ),
                    const SizedBox(width: 8),
                    _ComplaintActionButton(
                      icon: HugeIcons.strokeRoundedDelete02,
                      color: context.modeError,
                      tooltip: 'Delete complaint',
                      onPressed: () => _confirmDeleteComplaint(complaint),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        return context.modeSuccess;
      case 'in progress':
      case 'processing':
        return context.modeInfo;
      case 'rejected':
      case 'cancelled':
        return context.modeError;
      default:
        return context.modeWarning;
    }
  }

  String _formatRecordDate(String? value) {
    if (value == null || value.isEmpty) return 'Not available';
    return value.split('T').first;
  }

  Future<void> _confirmDeleteComplaint(CustomerServiceRecord complaint) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.modeSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            PosIconTile(
              icon: HugeIcons.strokeRoundedDelete02,
              color: context.modeError,
              size: 38,
              iconSize: 21,
              borderRadius: 10,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete complaint?',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.modeTextPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${complaint.title}"? This action cannot be undone.',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            color: context.modeTextSecondary,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontWeight: FontWeight.w700,
                color: context.modeTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.modeError,
              foregroundColor: context.modeTextInverse,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Delete',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontWeight: FontWeight.w700,
                color: context.modeTextInverse,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      await _deleteComplaint(complaint);
    }
  }

  Future<void> _deleteComplaint(CustomerServiceRecord complaint) async {
    final response = await context
        .read<CustomerServiceFeedbackRepositoryInterface>()
        .deleteComplaint(complaint.id);

    if (!mounted) return;
    response.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint deleted successfully')),
        );
        _loadComplaints();
      },
      error: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      },
    );
  }

  void _showEditComplaintDialog(CustomerServiceRecord complaint) {
    final subjectController = TextEditingController(text: complaint.title);
    final detailsController = TextEditingController(text: complaint.details);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: context.modeSurface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.modePrimary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: AppIcon(
                        Icons.edit_note_outlined,
                        color: context.modePrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Update Complaint',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.modeTextPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: AppIcon(Icons.close, color: context.modeTextMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildDialogField(
                  controller: subjectController,
                  label: 'Subject',
                  hint: 'Enter complaint subject',
                  icon: Icons.subject_outlined,
                ),
                const SizedBox(height: 14),
                _buildDialogField(
                  controller: detailsController,
                  label: 'Description',
                  hint: 'Describe the complaint',
                  icon: Icons.notes_outlined,
                  maxLines: 4,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.modeTextPrimary,
                          side: BorderSide(color: context.modeBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Cancel',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          final response = await context
                              .read<
                                CustomerServiceFeedbackRepositoryInterface
                              >()
                              .updateComplaint(complaint.id, {
                                'subject': subjectController.text.trim(),
                                'description': detailsController.text.trim(),
                              });

                          if (!mounted) return;
                          response.when(
                            success: (_) => _loadComplaints(),
                            error: (error) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.modePrimary,
                          foregroundColor: context.modeTextInverse,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Update',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.modeTextInverse,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.modeTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          cursorColor: context.modePrimary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: context.modeTextMuted,
            ),
            prefixIcon: AppIcon(icon, color: context.modeTextMuted, size: 20),
            filled: true,
            fillColor: context.modeSurfaceAlt,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.modeBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.modePrimary, width: 1.4),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            color: context.modeTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _ComplaintActionButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _ComplaintActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Center(
              child: HugeIcon(
                icon: icon,
                color: color,
                size: 20 * AppIcon.sizeScale,
                strokeWidth: 1.9,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
