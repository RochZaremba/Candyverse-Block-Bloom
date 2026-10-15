import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/localization/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../home/candy_backdrop.dart';
import '../save/application/app_session.dart';

/// Full local preferences and explicit data controls, without external services.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.theme, required this.session, super.key});
  final AppTheme theme;
  final AppSession session;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    String t(String pl, String en) => strings.text(pl, en);
    return Scaffold(
      appBar: AppBar(title: Text(t('Ustawienia', 'Settings'))),
      body: CandyBackdrop(
        theme: theme,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([session, session.settings]),
            builder: (context, _) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _panel([
                  SwitchListTile(
                    title: Text(t('Dźwięk', 'Sound')),
                    value: session.settings.sound,
                    onChanged: session.busy ? null : session.settings.setSound,
                  ),
                  SwitchListTile(
                    title: Text(t('Haptyka', 'Haptics')),
                    subtitle: Text(
                      t('Delikatne wibracje.', 'Gentle vibrations.'),
                    ),
                    value: session.settings.haptics,
                    onChanged: session.busy
                        ? null
                        : session.settings.setHaptics,
                  ),
                  SwitchListTile(
                    title: Text(t('Ograniczony ruch', 'Reduced motion')),
                    subtitle: Text(
                      t(
                        'Mniej animacji i bez drobinek.',
                        'Fewer animations and no particles.',
                      ),
                    ),
                    value: session.settings.reduceMotion,
                    onChanged: session.busy
                        ? null
                        : session.settings.setReduceMotion,
                  ),
                ]),
                const SizedBox(height: 16),
                _panel([
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      t('Język', 'Language'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  RadioGroup<String>(
                    groupValue: session.settings.language,
                    onChanged: (value) {
                      if (!session.busy && value != null) {
                        session.settings.setLanguage(value);
                      }
                    },
                    child: Column(
                      children: [
                        for (final language in const {
                          'pl': 'Polski',
                          'en': 'English',
                        }.entries)
                          RadioListTile<String>(
                            title: Text(language.value),
                            value: language.key,
                            enabled: !session.busy,
                          ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                _panel([
                  ListTile(
                    minVerticalPadding: 16,
                    title: Text(t('Prywatność', 'Privacy')),
                    subtitle: Text(
                      t(
                        'Lokalny postęp i ustawienia.',
                        'Local progress and preferences.',
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _privacy(context),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      t(
                        'Postęp i ustawienia są zapisane lokalnie. Odinstalowanie może usunąć zapis. Wydawca nie prowadzi zapisu w chmurze. Aplikacja wyłącza standardowy backup i transfer danych Androida. Uprzywilejowane narzędzia systemowe mogą działać inaczej.',
                        'Progress and preferences are saved locally. Uninstalling may remove your save. The publisher has no cloud save. The app disables standard Android backup and data transfer. Privileged system tools may behave differently.',
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                if (session.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      session.resetNeedsRetry
                          ? t(
                              'Nie można potwierdzić usunięcia danych. Ponów reset przed kontynuowaniem.',
                              'Could not confirm data deletion. Retry reset before continuing.',
                            )
                          : t(
                              'Zapis nie powiódł się. Możesz spróbować ponownie.',
                              'Saving failed. You can try again.',
                            ),
                      semanticsLabel: t('Błąd zapisu', 'Save error'),
                    ),
                  ),
                if (session.error != null && !session.resetNeedsRetry)
                  TextButton(
                    onPressed: session.busy ? null : session.retrySettingsSave,
                    child: Text(
                      t('Ponów zapis ustawień', 'Retry saving preferences'),
                    ),
                  ),
                if (session.busy)
                  const Center(child: CircularProgressIndicator()),
                OutlinedButton(
                  key: const Key('reset-data'),
                  onPressed: session.busy ? null : () => _reset(context),
                  child: Text(t('Usuń lokalne dane', 'Delete local data')),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _panel(List<Widget> children) => Material(
    color: theme.color('creamWhite'),
    elevation: 3,
    shadowColor: theme.color('ink').withValues(alpha: .15),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(theme.cardRadius),
      side: BorderSide(color: theme.color('candyPink').withValues(alpha: .25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );

  Future<void> _privacy(BuildContext context) async {
    final strings = AppStrings.of(context);
    final policy = await rootBundle.loadString(
      strings.text(
        'assets/privacy/policy_pl.txt',
        'assets/privacy/policy_en.txt',
      ),
    );
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.text('Prywatność', 'Privacy')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(policy),
              const SizedBox(height: 16),
              Text(strings.text('Publiczna polityka:', 'Public policy:')),
              const SelectableText(
                'https://rochzaremba.github.io/Candyverse-Block-Bloom/',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.text('Gotowe', 'Done')),
          ),
        ],
      ),
    );
  }

  Future<void> _reset(BuildContext context) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.text('Usunąć lokalne dane?', 'Delete local data?')),
        content: SingleChildScrollView(
          child: Text(
            strings.text(
              'Usuniesz monety, wyspę, rekord, bieżącą grę i ustawienia. Nie można tego cofnąć. Nie ma kopii u wydawcy.',
              'This deletes coins, your island, best score, current game and preferences. This cannot be undone. The publisher has no backup.',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.text('Anuluj', 'Cancel')),
          ),
          FilledButton(
            key: const Key('confirm-reset'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.text('Usuń dane', 'Delete data')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await session.resetData();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.text(
                'Nie udało się usunąć danych. Spróbuj ponownie.',
                'Could not delete data. Try again.',
              ),
            ),
          ),
        );
      }
    }
  }
}
