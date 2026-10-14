import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../game/presentation/game_screen.dart';
import '../settings/settings_model.dart';
import '../core/feedback/feedback_service.dart';
import 'candy_backdrop.dart';

/// Candy Home leading directly into a real engine-backed run.
class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.theme, super.key});

  final AppTheme theme;

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
                  Semantics(
                    label: 'Kolorowy cukierkowy kwiat',
                    image: true,
                    child: SizedBox.square(
                      dimension: 180,
                      child: CustomPaint(painter: _CandyBloomPainter(theme)),
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
                    onPressed: () => _showSettings(context),
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
  void _showSettings(BuildContext context) {
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Ustawienia obowiązują do zamknięcia aplikacji.',
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
}

/// Original glossy candy bloom, the visual signature of the Home screen.
class _CandyBloomPainter extends CustomPainter {
  _CandyBloomPainter(this.theme);

  final AppTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final colors = ['candyPink', 'electricPurple', 'turquoise', 'candyLime'];
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final petal = center + Offset(math.cos(angle), math.sin(angle)) * 48;
      final rect = Rect.fromCenter(center: petal, width: 56, height: 56);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.shift(const Offset(0, 5)),
          const Radius.circular(18),
        ),
        Paint()..color = theme.color('ink').withValues(alpha: 0.12),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(18)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.color('creamWhite'), theme.color(colors[i % 4])],
          ).createShader(rect),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: petal + const Offset(-8, -12),
          width: 20,
          height: 8,
        ),
        Paint()..color = theme.color('creamWhite').withValues(alpha: 0.65),
      );
    }
    canvas.drawCircle(center, 27, Paint()..color = theme.color('lemonYellow'));
    canvas.drawCircle(
      center + const Offset(-9, -3),
      3,
      Paint()..color = theme.color('ink'),
    );
    canvas.drawCircle(
      center + const Offset(9, -3),
      3,
      Paint()..color = theme.color('ink'),
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: center + const Offset(0, 4),
        width: 14,
        height: 10,
      ),
      0,
      math.pi,
      false,
      Paint()
        ..color = theme.color('ink')
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CandyBloomPainter oldDelegate) =>
      oldDelegate.theme != theme;
}
