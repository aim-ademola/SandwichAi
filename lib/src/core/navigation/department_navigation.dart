enum AppDepartmentModule {
  kitchen,
  processing,
  procurement,
  stockControl,
  pointOfSale,
}

extension AppDepartmentModuleRoute on AppDepartmentModule {
  String get route {
    switch (this) {
      case AppDepartmentModule.kitchen:
        return '/Kitchen-nav';
      case AppDepartmentModule.processing:
        return '/Processing-nav';
      case AppDepartmentModule.procurement:
        return '/Procurement-nav';
      case AppDepartmentModule.stockControl:
        return '/Stock-control-nav';
      case AppDepartmentModule.pointOfSale:
        return '/Pos-nav';
    }
  }

  String get drawerTitle {
    switch (this) {
      case AppDepartmentModule.kitchen:
        return 'Kitchen';
      case AppDepartmentModule.processing:
        return 'Processing';
      case AppDepartmentModule.procurement:
        return 'Procurement';
      case AppDepartmentModule.stockControl:
        return 'Stock Control';
      case AppDepartmentModule.pointOfSale:
        return 'Point of Sale';
    }
  }
}

class DepartmentNavigation {
  const DepartmentNavigation._();

  static String? routeForDepartment(String? department) {
    return moduleForDepartment(department)?.route;
  }

  static AppDepartmentModule? moduleForDepartment(String? department) {
    final normalized = _normalize(department);
    if (normalized.isEmpty) return null;

    if (normalized.contains('KITCHEN')) {
      return AppDepartmentModule.kitchen;
    }
    if (normalized.contains('PROCESSING')) {
      return AppDepartmentModule.processing;
    }
    if (normalized.contains('PROCUREMENT')) {
      return AppDepartmentModule.procurement;
    }
    if (normalized.contains('STOCK') ||
        normalized.contains('INVENTORY') ||
        normalized.contains('STORE')) {
      return AppDepartmentModule.stockControl;
    }
    if (normalized.contains('CUSTOMER') ||
        normalized == 'POS' ||
        normalized.contains('POINT OF SALE') ||
        normalized.contains('SALES')) {
      return AppDepartmentModule.pointOfSale;
    }

    return null;
  }

  static String _normalize(String? value) {
    return (value ?? '')
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toUpperCase();
  }
}
