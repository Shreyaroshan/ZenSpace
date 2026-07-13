import 'package:flutter/material.dart';

/// Global notifier for theme mode (Light/Dark)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

/// Global refresh notifier to trigger UI updates across screens
final ValueNotifier<int> homeRefreshNotifier = ValueNotifier(0);

/// Custom notification to handle tab switching from child screens
class TabSwitchNotification extends Notification {
  final int index;
  TabSwitchNotification(this.index);
}
