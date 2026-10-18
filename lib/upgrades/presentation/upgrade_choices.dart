import '../domain/evolution.dart';
import '../../core/localization/app_strings.dart';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/presentation/candy_controls.dart';
import '../domain/upgrade.dart';

class UpgradeChoices extends StatelessWidget {
  const UpgradeChoices({
    this.evolution,
    required this.theme,
    required this.choices,
    required this.onChoose,
    required this.pending,
    super.key,
  });
  final Evolution? evolution;
  final AppTheme theme;
  final List<Upgrade> choices;
  final ValueChanged<Upgrade> onChoose;
  final int pending;

  List<String> _unlockedBy(Upgrade u) {
    final e = evolution!;
    final next = e.advancePath(u.path);
    return next.synergies.where((name) => !e.synergies.contains(name)).toList();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: theme.color('ink').withValues(alpha: .75),
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CandyFriends(height: 86),
            Semantics(
              liveRegion: true,
              child: appText(
                context,
                'Wybierz ulepszenie',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.color('creamWhite'),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (pending > 1)
              appText(
                context,
                'Pozostałe wybory: $pending',
                style: TextStyle(color: theme.color('creamWhite')),
              ),
            const SizedBox(height: 12),
            for (final upgrade in choices)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: theme.color(switch (upgrade) {
                    Upgrade.sugarRush => 'bubblegumPink',
                    Upgrade.luckyJelly => 'lemonYellow',
                    Upgrade.rainbowEraser => 'turquoise',
                    _ => [
                      'bubblegumPink',
                      'turquoise',
                      'lemonYellow',
                    ][upgrade.path],
                  }),
                  borderRadius: BorderRadius.circular(24),
                  elevation: 5,
                  shadowColor: theme.color('ink').withValues(alpha: .3),
                  clipBehavior: Clip.antiAlias,
                  child: CandyPanel(
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      key: ValueKey('upgrade-${upgrade.name}'),
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => onChoose(upgrade),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ExcludeSemantics(
                              child: CustomPaint(
                                size: const Size(44, 48),
                                painter: _UpgradeEmblem(theme, upgrade),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  appText(
                                    context,
                                    upgrade.title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  if (upgrade.isEvolution)
                                    Text(
                                      '${['Explosive Candy', 'Rainbow Magic', 'Lucky Paws'][upgrade.path]} • ${upgrade.rank}/4',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  appText(context, upgrade.description),
                                  if (evolution != null && upgrade.isEvolution)
                                    for (final name in _unlockedBy(upgrade))
                                      Text(
                                        '${AppStrings.of(context).text('Odblokujesz', 'Unlock')}: $name',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Original candy emblems; presentation never substitutes emoji for art.
class _UpgradeEmblem extends CustomPainter {
  const _UpgradeEmblem(this.theme, this.upgrade);
  final AppTheme theme;
  final Upgrade upgrade;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = theme.color('ink');
    final cream = theme.color('creamWhite');
    final rect = Rect.fromLTWH(3, 9, size.width - 6, 32);
    final shape = switch (upgrade) {
      Upgrade.sugarRush => 'candyPink',
      Upgrade.luckyJelly => 'mangoOrange',
      Upgrade.rainbowEraser => 'electricPurple',
      _ => ['candyPink', 'electricPurple', 'mangoOrange'][upgrade.path],
    };
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [cream, theme.color(shape)],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.shift(const Offset(0, 3)),
        const Radius.circular(13),
      ),
      Paint()..color = ink.withValues(alpha: .14),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(13)),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(10, 12, 18, 6),
      Paint()..color = cream.withValues(alpha: .75),
    );
    if (upgrade.isEvolution && upgrade.path == 0) {
      canvas.drawCircle(
        const Offset(22, 30),
        9,
        Paint()..color = theme.color('electricPurple'),
      );
      canvas.drawCircle(
        const Offset(19, 27),
        3,
        Paint()..color = cream.withValues(alpha: .7),
      );
      canvas.drawPath(
        Path()
          ..moveTo(24, 22)
          ..quadraticBezierTo(26, 16, 31, 19),
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawCircle(
        const Offset(32, 18),
        3,
        Paint()..color = theme.color('lemonYellow'),
      );
    } else if (upgrade.isEvolution && upgrade.path == 2) {
      canvas.drawOval(
        const Rect.fromLTWH(15, 28, 15, 11),
        Paint()..color = ink,
      );
      for (final toe in [
        const Offset(12, 26),
        const Offset(18, 21),
        const Offset(25, 21),
        const Offset(32, 26),
      ]) {
        canvas.drawOval(
          Rect.fromCenter(center: toe, width: 6, height: 8),
          Paint()..color = ink,
        );
      }
    } else if (upgrade == Upgrade.sugarRush) {
      final bolt = Path()
        ..moveTo(25, 19)
        ..lineTo(17, 29)
        ..lineTo(23, 29)
        ..lineTo(19, 38)
        ..lineTo(31, 25)
        ..lineTo(24, 25)
        ..close();
      canvas.drawPath(bolt, Paint()..color = ink);
    } else if (upgrade == Upgrade.luckyJelly) {
      canvas.drawCircle(
        const Offset(22, 28),
        9,
        Paint()..color = theme.color('lemonYellow'),
      );
      canvas.drawCircle(
        const Offset(22, 28),
        7,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawLine(
        const Offset(22, 24),
        const Offset(22, 32),
        Paint()
          ..color = ink
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    } else {
      for (var i = 0; i < 3; i++) {
        canvas.drawLine(
          Offset(13, 24 + i * 5),
          Offset(31, 24 + i * 5),
          Paint()
            ..color = theme.color(['candyPink', 'lemonYellow', 'turquoise'][i])
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_UpgradeEmblem oldDelegate) =>
      oldDelegate.theme != theme || oldDelegate.upgrade != upgrade;
}
