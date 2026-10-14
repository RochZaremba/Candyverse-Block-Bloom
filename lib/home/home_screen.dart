import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../game/presentation/game_screen.dart';
import '../settings/settings_sheet.dart';
import '../core/feedback/feedback_service.dart';
import 'candy_backdrop.dart';
import '../island/domain/island_state.dart';
import '../island/presentation/island_scene.dart';
import '../island/presentation/island_screen.dart';

/// Candy Home leading directly into a real engine-backed run.
class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.theme, this.island, super.key});

  final AppTheme theme;
  final IslandState? island;
  IslandState get currentIsland => island ?? IslandState();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: CandyBackdrop(
      theme: theme,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 230,
                    child: IslandScene(
                      theme: theme,
                      island: currentIsland,
                      characterCount: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Candyverse',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: theme.color('ink'),
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'BLOCK & BLOOM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      color: theme.color('ink'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ułóż. Połącz. Rozkwitaj.',
                    style: TextStyle(fontSize: 16, color: theme.color('ink')),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.color('ink'),
                      foregroundColor: theme.color('creamWhite'),
                      minimumSize: const Size(220, 64),
                      textStyle: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    onPressed: () {
                      FeedbackScope.maybeOf(context)?.play(CandyCue.place);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => GameScreen(theme: theme),
                        ),
                      );
                    },
                    child: const Text('GRAJ'),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            IslandScreen(theme: theme, island: currentIsland),
                      ),
                    ),
                    icon: const Icon(Icons.landscape_rounded),
                    label: const Text('Odwiedź wyspę'),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        showFeedbackSettings(context, theme: theme),
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Dźwięk i ruch'),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.color('creamWhite'),
                      borderRadius: BorderRadius.circular(theme.panelRadius),
                    ),
                    child: Text(
                      'Małe klocki, wielkie możliwości.\n'
                      'Twój cukierkowy świat rozkwita bez pośpiechu.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
