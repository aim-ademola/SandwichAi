import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  static const String boxName = 'settings_box';
  static const String themeKey = 'theme_mode';

  ThemeCubit() : super(const ThemeState(themeMode: ThemeMode.system));

  Future<void> initialize() async {
    final box = Hive.box(boxName);

    final storedTheme = box.get(themeKey, defaultValue: 'system');

    emit(ThemeState(themeMode: _themeModeFromString(storedTheme)));
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    final box = Hive.box(boxName);

    await box.put(themeKey, _themeModeToString(themeMode));

    emit(state.copyWith(themeMode: themeMode));
  }

  Future<void> toggleTheme() async {
    if (state.themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;

      case 'dark':
        return ThemeMode.dark;

      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';

      case ThemeMode.dark:
        return 'dark';

      case ThemeMode.system:
        return 'system';
    }
  }
}
