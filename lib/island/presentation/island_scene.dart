import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/feedback/feedback_service.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../settings/settings_model.dart';
import '../domain/island_state.dart';
import 'kingdom_sprite.dart';

String characterName(CandyCharacter kind) => switch (kind) {
  CandyCharacter.pinkMochi => 'Maple the kitten',
  CandyCharacter.blueJelly => 'Biscuit the puppy',
  CandyCharacter.lemonBlob => 'Clover the bunny',
  CandyCharacter.mintyMonster => 'Toffee the fox',
};
String buildingName(BuildingKind kind) => switch (kind) {
  BuildingKind.candyTree => 'Cukierkowe drzewo',
  BuildingKind.jellyHouse => 'Galaretkowy domek',
  BuildingKind.rainbowFountain => 'Tęczowa fontanna',
};

/// Rendered diorama: cached scenery and buildings stay outside pet repaints.
class IslandScene extends StatefulWidget {
  const IslandScene({
    required this.theme,
    required this.island,
    this.onBuildingTap,
    this.characterCount = 4,
    this.worldIndex = 0,
    super.key,
  });
  final AppTheme theme;
  final IslandState island;
  final ValueChanged<BuildingKind>? onBuildingTap;
  final int characterCount;
  final int worldIndex;
  @override
  State<IslandScene> createState() => _IslandSceneState();
}

class _IslandSceneState extends State<IslandScene>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  late final celebration = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool foreground = true;
  bool get animate =>
      foreground &&
      TickerMode.valuesOf(context).enabled &&
      !SettingsScope.reducedMotionOf(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _sync() {
    if (animate && !idle.isAnimating) idle.repeat();
    if (!animate) {
      idle.stop();
      celebration.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(IslandScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (animate &&
        (oldWidget.worldIndex != widget.worldIndex ||
            BuildingKind.values.any(
              (kind) =>
                  widget.island.level(kind) > oldWidget.island.level(kind),
            ))) {
      celebration.forward(from: 0);
    }
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
    celebration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 400 / 350,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / 400;
        const buildings = [
          Offset(105, 150),
          Offset(288, 150),
          Offset(204, 218),
        ];
        const characters = [
          Offset(78, 249),
          Offset(320, 249),
          Offset(156, 285),
          Offset(254, 286),
        ];
        return Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: KingdomSprite(
                  key: ValueKey('world-${widget.worldIndex % 3}'),
                  asset: 'assets/kingdom/worlds.png',
                  row: widget.worldIndex % 3,
                  column: 0,
                  rows: 3,
                  columns: 1,
                ),
              ),
            ),
            for (var i = 0; i < 3; i++)
              Positioned(
                left: (buildings[i].dx - 57) * scale,
                top: (buildings[i].dy - 69) * scale,
                width: math.max(48.0, 114 * scale),
                height: math.max(48.0, 116 * scale),
                child: _BuildingSprite(
                  theme: widget.theme,
                  kind: BuildingKind.values[i],
                  level: widget.island.level(BuildingKind.values[i]),
                  onTap: widget.onBuildingTap == null
                      ? null
                      : () => widget.onBuildingTap!(BuildingKind.values[i]),
                ),
              ),
            for (var i = 0; i < widget.characterCount.clamp(0, 4); i++)
              Positioned(
                left: characters[i].dx * scale - math.max(48.0, 75 * scale) / 2,
                top: characters[i].dy * scale - math.max(48.0, 80 * scale) / 2,
                width: math.max(48.0, 75 * scale),
                height: math.max(48.0, 80 * scale),
                child: _CharacterSprite(
                  kind: CandyCharacter.values[i],
                  idle: idle,
                  phase: i * .17,
                ),
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: celebration,
                    builder: (_, _) => CustomPaint(
                      painter: _CandyFireworks(
                        widget.theme,
                        animate ? celebration.value : 0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _BuildingSprite extends StatelessWidget {
  const _BuildingSprite({
    required this.theme,
    required this.kind,
    required this.level,
    this.onTap,
  });
  final AppTheme theme;
  final BuildingKind kind;
  final int level;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    label: AppStrings.of(context)
        .translate('${buildingName(kind)}, poziom $level'),
    button: onTap != null,
    child: GestureDetector(
      key: ValueKey('building-${kind.name}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: RepaintBoundary(
        child: Column(
          children: [
            Expanded(
              child: level == 0
                  ? Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme
                              .color('creamWhite')
                              .withValues(alpha: .85),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.color('bubblegumPink'),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.color('ink').withValues(alpha: .12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: theme.color('electricPurple'),
                          size: 30,
                        ),
                      ),
                    )
                  : Transform.scale(
                      scale: .88 + ((level - 1) % 5) * .03,
                      child: KingdomSprite(
                        key: ValueKey('building-art-${kind.name}-$level'),
                        asset: 'assets/kingdom/buildings.png',
                        row: ((level - 1) ~/ 5).clamp(0, 5),
                        column: kind.index,
                        rows: 6,
                        columns: 3,
                      ),
                    ),
            ),
            if (level > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.color('creamWhite').withValues(alpha: .96),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$level / 30',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    color: theme.color('ink'),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _CharacterSprite extends StatefulWidget {
  const _CharacterSprite({
    required this.kind,
    required this.idle,
    required this.phase,
  });
  final CandyCharacter kind;
  final Animation<double> idle;
  final double phase;
  @override
  State<_CharacterSprite> createState() => _CharacterSpriteState();
}

class _CharacterSpriteState extends State<_CharacterSprite>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final reaction = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  bool greeting = false;
  bool foreground = true;
  bool get animate =>
      foreground &&
      TickerMode.valuesOf(context).enabled &&
      !SettingsScope.reducedMotionOf(context);
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
    if (!animate) reaction.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (!animate) reaction.stop();
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
    if (animate) reaction.forward(from: 0);
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
          animation: Listenable.merge([widget.idle, reaction]),
          child: KingdomSprite(
            asset: 'assets/kingdom/mascots.png',
            row: widget.kind.index ~/ 2,
            column: widget.kind.index % 2,
            rows: 2,
            columns: 2,
          ),
          builder: (_, child) {
            final bounce = animate ? math.sin(reaction.value * math.pi) : 0.0;
            final breathe = animate
                ? math.sin((widget.idle.value + widget.phase) * math.pi * 2)
                : 0.0;
            return Transform.translate(
              offset: Offset(0, breathe * 2 - bounce * 11),
              child: Transform.rotate(
                angle: bounce * .12,
                child: Transform.scale(
                  scale: 1 + bounce * .08 + breathe * .01,
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

/// Thirty-six slow, pastel particles. No full-screen flash or alternating light.
class _CandyFireworks extends CustomPainter {
  _CandyFireworks(this.theme, this.progress);
  final AppTheme theme;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    const colors = ['candyPink', 'lemonYellow', 'turquoise', 'electricPurple'];
    for (var i = 0; i < 36; i++) {
      final burst = i ~/ 12;
      final angle = i % 12 * math.pi / 6 - math.pi / 2;
      final origin = Offset(
        size.width * [.25, .73, .5][burst],
        size.height * [.32, .3, .56][burst],
      );
      final distance = (18 + i % 4 * 9) * Curves.easeOut.transform(progress);
      final center =
          origin +
          Offset(
            math.cos(angle) * distance,
            math.sin(angle) * distance + progress * progress * 25,
          );
      final paint = Paint()
        ..color = theme
            .color(colors[i % colors.length])
            .withValues(alpha: (1 - progress) * .85);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle + progress * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 3 + i % 3, height: 7),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CandyFireworks old) =>
      old.progress != progress || old.theme != theme;
}
