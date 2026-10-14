import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'settings_model.dart';

/// Shared, functional controls for Home and the active run.
void showFeedbackSettings(BuildContext context, {required AppTheme theme}) {
  final settings = SettingsScope.maybeOf(context);
  if (settings == null) return;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.color('creamWhite'),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: ListenableBuilder(
          listenable: settings,
          builder: (_, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Dźwięk i ruch',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
              SwitchListTile(
                title: const Text('Dźwięk'),
                value: settings.sound,
                onChanged: settings.setSound,
              ),
              SwitchListTile(
                title: const Text('Haptyka'),
                value: settings.haptics,
                onChanged: settings.setHaptics,
              ),
              SwitchListTile(
                title: const Text('Ograniczony ruch'),
                subtitle: const Text('Mniej animacji i bez drobinek.'),
                value: settings.reduceMotion,
                onChanged: settings.setReduceMotion,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  settings.persisted
                      ? 'Ustawienia są zapisywane na tym urządzeniu.'
                      : 'Ustawienia obowiązują do zamknięcia aplikacji.',
                  textAlign: TextAlign.center,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Gotowe'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    ),
  );
}
