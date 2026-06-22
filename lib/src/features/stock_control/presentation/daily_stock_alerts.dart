import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/globals/notifications/stock_notification_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enhanced Notification Settings Screen
class StockNotificationSettingsScreen extends StatelessWidget {
  const StockNotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;

          return ListView(
            padding: EdgeInsets.symmetric(
              vertical: _getListPadding(screenWidth),
            ),
            children: [
              const DailyStockCheckSettings(),
              SizedBox(height: _getCardSpacing(screenWidth)),
              const NotificationTypeSettings(),
              SizedBox(height: _getCardSpacing(screenWidth)),
              _buildNotificationSummary(screenWidth),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Notification Settings',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNotificationSummary(double screenWidth) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: _getHorizontalMargin(screenWidth),
      ),
      padding: EdgeInsets.all(_getContainerPadding(screenWidth)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: kPrimary,
                size: _getHeaderIconSize(screenWidth),
              ),
              SizedBox(width: _getIconSpacing(screenWidth)),
              Text(
                'About Notifications',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getHeaderFontSize(screenWidth),
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: _getSectionSpacing(screenWidth)),
          Text(
            'Stock notifications help you stay on top of your inventory. Enable the alerts that matter most to your needs.',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getInfoDescFontSize(screenWidth),
              fontWeight: FontWeight.w400,
              color: const Color(0xFF757575),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  double _getHorizontalMargin(double width) => width < 360
      ? 12
      : width < 600
      ? 16
      : 20;
  double _getContainerPadding(double width) => width < 360
      ? 12
      : width < 600
      ? 16
      : 20;
  double _getListPadding(double width) => width < 360
      ? 12
      : width < 600
      ? 16
      : 20;
  double _getCardSpacing(double width) => width < 360
      ? 12
      : width < 600
      ? 16
      : 20;
  double _getHeaderIconSize(double width) => width < 360
      ? 18
      : width < 600
      ? 20
      : 22;
  double _getIconSpacing(double width) => width < 360
      ? 8
      : width < 600
      ? 10
      : 12;
  double _getHeaderFontSize(double width) => width < 360
      ? 14
      : width < 600
      ? 16
      : 17;
  double _getInfoDescFontSize(double width) => width < 360
      ? 11
      : width < 600
      ? 12
      : 13;
  double _getSectionSpacing(double width) => width < 360
      ? 12
      : width < 600
      ? 16
      : 18;
}

// New Widget for Individual Notification Type Settings
class NotificationTypeSettings extends StatefulWidget {
  const NotificationTypeSettings({super.key});

  @override
  State<NotificationTypeSettings> createState() =>
      _NotificationTypeSettingsState();
}

class _NotificationTypeSettingsState extends State<NotificationTypeSettings> {
  bool _isLoading = true;
  bool _lowStockEnabled = true;
  bool _criticalStockEnabled = true;
  bool _expiringSoonEnabled = true;
  bool _expiredEnabled = true;
  bool _outOfStockEnabled = true;
  bool _nearReorderEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _lowStockEnabled = prefs.getBool('notif_low_stock') ?? true;
        _criticalStockEnabled = prefs.getBool('notif_critical_stock') ?? true;
        _expiringSoonEnabled = prefs.getBool('notif_expiring_soon') ?? true;
        _expiredEnabled = prefs.getBool('notif_expired') ?? true;
        _outOfStockEnabled = prefs.getBool('notif_out_of_stock') ?? true;
        _nearReorderEnabled = prefs.getBool('notif_near_reorder') ?? true;

        _isLoading = false;
      });
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: _getHorizontalMargin(screenWidth),
            vertical: 8,
          ),
          padding: EdgeInsets.all(_getContainerPadding(screenWidth)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(_getIconPadding(screenWidth)),
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.notifications_active,
                      color: kPrimary,
                      size: _getMainIconSize(screenWidth),
                    ),
                  ),
                  SizedBox(width: _getIconSpacing(screenWidth)),
                  Expanded(
                    child: Text(
                      'Alert Types',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: _getTitleFontSize(screenWidth),
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: _getSectionSpacing(screenWidth)),
              const Divider(height: 1, color: Color(0xFFE0E0E0)),
              SizedBox(height: _getSectionSpacing(screenWidth)),
              _buildNotificationToggle(
                screenWidth: screenWidth,
                icon: Icons.inventory_2_outlined,
                iconColor: kPrimary,
                title: 'Low Stock',
                description: 'Items running low',
                value: _lowStockEnabled,
                onChanged: (value) {
                  setState(() => _lowStockEnabled = value);
                  _saveSetting('notif_low_stock', value);
                },
              ),
              SizedBox(height: _getItemSpacing(screenWidth)),
              _buildNotificationToggle(
                screenWidth: screenWidth,
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFFF6B00),
                title: 'Critical Stock',
                description: 'Critically low items',
                value: _criticalStockEnabled,
                onChanged: (value) {
                  setState(() => _criticalStockEnabled = value);
                  _saveSetting('notif_critical_stock', value);
                },
              ),
              SizedBox(height: _getItemSpacing(screenWidth)),
              _buildNotificationToggle(
                screenWidth: screenWidth,
                icon: Icons.access_time,
                iconColor: const Color(0xFFA1000C),
                title: 'Expiring Soon',
                description: 'Items expiring within 7 days',
                value: _expiringSoonEnabled,
                onChanged: (value) {
                  setState(() => _expiringSoonEnabled = value);
                  _saveSetting('notif_expiring_soon', value);
                },
              ),
              SizedBox(height: _getItemSpacing(screenWidth)),
              _buildNotificationToggle(
                screenWidth: screenWidth,
                icon: Icons.error_outline,
                iconColor: const Color(0xFFE53935),
                title: 'Expired Items',
                description: 'Items past expiry date',
                value: _expiredEnabled,
                onChanged: (value) {
                  setState(() => _expiredEnabled = value);
                  _saveSetting('notif_expired', value);
                },
              ),
              SizedBox(height: _getItemSpacing(screenWidth)),
              _buildNotificationToggle(
                screenWidth: screenWidth,
                icon: Icons.remove_shopping_cart,
                iconColor: const Color(0xFF757575),
                title: 'Out of Stock',
                description: 'Items completely depleted',
                value: _outOfStockEnabled,
                onChanged: (value) {
                  setState(() => _outOfStockEnabled = value);
                  _saveSetting('notif_out_of_stock', value);
                },
              ),
              SizedBox(height: _getItemSpacing(screenWidth)),
              _buildNotificationToggle(
                screenWidth: screenWidth,
                icon: Icons.trending_down,
                iconColor: const Color(0xFFF57F17),
                title: 'Near Reorder',
                description: 'Items approaching reorder level',
                value: _nearReorderEnabled,
                onChanged: (value) {
                  setState(() => _nearReorderEnabled = value);
                  _saveSetting('notif_near_reorder', value);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationToggle({
    required double screenWidth,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(_getInfoIconPadding(screenWidth)),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: _getInfoIconSize(screenWidth),
          ),
        ),
        SizedBox(width: _getIconSpacing(screenWidth)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getInfoLabelFontSize(screenWidth),
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: _getTextSpacing(screenWidth)),
              Text(
                description,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getInfoDescFontSize(screenWidth),
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
        Transform.scale(
          scale: _getSwitchScale(screenWidth),
          child: CupertinoSwitch(
            value: value,
            activeTrackColor: kPrimary,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  double _getHorizontalMargin(double width) => width < 360
      ? 12
      : width < 600
      ? 16
      : 20;
  double _getContainerPadding(double width) => width < 360
      ? 12
      : width < 600
      ? 16
      : 20;
  double _getIconPadding(double width) => width < 360
      ? 6
      : width < 600
      ? 8
      : 10;
  double _getMainIconSize(double width) => width < 360
      ? 20
      : width < 600
      ? 24
      : 26;
  double _getInfoIconSize(double width) => width < 360
      ? 18
      : width < 600
      ? 20
      : 22;
  double _getInfoIconPadding(double width) => width < 360
      ? 6
      : width < 600
      ? 8
      : 10;
  double _getIconSpacing(double width) => width < 360
      ? 10
      : width < 600
      ? 12
      : 14;
  double _getTitleFontSize(double width) => width < 360
      ? 14
      : width < 600
      ? 16
      : 17;
  double _getInfoLabelFontSize(double width) => width < 360
      ? 13
      : width < 600
      ? 14
      : 15;
  double _getInfoDescFontSize(double width) => width < 360
      ? 11
      : width < 600
      ? 12
      : 13;
  double _getTextSpacing(double width) => width < 360
      ? 2
      : width < 600
      ? 3
      : 4;
  double _getSectionSpacing(double width) => width < 360
      ? 12
      : width < 600
      ? 16
      : 18;
  double _getItemSpacing(double width) => width < 360
      ? 10
      : width < 600
      ? 12
      : 14;
  double _getSwitchScale(double width) => width < 360
      ? 0.85
      : width < 600
      ? 0.9
      : 1.0;
}

// Keep your existing DailyStockCheckSettings widget as is
class DailyStockCheckSettings extends StatefulWidget {
  const DailyStockCheckSettings({super.key});

  @override
  State<DailyStockCheckSettings> createState() =>
      _DailyStockCheckSettingsState();
}

class _DailyStockCheckSettingsState extends State<DailyStockCheckSettings> {
  final _stockNotificationHelper = StockNotificationHelper();
  bool _isEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isEnabled = prefs.getBool('daily_stock_check_enabled') ?? false;
        final hour = prefs.getInt('daily_stock_check_hour') ?? 9;
        final minute = prefs.getInt('daily_stock_check_minute') ?? 0;
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_stock_check_enabled', _isEnabled);
    await prefs.setInt('daily_stock_check_hour', _selectedTime.hour);
    await prefs.setInt('daily_stock_check_minute', _selectedTime.minute);

    if (_isEnabled) {
      await _stockNotificationHelper.scheduleDailyStockCheck(
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
      );
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      await _saveSettings();

      if (_isEnabled && mounted) {
        _showSnackBar(
          'Daily stock check scheduled for ${_formatTime(_selectedTime)}',
        );
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: kGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: _getHorizontalMargin(screenWidth),
            vertical: 8,
          ),
          padding: EdgeInsets.all(_getContainerPadding(screenWidth)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(_getIconPadding(screenWidth)),
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.schedule,
                      color: kPrimary,
                      size: _getMainIconSize(screenWidth),
                    ),
                  ),
                  SizedBox(width: _getIconSpacing(screenWidth)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Stock Check',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: _getTitleFontSize(screenWidth),
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: _getTextSpacing(screenWidth)),
                        Text(
                          'Get daily reminders to review inventory',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: _getSubtitleFontSize(screenWidth),
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: _getSwitchScale(screenWidth),
                    child: CupertinoSwitch(
                      value: _isEnabled,
                      activeTrackColor: kPrimary,
                      onChanged: (value) async {
                        setState(() {
                          _isEnabled = value;
                        });
                        await _saveSettings();

                        if (value) {
                          _showSnackBar(
                            'Daily stock check enabled at ${_formatTime(_selectedTime)}',
                          );
                        } else {
                          _showSnackBar('Daily stock check disabled');
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (_isEnabled) ...[
                SizedBox(height: _getSectionSpacing(screenWidth)),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                SizedBox(height: _getSectionSpacing(screenWidth)),
                InkWell(
                  onTap: _selectTime,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.all(_getTimePickerPadding(screenWidth)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: kPrimary,
                          size: _getSecondaryIconSize(screenWidth),
                        ),
                        SizedBox(width: _getIconSpacing(screenWidth)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notification Time',
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: _getLabelFontSize(screenWidth),
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF757575),
                                ),
                              ),
                              SizedBox(height: _getTextSpacing(screenWidth)),
                              Text(
                                _formatTime(_selectedTime),
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: _getTimeFontSize(screenWidth),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: const Color(0xFF757575),
                          size: _getSecondaryIconSize(screenWidth),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  double _getHorizontalMargin(double width) => width < 360
      ? 12
      : width < 600
      ? 16
      : 20;
  double _getContainerPadding(double width) => width < 360
      ? 12
      : width < 600
      ? 16
      : 20;
  double _getIconPadding(double width) => width < 360
      ? 6
      : width < 600
      ? 8
      : 10;
  double _getMainIconSize(double width) => width < 360
      ? 20
      : width < 600
      ? 24
      : 26;
  double _getSecondaryIconSize(double width) => width < 360
      ? 18
      : width < 600
      ? 20
      : 22;
  double _getIconSpacing(double width) => width < 360
      ? 10
      : width < 600
      ? 12
      : 14;
  double _getTitleFontSize(double width) => width < 360
      ? 14
      : width < 600
      ? 16
      : 17;
  double _getSubtitleFontSize(double width) => width < 360
      ? 11
      : width < 600
      ? 13
      : 14;
  double _getLabelFontSize(double width) => width < 360
      ? 11
      : width < 600
      ? 13
      : 14;
  double _getTimeFontSize(double width) => width < 360
      ? 14
      : width < 600
      ? 16
      : 17;
  double _getTextSpacing(double width) => width < 360
      ? 2
      : width < 600
      ? 3
      : 4;
  double _getSectionSpacing(double width) => width < 360
      ? 12
      : width < 600
      ? 16
      : 18;
  double _getTimePickerPadding(double width) => width < 360
      ? 10
      : width < 600
      ? 12
      : 14;
  double _getSwitchScale(double width) => width < 360
      ? 0.85
      : width < 600
      ? 0.9
      : 1.0;
}
