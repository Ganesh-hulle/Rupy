import 'package:flutter/material.dart';
import 'package:rupy/config/app_config.dart';
import 'package:rupy/settings/models/dashboard_widget_type.dart';
import 'package:rupy/settings/settings_state.dart';
import 'package:rupy/theme/theme_contrast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _themeModeKey = 'settings.themeMode';
  static const _contrastKey = 'settings.contrast';
  static const _cardRemindersKey = 'settings.cardRemindersEnabled';
  static const _appLockKey = 'settings.appLockEnabled';
  static const _testModeKey = 'settings.testModeEnabled';
  static const _baseCurrencyKey = 'settings.baseCurrency';
  static const _dashboardLayoutKey = 'settings.dashboardLayout';
  static const _hiddenWidgetsKey = 'settings.hiddenWidgets';

  Future<SettingsState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeModeKey);
    final contrastName = prefs.getString(_contrastKey);
    final reminders = prefs.getBool(_cardRemindersKey);
    final appLock = prefs.getBool(_appLockKey);
    final testMode = prefs.getBool(_testModeKey);
    final baseCurrency = prefs.getString(_baseCurrencyKey);
    final layoutNames = prefs.getStringList(_dashboardLayoutKey);
    final hiddenNames = prefs.getStringList(_hiddenWidgetsKey);

    return SettingsState(
      themeMode: _parseThemeMode(themeName),
      contrast: _parseContrast(contrastName),
      cardRemindersEnabled: reminders ?? true,
      appLockEnabled: appLock ?? false,
      testModeEnabled: testMode ?? false,
      baseCurrency: baseCurrency ?? AppConfig.baseCurrency,
      dashboardLayout: _parseLayout(layoutNames),
      hiddenWidgets: _parseHidden(hiddenNames),
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> saveContrast(AppContrast contrast) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_contrastKey, contrast.name);
  }

  Future<void> saveCardRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cardRemindersKey, enabled);
  }

  Future<void> saveAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockKey, enabled);
  }

  Future<void> saveTestModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_testModeKey, enabled);
  }

  Future<void> saveBaseCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseCurrencyKey, currency);
  }

  Future<void> saveDashboardLayout(
    List<DashboardWidgetType> layout,
    Set<DashboardWidgetType> hidden,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _dashboardLayoutKey,
      layout.map((e) => e.name).toList(),
    );
    await prefs.setStringList(
      _hiddenWidgetsKey,
      hidden.map((e) => e.name).toList(),
    );
  }

  ThemeMode _parseThemeMode(String? value) {
    if (value == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  AppContrast _parseContrast(String? value) {
    if (value == null) return AppContrast.normal;
    return AppContrast.values.firstWhere(
      (contrast) => contrast.name == value,
      orElse: () => AppContrast.normal,
    );
  }

  List<DashboardWidgetType>? _parseLayout(List<String>? names) {
    if (names == null) return null;
    return names
        .map(
          (n) => DashboardWidgetType.values.firstWhere(
            (e) => e.name == n,
            orElse: () => DashboardWidgetType.metrics,
          ),
        )
        .toList();
  }

  Set<DashboardWidgetType> _parseHidden(List<String>? names) {
    if (names == null) return {};
    return names
        .map(
          (n) => DashboardWidgetType.values.firstWhere(
            (e) => e.name == n,
            orElse: () => DashboardWidgetType.metrics,
          ),
        )
        .toSet();
  }
}
