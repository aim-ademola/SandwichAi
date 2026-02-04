import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';

class MyTaskScreen extends StatefulWidget {
  const MyTaskScreen({super.key});

  @override
  State<MyTaskScreen> createState() => _MyTaskScreenState();
}

class _MyTaskScreenState extends State<MyTaskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<TaskData> _tasks = [
    TaskData(
      title: 'Restock napkins at Station 3',
      priority: TaskPriority.high,
      dueDate: DateTime.now(),
      dueTime: '5:00 PM',
      status: TaskStatus.toDo,
    ),
    TaskData(
      title: 'Wipe down all front-of-house',
      priority: TaskPriority.normal,
      dueDate: DateTime.now().add(const Duration(days: 2)),
      dueTime: '5:00 PM',
      status: TaskStatus.toDo,
    ),
    TaskData(
      title: 'Setup Table and fix all Tags',
      priority: TaskPriority.urgent,
      dueDate: DateTime.now(),
      dueTime: '5:00 PM',
      status: TaskStatus.toDo,
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
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'My Task',
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
            Container(color: Colors.white, child: _buildTabBar()),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTaskList(TaskStatus.toDo),
                  _buildTaskList(TaskStatus.inProgress),
                  _buildTaskList(TaskStatus.completed),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabTextSize = _getTabTextSize(constraints.maxWidth);

        return TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF5722),
          unselectedLabelColor: const Color(0xFF757575),
          indicatorColor: const Color(0xFFFF5722),
          indicatorWeight: 3,
          labelStyle: WorkSansAppTextStyles.medium.copyWith(
            fontSize: tabTextSize,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: WorkSansAppTextStyles.medium.copyWith(
            fontSize: tabTextSize,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(text: 'To Do (${_getTaskCount(TaskStatus.toDo)})'),
            const Tab(text: 'In Progress'),
            const Tab(text: 'Completed'),
          ],
        );
      },
    );
  }

  Widget _buildTaskList(TaskStatus status) {
    final filteredTasks = _tasks
        .where((task) => task.status == status)
        .toList();

    if (filteredTasks.isEmpty) {
      return Center(
        child: Text(
          'No tasks',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _getHorizontalPadding(constraints.maxWidth);
        final verticalSpacing = _getVerticalSpacing(constraints.maxWidth);

        return ListView.separated(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalSpacing,
          ),
          itemCount: filteredTasks.length,
          separatorBuilder: (context, index) =>
              SizedBox(height: verticalSpacing),
          itemBuilder: (context, index) {
            return _buildTaskCard(filteredTasks[index], constraints.maxWidth);
          },
        );
      },
    );
  }

  Widget _buildTaskCard(TaskData task, double screenWidth) {
    final textSize = _getBodyTextSize(screenWidth);
    final iconSize = _getIconSize(screenWidth);
    final buttonTextSize = _getButtonTextSize(screenWidth);

    return Container(
      padding: EdgeInsets.all(_getCardPadding(screenWidth)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Priority icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getPriorityColor(task.priority).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.error_outline,
                  color: _getPriorityColor(task.priority),
                  size: iconSize,
                ),
              ),
              const SizedBox(width: 12),
              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: textSize,
                        fontWeight: FontWeight.w600,
                        color: kprimaryTextColor1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPriorityText(task.priority),
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: textSize - 2,
                        fontWeight: FontWeight.w500,
                        color: _getPriorityColor(task.priority),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Due date
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: iconSize - 4,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                'Due: ${_formatDueDate(task.dueDate)} at ${task.dueTime}',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: textSize - 2,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleStartTask(task),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF5722),
                    side: const BorderSide(color: Color(0xFFFF5722)),
                    backgroundColor: const Color(0xFFFFEBEE),
                    padding: EdgeInsets.symmetric(
                      vertical: _getButtonVerticalPadding(screenWidth),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Start Task',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: buttonTextSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF5722),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleCompleteTask(task),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: _getButtonVerticalPadding(screenWidth),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Complete',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: buttonTextSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const Color(0xFFFF5252);
      case TaskPriority.normal:
        return const Color(0xFF4CAF50);
      case TaskPriority.urgent:
        return const Color(0xFFFF1744);
    }
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'High Priority';
      case TaskPriority.normal:
        return 'Normal Priority';
      case TaskPriority.urgent:
        return 'Urgent Priority';
    }
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Today';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      final weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return '${weekdays[date.weekday - 1]} ${date.day}';
    }
  }

  int _getTaskCount(TaskStatus status) {
    return _tasks.where((task) => task.status == status).length;
  }

  void _handleStartTask(TaskData task) {
    setState(() {
      task.status = TaskStatus.inProgress;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Started: ${task.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleCompleteTask(TaskData task) {
    setState(() {
      task.status = TaskStatus.completed;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Completed: ${task.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Responsive sizing functions
  double _getHorizontalPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    if (width < 900) return 24;
    return 32;
  }

  double _getVerticalSpacing(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    if (width < 900) return 16;
    return 18;
  }

  double _getCardPadding(double width) {
    if (width < 360) return 14;
    if (width < 600) return 16;
    if (width < 900) return 18;
    return 20;
  }

  double _getBodyTextSize(double width) {
    if (width < 360) return 14;
    if (width < 600) return 15;
    if (width < 900) return 16;
    return 17;
  }

  double _getTabTextSize(double width) {
    if (width < 360) return 13;
    if (width < 600) return 14;
    if (width < 900) return 15;
    return 16;
  }

  double _getIconSize(double width) {
    if (width < 360) return 20;
    if (width < 600) return 22;
    if (width < 900) return 24;
    return 26;
  }

  double _getButtonTextSize(double width) {
    if (width < 360) return 13;
    if (width < 600) return 14;
    if (width < 900) return 15;
    return 16;
  }

  double _getButtonVerticalPadding(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    if (width < 900) return 16;
    return 18;
  }
}

// Data models
enum TaskStatus { toDo, inProgress, completed }

enum TaskPriority { high, normal, urgent }

class TaskData {
  final String title;
  final TaskPriority priority;
  final DateTime dueDate;
  final String dueTime;
  TaskStatus status;

  TaskData({
    required this.title,
    required this.priority,
    required this.dueDate,
    required this.dueTime,
    required this.status,
  });
}
