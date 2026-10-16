import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/presentation/candy_controls.dart';
import '../core/localization/app_strings.dart';
import 'settings_model.dart';

/// Shared, functional controls for Home and the active run.
void showFeedbackSettings(BuildContext context, {required AppTheme theme}) {
  final settings = SettingsScope.maybeOf(context);
  if (settings == null) return;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: CandyPanel(
          child: ListenableBuilder(
            listenable: settings,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const CandyFriends(height: 90),
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
                  title: Text(
                    AppStrings.of(context).text('Haptyka', 'Haptics'),
                  ),
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
                CandyAction(
                  onPressed: () => Navigator.pop(context),
                  label: AppStrings.of(context).text('Gotowe', 'Done'),
                  fontSize: 22,
                  height: 58,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
