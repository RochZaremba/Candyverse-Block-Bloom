import '../../core/localization/app_strings.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/feedback/feedback_service.dart';
import '../../core/theme/app_theme.dart';
import '../../settings/settings_model.dart';
import '../domain/island_state.dart';

String characterName(CandyCharacter kind) => switch (kind) {
  CandyCharacter.pinkMochi => 'Pink Mochi',
  CandyCharacter.blueJelly => 'Blue Jelly',
  CandyCharacter.lemonBlob => 'Lemon Blob',
  CandyCharacter.mintyMonster => 'Minty Monster',
};
String buildingName(BuildingKind kind) => switch (kind) {
  BuildingKind.candyTree => 'Cukierkowe drzewo',
  BuildingKind.jellyHouse => 'Galaretkowy domek',
  BuildingKind.rainbowFountain => 'Tęczowa fontanna',
};

/// Original candy diorama. Static scenery repaints independently from sprites.
class IslandScene extends StatefulWidget {
  const IslandScene({
    required this.theme,
    required this.island,
    this.onBuildingTap,
    this.characterCount = 4,
    super.key,
  });
  final AppTheme theme;
  final IslandState island;
  final ValueChanged<BuildingKind>? onBuildingTap;
  final int characterCount;
  @override
  State<IslandScene> createState() => _IslandSceneState();
}

class _IslandSceneState extends State<IslandScene>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  bool foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _sync() {
    final animate =
        foreground &&
        TickerMode.valuesOf(context).enabled &&
        !SettingsScope.reducedMotionOf(context);
    if (animate && !idle.isAnimating) {
      idle.repeat();
    }
    if (!animate) {
      idle.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 400 / 350,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / 400;
        const buildings = [
          Offset(100, 157),
          Offset(285, 155),
          Offset(204, 229),
        ];
        const characters = [
          Offset(84, 248),
          Offset(310, 250),
          Offset(157, 301),
          Offset(255, 302),
        ];
        return Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _IslandPainter(widget.theme, widget.island),
                ),
              ),
            ),
            for (var i = 0; i < 3; i++)
              Positioned(
                left: buildings[i].dx * scale - math.max(48.0, 88 * scale) / 2,
                top: buildings[i].dy * scale - math.max(48.0, 90 * scale) / 2,
                width: math.max(48.0, 88 * scale),
                height: math.max(48.0, 90 * scale),
                child: Semantics(
                  label: AppStrings.of(context).translate(
                    '${buildingName(BuildingKind.values[i])}, poziom ${widget.island.level(BuildingKind.values[i])}',
                  ),
                  button: widget.onBuildingTap != null,
                  child: GestureDetector(
                    key: ValueKey('building-${BuildingKind.values[i].name}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onBuildingTap == null
                        ? null
                        : () => widget.onBuildingTap!(BuildingKind.values[i]),
                  ),
                ),
              ),
            for (var i = 0; i < widget.characterCount.clamp(0, 4); i++)
              Positioned(
                left: characters[i].dx * scale - math.max(48.0, 70 * scale) / 2,
                top: characters[i].dy * scale - math.max(48.0, 62 * scale) / 2,
                width: math.max(48.0, 70 * scale),
                height: math.max(48.0, 62 * scale),
                child: AnimatedBuilder(
                  animation: idle,
                  builder: (_, _) => _CharacterSprite(
                    theme: widget.theme,
                    kind: CandyCharacter.values[i],
                    idle: foreground && !SettingsScope.reducedMotionOf(context)
                        ? idle.value + i * .17
                        : 0,
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _CharacterSprite extends StatefulWidget {
  const _CharacterSprite({
    required this.theme,
    required this.kind,
    required this.idle,
  });
  final AppTheme theme;
  final CandyCharacter kind;
  final double idle;
  @override
  State<_CharacterSprite> createState() => _CharacterSpriteState();
}

class _CharacterSpriteState extends State<_CharacterSprite>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final reaction = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  bool greeting = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    reaction.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => greeting = false);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (SettingsScope.reducedMotionOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      reaction.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) reaction.stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    reaction.dispose();
    super.dispose();
  }

  void _tap() {
    setState(() => greeting = true);
    FeedbackScope.maybeOf(context)?.play(CandyCue.place);
    if (!SettingsScope.reducedMotionOf(context)) reaction.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppStrings.of(
      context,
    ).translate('${characterName(widget.kind)}${greeting ? ' wita Cię' : ''}'),
    button: true,
    child: GestureDetector(
      key: ValueKey('character-${widget.kind.name}'),
      onTap: _tap,
      behavior: HitTestBehavior.opaque,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: reaction,
          builder: (_, _) => CustomPaint(
            painter: _CharacterPainter(
              widget.theme,
              widget.kind,
              widget.idle,
              SettingsScope.reducedMotionOf(context) ? 0 : reaction.value,
              greeting,
            ),
          ),
        ),
      ),
    ),
  );
}

