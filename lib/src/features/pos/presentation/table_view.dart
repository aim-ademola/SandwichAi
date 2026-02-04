import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';

class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({super.key});

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<TableData> _tables = [
    TableData(
      id: 1,
      name: 'Table 1',
      status: TableStatus.available,
      category: 'All',
      imageUrl: 'assets/img/table1.png',
    ),
    TableData(
      id: 2,
      name: 'Table 2',
      status: TableStatus.occupied,
      category: 'Outdoor',
      imageUrl: 'assets/img/table2.png',
    ),
    TableData(
      id: 3,
      name: 'Table 3',
      status: TableStatus.available,
      category: 'Indoor',
      imageUrl: 'assets/img/table3.png',
    ),
    TableData(
      id: 4,
      name: 'Table 4',
      status: TableStatus.needsCleaning,
      category: 'Indoor',
      imageUrl: 'assets/img/table2.png',
    ),
    TableData(
      id: 5,
      name: 'Table 5',
      status: TableStatus.occupied,
      category: 'Indoor',
      imageUrl: 'assets/img/table1.png',
    ),
    TableData(
      id: 6,
      name: 'Table 6',
      status: TableStatus.available,
      category: 'Outdoor',
      imageUrl: 'assets/img/table3.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TableData> _getFilteredTables() {
    switch (_tabController.index) {
      case 0:
        return _tables;
      case 1:
        return _tables.where((t) => t.category == 'Indoor').toList();
      case 2:
        return _tables.where((t) => t.category == 'Outdoor').toList();
      default:
        return _tables;
    }
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
          title: Text(
            'Tables',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: kprimaryTextColor1),
              onPressed: () {
                // Add new table functionality
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                onTap: (index) {
                  setState(() {});
                },
                labelColor: kprimaryTextColor1,
                isScrollable: false,
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
                  Tab(text: 'All'),
                  Tab(text: 'Indoor'),
                  Tab(text: 'Outdoor'),
                ],
              ),
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = _getHorizontalPadding(
              constraints.maxWidth,
            );
            final spacing = _getSpacing(constraints.maxWidth);
            final textSize = _getBodyTextSize(constraints.maxWidth);

            return TabBarView(
              controller: _tabController,
              children: [
                _buildTableGrid(horizontalPadding, spacing, textSize),
                _buildTableGrid(horizontalPadding, spacing, textSize),
                _buildTableGrid(horizontalPadding, spacing, textSize),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTableGrid(double padding, double spacing, double textSize) {
    final filteredTables = _getFilteredTables();

    return GridView.builder(
      padding: EdgeInsets.all(padding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 0.85,
      ),
      itemCount: filteredTables.length,
      itemBuilder: (context, index) {
        return _buildTableCard(filteredTables[index], textSize);
      },
    );
  }

  Widget _buildTableCard(TableData table, double textSize) {
    return InkWell(
      onTap: () {
        // Navigate to table details or order screen
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Table image
              Image.asset(
                table.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.table_restaurant, size: 60),
                  );
                },
              ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              // Table info
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      table.name,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: textSize + 2,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(table.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(table.status),
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: textSize - 2,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return const Color(0xFF30A46C).withOpacity(0.73);
      case TableStatus.occupied:
        return const Color(0xFFFFE770).withOpacity(0.73);
      case TableStatus.needsCleaning:
        return const Color(0xFFC2E5FF).withOpacity(0.73);
    }
  }

  String _getStatusText(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.needsCleaning:
        return 'Needs Cleaning';
    }
  }

  // Responsive sizing functions
  double _getHorizontalPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    if (width < 900) return 24;
    return 32;
  }

  double _getSpacing(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    if (width < 900) return 16;
    return 18;
  }

  double _getBodyTextSize(double width) {
    if (width < 360) return 14;
    if (width < 600) return 15;
    if (width < 900) return 16;
    return 17;
  }
}

// Data models
enum TableStatus { available, occupied, needsCleaning }

class TableData {
  final int id;
  final String name;
  final TableStatus status;
  final String category;
  final String imageUrl;

  TableData({
    required this.id,
    required this.name,
    required this.status,
    required this.category,
    required this.imageUrl,
  });
}
