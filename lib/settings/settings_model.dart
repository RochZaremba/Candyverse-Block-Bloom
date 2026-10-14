import 'package:flutter/material.dart';

import '../save/domain/app_save.dart';

/// Observable preferences restored and persisted by the application session.
class SettingsModel extends ChangeNotifier {
  SettingsModel({SavedSettings initial = const SavedSettings()})
    : _sound = initial.sound,
      _haptics = initial.haptics,
      _reduceMotion = initial.reduceMotion,
      language = initial.language;
  final String language;
  bool persisted = false;
  SavedSettings get snapshot => SavedSettings(
    sound: sound,
    haptics: haptics,
    reduceMotion: reduceMotion,
    language: language,
  );
  bool _sound;
  bool _haptics;
  bool _reduceMotion;
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
