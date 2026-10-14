import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/localization/app_strings.dart';
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
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  AppStrings.of(context)
                      .text('Dźwięk i ruch', 'Sound and motion'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SwitchListTile(
                title: Text(AppStrings.of(context).text('Dźwięk', 'Sound')),
                value: settings.sound,
                onChanged: settings.setSound,
              ),
              SwitchListTile(
                title: Text(AppStrings.of(context).text('Haptyka', 'Haptics')),
                value: settings.haptics,
                onChanged: settings.setHaptics,
              ),
              SwitchListTile(
                title: Text(
                  AppStrings.of(context)
                      .text('Ograniczony ruch', 'Reduced motion'),
                ),
                subtitle: Text(
                  AppStrings.of(context).text(
                    'Mniej animacji i bez drobinek.',
                    'Fewer animations and no particles.',
                  ),
                ),
                value: settings.reduceMotion,
                onChanged: settings.setReduceMotion,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  settings.persisted
                      ? AppStrings.of(context).text(
                          'Ustawienia są zapisywane na tym urządzeniu.',
                          'Preferences are saved on this device.',
                        )
                      : AppStrings.of(context).text(
                          'Ustawienia obowiązują do zamknięcia aplikacji.',
                          'Preferences last until the app closes.',
                        ),
                  textAlign: TextAlign.center,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppStrings.of(context).text('Gotowe', 'Done')),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    ),
  );
}
