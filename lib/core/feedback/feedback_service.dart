import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../settings/settings_model.dart';

enum CandyCue { place, clear, upgrade, fanfare }

/// Offline Android SoundPool bridge. Missing audio never interrupts a move.
class FeedbackService with WidgetsBindingObserver {
  FeedbackService(this.settings, {MethodChannel? channel})
    : channel = channel ?? const MethodChannel('candyverse/feedback') {
    WidgetsBinding.instance.addObserver(this);
    _lastSound = settings.sound;
    settings.addListener(_settingsChanged);
  }
  final SettingsModel settings;
  final MethodChannel channel;
  bool _active = true;
  bool _disposed = false;
  bool _lastSound = true;
  Future<void> _send(String method, [Object? args]) async {
    try {
      await channel.invokeMethod<void>(method, args);
    } on MissingPluginException {
      /* Widget tests / non-Android preview. */
    } on PlatformException {
      /* Optional feedback must not block gameplay. */
    }
  }

  Future<void> play(CandyCue cue) async {
    if (!_active || _disposed) return;
    final tasks = <Future<void>>[];
    if (settings.sound) tasks.add(_send('play', cue.name));
    if (settings.haptics) tasks.add(HapticFeedback.lightImpact());
    await Future.wait(tasks);
  }

  void _settingsChanged() {
    if (_lastSound && !settings.sound) unawaited(_send('stop'));
    _lastSound = settings.sound;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (!_active) unawaited(_send('stop'));
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    settings.removeListener(_settingsChanged);
    unawaited(_send('stop'));
  }
}

class FeedbackScope extends InheritedWidget {
  const FeedbackScope({required this.service, required super.child, super.key});
  final FeedbackService service;
  static FeedbackService? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FeedbackScope>()?.service;
  @override
  bool updateShouldNotify(FeedbackScope oldWidget) =>
      service != oldWidget.service;
}