class _CharacterPainter extends CustomPainter {
  _CharacterPainter(
    this.theme,
    this.kind,
    this.idle,
    this.reaction,
    this.greeting,
  );
  final AppTheme theme;
  final CandyCharacter kind;
  final double idle, reaction;
  final bool greeting;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 70, size.height / 62);
    final ink = theme.color('ink');
    canvas.drawOval(
      const Rect.fromLTWH(14, 48, 42, 9),
      Paint()..color = ink.withValues(alpha: .12),
    );
    final bounce = math.sin(reaction * math.pi) * 9;
    final breathe = math.sin(idle * math.pi * 2) * 1.2;
    canvas.translate(0, -bounce + breathe);
    final rect = const Rect.fromLTWH(10, 11, 50, 40);
    final color = theme.color(switch (kind) {
      CandyCharacter.pinkMochi => 'candyPink',
      CandyCharacter.blueJelly => 'blueberry',
      CandyCharacter.lemonBlob => 'lemonYellow',
      CandyCharacter.mintyMonster => 'turquoise',
    });
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(color, theme.color('creamWhite'), .4)!, color],
      ).createShader(rect);
    switch (kind) {
      case CandyCharacter.pinkMochi:
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(20)),
          paint,
        );
        canvas.drawOval(const Rect.fromLTWH(3, 30, 18, 20), paint);
        canvas.drawOval(const Rect.fromLTWH(49, 30, 18, 20), paint);
      case CandyCharacter.blueJelly:
        final body = Path()
          ..moveTo(10, 45)
          ..cubicTo(8, 1, 60, 1, 60, 45)
          ..quadraticBezierTo(54, 54, 48, 47)
          ..quadraticBezierTo(41, 57, 35, 48)
          ..quadraticBezierTo(27, 57, 21, 48)
          ..quadraticBezierTo(13, 56, 10, 45)
          ..close();
        canvas.drawPath(body, paint);
      case CandyCharacter.lemonBlob:
        final body = Path()
          ..moveTo(35, 9)
          ..cubicTo(45, 13, 64, 39, 58, 47)
          ..cubicTo(52, 57, 16, 57, 11, 45)
          ..cubicTo(7, 35, 23, 15, 35, 9)
          ..close();
        canvas.drawPath(body, paint);
        canvas.drawOval(
          const Rect.fromLTWH(35, 2, 17, 8),
          Paint()..color = theme.color('candyLime'),
        );
      case CandyCharacter.mintyMonster:
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(15)),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(13, 17)
            ..lineTo(12, 1)
            ..lineTo(26, 13)
            ..close(),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(45, 14)
            ..lineTo(58, 1)
            ..lineTo(58, 21)
            ..close(),
          paint,
        );
        canvas.drawCircle(const Offset(14, 47), 8, paint);
        canvas.drawCircle(const Offset(56, 47), 8, paint);
    }
    canvas.drawOval(
      const Rect.fromLTWH(18, 16, 19, 7),
      Paint()..color = theme.color('creamWhite').withValues(alpha: .7),
    );
    final blink = idle != 0 && (idle % 1) > .91;
    for (final x in [26.0, 44.0]) {
      if (blink || (greeting && reaction > .2 && reaction < .7)) {
        canvas.drawArc(
          Rect.fromCenter(center: Offset(x, 30), width: 7, height: 6),
          math.pi,
          math.pi,
          false,
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, 30), width: 4, height: 6),
          Paint()..color = ink,
        );
      }
    }
    canvas.drawArc(
      const Rect.fromLTWH(29, 33, 12, 8),
      0,
      math.pi,
      false,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    if (kind == CandyCharacter.mintyMonster) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(33, 37, 4, 4),
          const Radius.circular(1),
        ),
        Paint()..color = theme.color('creamWhite'),
      );
    }
    if (greeting && reaction == 0) {
      canvas.drawCircle(
        const Offset(57, 12),
        3,
        Paint()..color = theme.color('lemonYellow'),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CharacterPainter old) =>
      idle != old.idle ||
      reaction != old.reaction ||
      greeting != old.greeting ||
      kind != old.kind ||
      theme != old.theme;
}

