import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/localization/app_strings.dart';
import '../core/presentation/candy_controls.dart';
import '../core/presentation/candy_message.dart';
import '../core/theme/app_theme.dart';
import '../game/presentation/game_screen.dart';
import '../settings/settings_sheet.dart';
import '../settings/settings_screen.dart';
import '../island/presentation/persistent_island_screen.dart';
import '../core/feedback/feedback_service.dart';
import '../island/domain/island_state.dart';
import '../save/application/app_session.dart';
import '../island/presentation/island_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.theme, this.island, this.session, super.key});
  final AppTheme theme;
  final IslandState? island;
  final AppSession? session;

  Future<void> _play(BuildContext context) async {
    FeedbackScope.maybeOf(context)?.play(CandyCue.place);
    try {
      final controller = await session?.openRun();
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GameScreen(theme: theme, controller: controller),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        showCandyMessage(
          context,
          AppStrings.of(context)
              .translate(session?.error ?? 'Błąd zapisu. Spróbuj ponownie.'),
          error: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = math.min(
              math.min(constraints.maxWidth, constraints.maxHeight * 9 / 16),
              560.0,
            );
            final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
            final height = math.max(constraints.maxHeight, width * 16 / 9);
            return Center(
              child: SizedBox(
                width: width,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: height,
                          child: const CandyArt('menu-scene', fit: BoxFit.fill),
                        ),
                        Column(
                          children: [
                            Semantics(
                              label: 'Candyverse: Block & Bloom',
                              image: true,
                              child: SizedBox(height: height * .18),
                            ),
                            SizedBox(
                              height: height * .12,
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * .27,
                                  ),
                                  child: Text(
                                    'Przyszła\nreklama',
                                    textScaler: TextScaler.noScaling,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'LilitaOne',
                                      color: const Color(0xff913493),
                                      fontSize: width * .065,
                                      height: 1.05,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: height * .25),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * .11,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: CandyMetric(
                                      label: strings.text(
                                        'Rekord',
                                        'Best Score',
                                      ),
                                      value: '${session?.save.bestScore ?? 0}',
                                      trophy: true,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: CandyMetric(
                                      label: 'Candy Coins',
                                      value: '${session?.save.wallet ?? 0}',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: height * .018),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * .10,
                              ),
                              child: CandyAction(
                                key: const Key('home-play'),
                                label: session?.busy == true
                                    ? strings.text('Zapisuję…', 'Saving…')
                                    : strings.text('GRAJ', 'PLAY'),
                                icon: Icons.play_arrow_rounded,
                                fontSize: width * .135,
                                height: height * .115,
                                onPressed:
                                    session?.busy == true ||
                                        session?.resetNeedsRetry == true
                                    ? null
                                    : () => _play(context),
                              ),
                            ),
                            SizedBox(height: height * .012),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * .10,
                              ),
                              child: CandyAction(
                                key: const Key('home-island'),
                                label: strings.text('WYSPA', 'ISLAND'),
                                tone: CandyButtonTone.aqua,
                                icon: Icons.landscape_rounded,
                                fontSize: width * .11,
                                height: height * .10,
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => session == null
                                        ? IslandScreen(
                                            theme: theme,
                                            island: island ?? IslandState(),
                                          )
                                        : PersistentIslandScreen(
                                            theme: theme,
                                            session: session!,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                24,
                                height * .015,
                                24,
                                20,
                              ),
                              child: Text(
                                strings.text(
                                  'Twoja mała kraina szczęścia',
                                  'Your little kingdom of joy',
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'LilitaOne',
                                  fontSize: 17,
                                  color: candyInk,
                                ),
                              ),
                            ),
                            if (session?.error != null)
                              CandyPanel(
                                child: Text(strings.translate(session!.error!)),
                              ),
                            if (scale > 1.3) const SizedBox(height: 16),
                          ],
                        ),
                        Positioned(
                          right: 12,
                          top: 10,
                          child: CandyIconButton(
                            key: const Key('home-settings'),
                            label: strings.text('Ustawienia', 'Settings'),
                            symbol: CandySymbol.settings,
                            onPressed: () {
                              if (session == null) {
                                showFeedbackSettings(context, theme: theme);
                                return;
                              }
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => SettingsScreen(
                                    theme: theme,
                                    session: session!,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
