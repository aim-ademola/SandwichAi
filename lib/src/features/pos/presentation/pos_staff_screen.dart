import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/pos/data/model/staffmember_model.dart';
import 'package:sandwich_ai/src/features/pos/presentation/pos_assign_task.dart';

class PosStaffScreen extends StatefulWidget {
  const PosStaffScreen({super.key});

  @override
  State<PosStaffScreen> createState() => _PosStaffScreenState();
}

class _PosStaffScreenState extends State<PosStaffScreen> {
  final TextEditingController _searchController = TextEditingController();
  StaffStatus _selectedStatus = StaffStatus.all;

  final List<StaffMember> _staffMembers = [
    StaffMember(
      id: '1',
      name: 'Viviana Kie',
      role: 'Cashier',
      imageUrl: 'assets/img/vivan.png',
      isAvailable: false,
    ),
    StaffMember(
      id: '2',
      name: 'Elvis Mike',
      role: 'Server',
      imageUrl: 'assets/img/sarah.png',
      isAvailable: true,
    ),
    StaffMember(
      id: '3',
      name: 'Sarah Grace',
      role: 'Server',
      imageUrl: 'assets/img/sarah.png',
      isAvailable: true,
    ),
    StaffMember(
      id: '4',
      name: 'Temi Ovie',
      role: 'Cashier',
      imageUrl: 'assets/img/sarah.png',
      isAvailable: true,
    ),
    StaffMember(
      id: '5',
      name: 'David Dre',
      role: 'Server',
      imageUrl: 'assets/img/sarah.png',
      isAvailable: true,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StaffMember> _getFilteredStaff() {
    List<StaffMember> filtered = _staffMembers;

    // Filter by status
    if (_selectedStatus == StaffStatus.available) {
      filtered = filtered.where((staff) => staff.isAvailable).toList();
    } else if (_selectedStatus == StaffStatus.unavailable) {
      filtered = filtered.where((staff) => !staff.isAvailable).toList();
    }

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where(
            (staff) => staff.name.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ),
          )
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredStaff = _getFilteredStaff();

    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const AppIcon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            children: [
              Text(
                'POS Staff',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kprimaryTextColor1,
                ),
              ),
              Text(
                'Manager View',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: kprimaryTextColor2,
                ),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Search bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TextField(
                cursorColor: kPrimary,
                controller: _searchController,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Find Staff member...',
                  hintStyle: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    color: kprimaryTextColor2,
                  ),
                  prefixIcon: const AppIcon(
                    Icons.search,
                    color: kprimaryTextColor2,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F6F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Status filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'All Staff',
                    isSelected: _selectedStatus == StaffStatus.all,
                    onTap: () =>
                        setState(() => _selectedStatus = StaffStatus.all),
                  ),
                  const SizedBox(width: 12),
                  _buildFilterChip(
                    label: 'Unavailable',
                    isSelected: _selectedStatus == StaffStatus.unavailable,
                    onTap: () => setState(
                      () => _selectedStatus = StaffStatus.unavailable,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildFilterChip(
                    label: 'Available',
                    isSelected: _selectedStatus == StaffStatus.available,
                    onTap: () =>
                        setState(() => _selectedStatus = StaffStatus.available),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Staff list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredStaff.length,
                itemBuilder: (context, index) {
                  final staff = filteredStaff[index];
                  return _buildStaffCard(staff);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kPrimary : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : kprimaryTextColor1,
          ),
        ),
      ),
    );
  }

  Widget _buildStaffCard(StaffMember staff) {
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
      child: Row(
        children: [
          // Staff avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: staff.isAvailable
                        ? Colors.green
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    staff.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const AppIcon(Icons.person, size: 30),
                      );
                    },
                  ),
                ),
              ),
              // Icon positioned at the bottom
              staff.isAvailable == false
                  ? Positioned(
                      bottom: -1,
                      left: 0,
                      right: -30,
                      child: AppIcon(
                        Icons.cloud,
                        size: 16,
                        color: Colors.blueGrey,
                      ),
                    )
                  : SizedBox(),
            ],
          ),
          const SizedBox(width: 12),
          // Staff details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.name,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kprimaryTextColor1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  staff.role,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: kprimaryTextColor2,
                  ),
                ),
              ],
            ),
          ),
          // Assign task button (only for available staff)
          if (_selectedStatus == StaffStatus.available && staff.isAvailable)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => PosAssignTaskScreen(staff: staff),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppIcon(
                      Icons.assignment_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Assign Task',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
