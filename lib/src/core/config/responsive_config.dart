import 'package:flutter/material.dart';

class Breakpoints {
  static const double mobile = 360;
  static const double mobileLarge = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double desktopLarge = 1800;
}

/// Responsive configuration singleton for consistent sizing across the app
class ResponsiveConfig {
  ResponsiveConfig._();
  static final ResponsiveConfig _instance = ResponsiveConfig._();
  static ResponsiveConfig get instance => _instance;

  /// Factory constructor for convenient access
  factory ResponsiveConfig() => _instance;

  // ==================== LAYOUT & SPACING ====================

  /// Get horizontal padding based on screen width
  double getHorizontalPadding(double width) {
    if (width < Breakpoints.mobile) return 16;
    if (width < Breakpoints.mobileLarge) return 24;
    if (width < Breakpoints.tablet) return 48;
    if (width < Breakpoints.desktop) return 80;
    if (width < Breakpoints.desktopLarge) return 120;
    return 160;
  }

  /// Get vertical padding based on screen height
  double getVerticalPadding(double height) {
    if (height < 600) return 16;
    if (height < 800) return 24;
    if (height < 1000) return 32;
    return 40;
  }

  /// Get vertical spacing between elements
  double getVerticalSpacing(double height) {
    if (height < 600) return 16;
    if (height < 800) return 20;
    if (height < 1000) return 24;
    return 28;
  }

  /// Get horizontal spacing between elements
  double getHorizontalSpacing(double width) {
    if (width < Breakpoints.mobile) return 12;
    if (width < Breakpoints.mobileLarge) return 16;
    if (width < Breakpoints.tablet) return 20;
    return 24;
  }

  /// Get maximum content width for centered layouts
  double getMaxContentWidth(double width) {
    if (width < Breakpoints.mobileLarge) return 400;
    if (width < Breakpoints.tablet) return 500;
    if (width < Breakpoints.desktop) return 600;
    return 800;
  }

  /// Get card/container padding
  EdgeInsets getCardPadding(double width) {
    if (width < Breakpoints.mobile) {
      return const EdgeInsets.all(12);
    }
    if (width < Breakpoints.mobileLarge) {
      return const EdgeInsets.all(16);
    }
    if (width < Breakpoints.tablet) {
      return const EdgeInsets.all(20);
    }
    return const EdgeInsets.all(24);
  }

  // ==================== TYPOGRAPHY ====================

  /// Get display/heading font size (largest text)
  double getDisplayFontSize(double width) {
    if (width < Breakpoints.mobile) return 32;
    if (width < Breakpoints.mobileLarge) return 36;
    if (width < Breakpoints.tablet) return 40;
    if (width < Breakpoints.desktop) return 48;
    return 56;
  }

  /// Get title/heading font size
  double getTitleFontSize(double width) {
    if (width < Breakpoints.mobile) return 24;
    if (width < Breakpoints.mobileLarge) return 28;
    if (width < Breakpoints.tablet) return 32;
    if (width < Breakpoints.desktop) return 36;
    return 40;
  }

  /// Get subtitle/subheading font size
  double getSubtitleFontSize(double width) {
    if (width < Breakpoints.mobile) return 13;
    if (width < Breakpoints.mobileLarge) return 14;
    if (width < Breakpoints.tablet) return 15;
    if (width < Breakpoints.desktop) return 16;
    return 18;
  }

  /// Get body/paragraph text font size
  double getBodyFontSize(double width) {
    if (width < Breakpoints.mobile) return 14;
    if (width < Breakpoints.mobileLarge) return 15;
    if (width < Breakpoints.tablet) return 16;
    if (width < Breakpoints.desktop) return 17;
    return 18;
  }

  /// Get input field font size
  double getInputFontSize(double width) {
    if (width < Breakpoints.mobile) return 14;
    if (width < Breakpoints.mobileLarge) return 15;
    if (width < Breakpoints.tablet) return 16;
    if (width < Breakpoints.desktop) return 17;
    return 18;
  }

  /// Get button text font size
  double getButtonFontSize(double width) {
    if (width < Breakpoints.mobile) return 15;
    if (width < Breakpoints.mobileLarge) return 16;
    if (width < Breakpoints.tablet) return 17;
    if (width < Breakpoints.desktop) return 18;
    return 19;
  }

  /// Get caption/small text font size
  double getCaptionFontSize(double width) {
    if (width < Breakpoints.mobile) return 11;
    if (width < Breakpoints.mobileLarge) return 12;
    if (width < Breakpoints.tablet) return 13;
    return 14;
  }

  // ==================== INTERACTIVE ELEMENTS ====================