class _IslandPainter extends CustomPainter {
  _IslandPainter(this.theme, this.island);
  final AppTheme theme;
  final IslandState island;
  Color c(String name) => theme.color(name);
  void _round(Canvas canvas, Rect rect, double radius, List<Color> colors) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.shift(const Offset(0, 3)),
        Radius.circular(radius),
      ),
      Paint()..color = c('ink').withValues(alpha: .12),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(rect),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 400, size.height / 350);
    canvas.drawOval(
      const Rect.fromLTWH(43, 285, 315, 30),
      Paint()..color = c('ink').withValues(alpha: .10),
    );
    _round(canvas, const Rect.fromLTWH(29, 112, 342, 188), 85, [
      c('bubblegumPink'),
      c('electricPurple'),
    ]);
    canvas.drawOval(
      const Rect.fromLTWH(29, 94, 342, 180),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c('creamWhite'), c('candyLime')],
        ).createShader(const Rect.fromLTWH(29, 94, 342, 180)),
    );
    canvas.drawOval(
      const Rect.fromLTWH(74, 207, 267, 71),
      Paint()..color = c('creamWhite').withValues(alpha: .60),
    );
    for (var i = 0; i < 12; i++) {
      final x = 45 + i * 28.0, y = 185 + math.sin(i * .9) * 60;
      canvas.drawOval(
        Rect.fromLTWH(x, y, 8, 4),
        Paint()
          ..color = c(i.isEven ? 'candyPink' : 'turquoise')
              .withValues(alpha: .45),
      );
    }
    _building(canvas, BuildingKind.candyTree, const Offset(100, 157));
    _building(canvas, BuildingKind.jellyHouse, const Offset(285, 155));
    _building(canvas, BuildingKind.rainbowFountain, const Offset(204, 229));
    canvas.restore();
  }

  void _building(Canvas canvas, BuildingKind kind, Offset center) {
    final level = island.level(kind);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (level == 0) {
      canvas.drawOval(
        const Rect.fromLTWH(-34, 4, 68, 23),
        Paint()..color = c('mangoOrange').withValues(alpha: .35),
      );
      canvas.drawOval(
        const Rect.fromLTWH(-30, 6, 60, 15),
        Paint()..color = c('creamWhite').withValues(alpha: .75),
      );
      canvas.drawLine(
        const Offset(0, -7),
        const Offset(0, 18),
        Paint()
          ..color = c('ink').withValues(alpha: .3)
          ..strokeWidth = 3,
      );
      _round(canvas, const Rect.fromLTWH(-17, -19, 34, 20), 6, [
        c('creamWhite'),
        c('lemonYellow'),
      ]);
      final paint = Paint()
        ..color = c('ink').withValues(alpha: .6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      if (kind == BuildingKind.candyTree) {
        canvas.drawLine(const Offset(0, -6), const Offset(0, -14), paint);
        canvas.drawLine(const Offset(0, -9), const Offset(5, -13), paint);
      }
      if (kind == BuildingKind.jellyHouse) {
        canvas.drawPath(
          Path()
            ..moveTo(-6, -6)
            ..lineTo(-6, -12)
            ..lineTo(0, -16)
            ..lineTo(6, -12)
            ..lineTo(6, -6)
            ..close(),
          paint,
        );
      }
      if (kind == BuildingKind.rainbowFountain) {
        canvas.drawArc(
          const Rect.fromLTWH(-8, -15, 16, 16),
          math.pi,
          math.pi,
          false,
          paint,
        );
      }
      canvas.restore();
      return;
    }
    switch (kind) {
      case BuildingKind.candyTree:
        final canopyWidth = 58 + level * 12.0;
        _round(canvas, Rect.fromLTWH(-7, -37, 14, 62), 6, [
          c('creamWhite'),
          c('mangoOrange'),
        ]);
        if (level > 1) {
          canvas.drawLine(
            const Offset(0, -18),
            const Offset(-24, -40),
            Paint()
              ..color = c('mangoOrange')
              ..strokeWidth = 8
              ..strokeCap = StrokeCap.round,
          );
        }
        final canopy = Rect.fromCenter(
          center: const Offset(0, -44),
          width: canopyWidth,
          height: 50 + level * 5.0,
        );
        _round(canvas, canopy, 28, [c('bubblegumPink'), c('candyPink')]);
        canvas.drawCircle(
          const Offset(-24, -47),
          22 + level * 2.0,
          Paint()..color = c('bubblegumPink'),
        );
        canvas.drawCircle(
          const Offset(22, -59),
          19 + level * 3.0,
          Paint()..color = c(level == 3 ? 'turquoise' : 'electricPurple'),
        );
        canvas.drawOval(
          const Rect.fromLTWH(-23, -63, 28, 8),
          Paint()..color = c('creamWhite').withValues(alpha: .65),
        );
        for (var i = 0; i < level * 2; i++) {
          canvas.drawCircle(
            Offset(-28 + i * 11, -40 + (i % 2) * 9),
            4,
            Paint()..color = c(i.isEven ? 'lemonYellow' : 'candyLime'),
          );
        }
        if (level == 3) {
          canvas.drawCircle(
            const Offset(-40, -17),
            11,
            Paint()..color = c('turquoise'),
          );
          canvas.drawCircle(
            const Offset(41, -30),
            13,
            Paint()..color = c('lemonYellow'),
          );
        }
      case BuildingKind.jellyHouse:
        final width = 59 + level * 9.0;
        _round(canvas, Rect.fromLTWH(-width / 2, -35, width, 60), 18, [
          c('creamWhite'),
          c('electricPurple'),
        ]);
        final roof = Path()
          ..moveTo(-width / 2 - 8, -27)
          ..quadraticBezierTo(-25, -70, 0, -67 - level * 3)
          ..quadraticBezierTo(28, -68, width / 2 + 8, -27)
          ..close();
        canvas.drawPath(
          roof,
          Paint()..color = c(level == 3 ? 'candyPink' : 'bubblegumPink'),
        );
        _round(canvas, const Rect.fromLTWH(-10, -4, 20, 29), 10, [
          c('turquoise'),
          c('blueberry'),
        ]);
        canvas.drawCircle(
          const Offset(4, 13),
          2,
          Paint()..color = c('lemonYellow'),
        );
        for (final x in [-24.0, 24.0]) {
          _round(canvas, Rect.fromLTWH(x - 7, -19, 14, 14), 5, [
            c('creamWhite'),
            c('lemonYellow'),
          ]);
        }
        if (level > 1) {
          _round(canvas, const Rect.fromLTWH(20, -65, 10, 24), 4, [
            c('creamWhite'),
            c('mangoOrange'),
          ]);
        }
        if (level == 3) {
          _round(canvas, const Rect.fromLTWH(-45, -43, 15, 67), 8, [
            c('turquoise'),
            c('electricPurple'),
          ]);
          canvas.drawCircle(
            const Offset(-38, -49),
            14,
            Paint()..color = c('lemonYellow'),
          );
        }
        canvas.drawOval(
          const Rect.fromLTWH(-18, -52, 23, 7),
          Paint()..color = c('creamWhite').withValues(alpha: .65),
        );
      case BuildingKind.rainbowFountain:
        canvas.drawOval(
          const Rect.fromLTWH(-44, 13, 88, 25),
          Paint()..color = c('blueberry').withValues(alpha: .3),
        );
        _round(canvas, const Rect.fromLTWH(-40, 3, 80, 24), 14, [
          c('creamWhite'),
          c('turquoise'),
        ]);
        canvas.drawOval(
          const Rect.fromLTWH(-33, 4, 66, 12),
          Paint()..color = c('blueberry').withValues(alpha: .5),
        );
        for (var i = 0; i < 3; i++) {
          final width = 39 + level * 13.0 - i * 5;
          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(0, 8 - level * 8.0),
              width: width,
              height: 40 + level * 17.0,
            ),
            math.pi,
            math.pi,
            false,
            Paint()
              ..color = c(['candyPink', 'lemonYellow', 'turquoise'][i])
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..strokeCap = StrokeCap.round,
          );
        }
        if (level > 1) {
          _round(canvas, Rect.fromLTWH(-20, -11, 40, 13), 7, [
            c('creamWhite'),
            c('electricPurple'),
          ]);
        }
        if (level == 3) {
          canvas.drawCircle(
            const Offset(-38, -12),
            4,
            Paint()..color = c('lemonYellow'),
          );
          canvas.drawCircle(
            const Offset(38, -12),
            4,
            Paint()..color = c('bubblegumPink'),
          );
          _round(canvas, const Rect.fromLTWH(-9, -30, 18, 10), 5, [
            c('creamWhite'),
            c('turquoise'),
          ]);
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IslandPainter old) =>
      island != old.island || theme != old.theme;
}
