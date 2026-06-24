import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
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
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final List<File> _attachedFiles = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Colors.red,
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
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
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

  void _submitComplaint() {
    if (_subjectController.text.trim().isEmpty ||
        _detailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all required fields',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Show success dialog
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
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
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
                color: kprimaryTextColor1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your complaint has been submitted successfully. We\'ll get back to you soon.',
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: kprimaryTextColor2,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Clear form
              _subjectController.clear();
              _detailsController.clear();
              setState(() {
                _attachedFiles.clear();
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Done',
                textAlign: TextAlign.center,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Complaints',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Tab bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: kPrimary,
                unselectedLabelColor: kprimaryTextColor2,
                indicatorColor: kPrimary,
                indicatorWeight: 3,
                labelStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Lodge Complaint'),
                  Tab(text: 'My Complaints'),
                ],
              ),
            ),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildLodgeComplaintTab(), _buildMyComplaintsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLodgeComplaintTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Complaint Subject
          Text(
            'Complaint Subject',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _subjectController,
              cursorColor: kPrimary,
              decoration: InputDecoration(
                hintText: 'Enter a brief subject for your complaint',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: kprimaryTextColor2,
                ),
                border: InputBorder.none,
              ),
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: kprimaryTextColor1,
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
              color: kprimaryTextColor1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _detailsController,
              cursorColor: kPrimary,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Describe the issue in detail here...',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: kprimaryTextColor2,
                ),
                border: InputBorder.none,
              ),
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: kprimaryTextColor1,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_file, color: kPrimary, size: 24),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attach Files/Images',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kprimaryTextColor1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Accepted file types: jpg, png, pdf. Max size 5MB.',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 12,
                          color: kprimaryTextColor2,
                        ),
                      ),
                    ],
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image, color: kPrimary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _attachedFiles[index].path.split('/').last,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 14,
                          color: kprimaryTextColor1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => _removeFile(index),
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          // Submit button
          GestureDetector(
            onTap: _submitComplaint,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Submit Complaint',
                textAlign: TextAlign.center,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyComplaintsTab() {
    // Sample complaints data
    final complaints = [
      {
        'subject': 'Order Processing Delay',
        'date': 'Nov 14, 2025',
        'status': 'Pending',
        'statusColor': Colors.orange,
      },
      {
        'subject': 'Payment System Error',
        'date': 'Nov 10, 2025',
        'status': 'Resolved',
        'statusColor': Colors.green,
      },
      {
        'subject': 'Equipment Malfunction',
        'date': 'Nov 8, 2025',
        'status': 'In Progress',
        'statusColor': Colors.blue,
      },
    ];

    if (complaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.feedback_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Complaints Yet',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your submitted complaints will appear here',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: kprimaryTextColor2,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: complaints.length,
      itemBuilder: (context, index) {
        final complaint = complaints[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
                      complaint['subject'] as String,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kprimaryTextColor1,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (complaint['statusColor'] as Color).withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      complaint['status'] as String,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: complaint['statusColor'] as Color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: kprimaryTextColor2,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    complaint['date'] as String,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      color: kprimaryTextColor2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
