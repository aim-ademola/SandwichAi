import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';

class POSRequisitionScreen extends StatefulWidget {
  const POSRequisitionScreen({super.key});

  @override
  State<POSRequisitionScreen> createState() => _POSRequisitionScreenState();
}

class _POSRequisitionScreenState extends State<POSRequisitionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String? _selectedDepartment;

  final List<String> _departments = [
    'Stock',
    'Kitchen',
    'Procurement',
    'Processing',
    'POS',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _itemController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitRequisition() {
    if (_itemController.text.trim().isEmpty ||
        _quantityController.text.trim().isEmpty ||
        _selectedDepartment == null) {
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
              'Requisition Submitted',
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your requisition has been submitted successfully and is now pending approval.',
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
              Navigator.pop(context);
              // Clear form
              _itemController.clear();
              _quantityController.clear();
              _notesController.clear();
              setState(() {
                _selectedDepartment = null;
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
            'Requisition',
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
                  Tab(text: 'Create Requisition'),
                  Tab(text: 'Pending'),
                  Tab(text: 'Completed'),
                ],
              ),
            ),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCreateRequisitionTab(),
                  _buildPendingTab(),
                  _buildCompletedTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateRequisitionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item
          Text(
            'Item',
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
              controller: _itemController,
              cursorColor: kPrimary,
              decoration: InputDecoration(
                hintText: 'Enter item to request',
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
          // Quantity
          Text(
            'Quantity',
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
              border: Border.all(color: kPrimary),
            ),
            child: TextField(
              controller: _quantityController,
              cursorColor: kPrimary,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '0',
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
          // Note/Instructions
          Text(
            'Note/Instructions',
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
              controller: _notesController,
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
          // Department Dropdown
          Text(
            'Select Department to Request from',
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
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDepartment,
                hint: Text(
                  'Select Department',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    color: kprimaryTextColor2,
                  ),
                ),
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: kprimaryTextColor2,
                ),
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: kprimaryTextColor1,
                ),
                items: _departments.map((String department) {
                  return DropdownMenuItem<String>(
                    value: department,
                    child: Text(department),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDepartment = newValue;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Continue button
          GestureDetector(
            onTap: _submitRequisition,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Continue',
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

  Widget _buildPendingTab() {
    // Sample pending requisitions data
    final pendingRequisitions = [
      {
        'item': 'Fresh Tomatoes',
        'quantity': '50 kg',
        'department': 'Kitchen',
        'date': 'Nov 20, 2025',
        'status': 'Pending Approval',
      },
      {
        'item': 'Bread Flour',
        'quantity': '100 kg',
        'department': 'Procurement',
        'date': 'Nov 19, 2025',
        'status': 'Under Review',
      },
      {
        'item': 'Cleaning Supplies',
        'quantity': '20 units',
        'department': 'Stock',
        'date': 'Nov 18, 2025',
        'status': 'Pending Approval',
      },
    ];

    if (pendingRequisitions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pending_actions_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Pending Requisitions',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your pending requisitions will appear here',
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
      itemCount: pendingRequisitions.length,
      itemBuilder: (context, index) {
        final requisition = pendingRequisitions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          requisition['item'] as String,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: kprimaryTextColor1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Qty: ${requisition['quantity']}',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            color: kprimaryTextColor2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      requisition['status'] as String,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.business_center,
                    size: 14,
                    color: kprimaryTextColor2,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    requisition['department'] as String,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 13,
                      color: kprimaryTextColor2,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: kprimaryTextColor2,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    requisition['date'] as String,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 13,
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

  Widget _buildCompletedTab() {
    // Sample completed requisitions data
    final completedRequisitions = [
      {
        'item': 'Chicken Breast',
        'quantity': '75 kg',
        'department': 'Kitchen',
        'date': 'Nov 15, 2025',
        'completedDate': 'Nov 17, 2025',
        'status': 'Approved',
      },
      {
        'item': 'Office Supplies',
        'quantity': '1 set',
        'department': 'Stock',
        'date': 'Nov 12, 2025',
        'completedDate': 'Nov 14, 2025',
        'status': 'Approved',
      },
      {
        'item': 'Packaging Materials',
        'quantity': '500 units',
        'department': 'Processing',
        'date': 'Nov 10, 2025',
        'completedDate': 'Nov 12, 2025',
        'status': 'Approved',
      },
      {
        'item': 'Receipt Paper Rolls',
        'quantity': '30 rolls',
        'department': 'POS',
        'date': 'Nov 8, 2025',
        'completedDate': 'Nov 9, 2025',
        'status': 'Rejected',
      },
    ];

    if (completedRequisitions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Completed Requisitions',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed requisitions will appear here',
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
      itemCount: completedRequisitions.length,
      itemBuilder: (context, index) {
        final requisition = completedRequisitions[index];
        final isApproved = requisition['status'] == 'Approved';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          requisition['item'] as String,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: kprimaryTextColor1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Qty: ${requisition['quantity']}',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            color: kprimaryTextColor2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (isApproved ? Colors.green : Colors.red)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      requisition['status'] as String,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isApproved ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.business_center,
                    size: 14,
                    color: kprimaryTextColor2,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    requisition['department'] as String,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 13,
                      color: kprimaryTextColor2,
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
                    'Requested: ${requisition['date']}',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 13,
                      color: kprimaryTextColor2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: kprimaryTextColor2),
                  const SizedBox(width: 6),
                  Text(
                    'Completed: ${requisition['completedDate']}',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 13,
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
