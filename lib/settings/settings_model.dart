import 'package:flutter/material.dart';

/// Session preferences; T-008 persists these with the single application save.
class SettingsModel extends ChangeNotifier {
  bool _sound = true;
  bool _haptics = true;
  bool _reduceMotion = false;
  bool get sound => _sound;
  bool get haptics => _haptics;
  bool get reduceMotion => _reduceMotion;
  void setSound(bool value) {
    if (_sound == value) return;
    _sound = value;
    notifyListeners();
  }

  void setHaptics(bool value) {
    if (_haptics == value) return;
    _haptics = value;
    notifyListeners();
  }

  void setReduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    notifyListeners();
  }
}

class SettingsScope extends InheritedNotifier<SettingsModel> {
  const SettingsScope({
    required SettingsModel settings,
    required super.child,
    super.key,
  }) : super(notifier: settings);
  static SettingsModel? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()?.notifier;
  static bool reducedMotionOf(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      (maybeOf(context)?.reduceMotion ?? false);
}