  /// Get button height
  double getButtonHeight(double width) {
    if (width < Breakpoints.mobile) return 48;
    if (width < Breakpoints.mobileLarge) return 52;
    if (width < Breakpoints.tablet) return 56;
    if (width < Breakpoints.desktop) return 60;
    return 64;
  }

  /// Get icon button size
  double getIconButtonSize(double width) {
    if (width < Breakpoints.mobile) return 40;
    if (width < Breakpoints.mobileLarge) return 44;
    if (width < Breakpoints.tablet) return 48;
    return 52;
  }

  /// Get checkbox/radio size
  double getCheckboxSize(double width) {
    if (width < Breakpoints.mobile) return 18;
    if (width < Breakpoints.mobileLarge) return 20;
    if (width < Breakpoints.tablet) return 22;
    return 24;
  }

  /// Get switch size scale factor
  double getSwitchScale(double width) {
    if (width < Breakpoints.mobile) return 0.9;
    if (width < Breakpoints.mobileLarge) return 1.0;
    if (width < Breakpoints.tablet) return 1.1;
    return 1.2;
  }

  // ==================== ICONS & IMAGES ====================

  /// Get icon size (general purpose)
  double getIconSize(double width) {
    if (width < Breakpoints.mobile) return 20;
    if (width < Breakpoints.mobileLarge) return 24;
    if (width < Breakpoints.tablet) return 28;
    return 32;
  }

  /// Get large icon size (e.g., for headers, empty states)
  double getLargeIconSize(double width) {
    if (width < Breakpoints.mobile) return 48;
    if (width < Breakpoints.mobileLarge) return 56;
    if (width < Breakpoints.tablet) return 64;
    if (width < Breakpoints.desktop) return 72;
    return 80;
  }

  /// Get avatar size
  double getAvatarSize(double width) {
    if (width < Breakpoints.mobile) return 40;
    if (width < Breakpoints.mobileLarge) return 48;
    if (width < Breakpoints.tablet) return 56;
    return 64;
  }

  // ==================== BORDERS & RADIUS ====================

  /// Get border radius for cards and containers
  double getBorderRadius(double width) {
    if (width < Breakpoints.mobile) return 8;
    if (width < Breakpoints.mobileLarge) return 10;
    if (width < Breakpoints.tablet) return 12;
    return 16;
  }

  /// Get button border radius
  double getButtonBorderRadius(double width) {
    if (width < Breakpoints.mobile) return 8;
    if (width < Breakpoints.mobileLarge) return 10;
    return 12;
  }

  // ==================== GRID & COLUMNS ====================

  /// Get number of grid columns based on width
  int getGridColumns(double width) {
    if (width < Breakpoints.mobile) return 1;
    if (width < Breakpoints.mobileLarge) return 2;
    if (width < Breakpoints.tablet) return 3;
    if (width < Breakpoints.desktop) return 4;
    return 6;
  }

  /// Get grid spacing
  double getGridSpacing(double width) {
    if (width < Breakpoints.mobile) return 12;
    if (width < Breakpoints.mobileLarge) return 16;
    if (width < Breakpoints.tablet) return 20;
    return 24;
  }

  // ==================== DEVICE TYPE HELPERS ====================

  /// Check if device is mobile
  bool isMobile(double width) => width < Breakpoints.mobileLarge;

  /// Check if device is tablet
  bool isTablet(double width) =>
      width >= Breakpoints.mobileLarge && width < Breakpoints.desktop;

  /// Check if device is desktop
  bool isDesktop(double width) => width >= Breakpoints.desktop;

  /// Get device type as string
  String getDeviceType(double width) {
    if (width < Breakpoints.mobileLarge) return 'mobile';
    if (width < Breakpoints.desktop) return 'tablet';
    return 'desktop';
  }
}

// ==================== EXTENSION FOR EASY ACCESS ====================

/// Extension on BuildContext for convenient access to responsive values
extension ResponsiveExtension on BuildContext {
  ResponsiveConfig get responsive => ResponsiveConfig.instance;

  /// Get current screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get current screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Quick access to responsive values
  double get horizontalPadding => responsive.getHorizontalPadding(screenWidth);

  double get verticalPadding => responsive.getVerticalPadding(screenHeight);

  double get verticalSpacing => responsive.getVerticalSpacing(screenHeight);

  double get titleFontSize => responsive.getTitleFontSize(screenWidth);

  double get subtitleFontSize => responsive.getSubtitleFontSize(screenWidth);

  double get bodyFontSize => responsive.getBodyFontSize(screenWidth);

  double get buttonHeight => responsive.getButtonHeight(screenWidth);

  bool get isMobile => responsive.isMobile(screenWidth);
  bool get isTablet => responsive.isTablet(screenWidth);
  bool get isDesktop => responsive.isDesktop(screenWidth);
}
