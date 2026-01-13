import 'package:flutter/material.dart';
import 'package:rupy/config/app_config.dart';
import 'package:rupy/settings/models/dashboard_widget_type.dart';
import 'package:rupy/theme/theme_contrast.dart';

class SettingsState {
  final ThemeMode themeMode;
  final AppContrast contrast;
  final bool cardRemindersEnabled;
  final bool appLockEnabled;
  final bool testModeEnabled;
  final String baseCurrency;
  final List<DashboardWidgetType> dashboardLayout;
  final Set<DashboardWidgetType> hiddenWidgets;
  final String? error;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.contrast = AppContrast.normal,
    this.cardRemindersEnabled = true,
    this.appLockEnabled = false,
    this.testModeEnabled = false,
    this.baseCurrency = AppConfig.baseCurrency,
    List<DashboardWidgetType>? dashboardLayout,
    this.hiddenWidgets = const {},
    this.error,
  }) : dashboardLayout = dashboardLayout ?? DashboardWidgetType.defaultOrder;

  SettingsState copyWith({
    ThemeMode? themeMode,
    AppContrast? contrast,
    bool? cardRemindersEnabled,
    bool? appLockEnabled,
    bool? testModeEnabled,
    String? baseCurrency,
    List<DashboardWidgetType>? dashboardLayout,
    Set<DashboardWidgetType>? hiddenWidgets,
    String? error,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      contrast: contrast ?? this.contrast,
      cardRemindersEnabled: cardRemindersEnabled ?? this.cardRemindersEnabled,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      testModeEnabled: testModeEnabled ?? this.testModeEnabled,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      dashboardLayout: dashboardLayout ?? this.dashboardLayout,
      hiddenWidgets: hiddenWidgets ?? this.hiddenWidgets,
      error: error,
    );
  }
}
