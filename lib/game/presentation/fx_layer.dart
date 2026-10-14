import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../settings/settings_model.dart';
import '../domain/cell.dart';

/// An accepted move's presentation-only metadata, never an engine mutation.
class CandyFxEvent {
  CandyFxEvent({
    required this.id,
    required Iterable<Cell> placed,
    required Iterable<Cell> cleared,
  }) : placed = List.unmodifiable(placed),
       cleared = List.unmodifiable(cleared);
  final int id;
  final List<Cell> placed;
  final List<Cell> cleared;
}

/// Overlay exactly the board bounds. Input remains available throughout the FX.
class FxLayer extends StatefulWidget {
  const FxLayer({required this.theme, this.event, super.key});
  final AppTheme theme;
  final CandyFxEvent? event;
  @override
  State<FxLayer> createState() => _FxLayerState();
}

class _FxLayerState extends State<FxLayer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.theme.lineClearMs),
  );
  bool active = true;
  bool reduced = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reduced = SettingsScope.reducedMotionOf(context);
    if (reduced) animation.value = 1;
  }

  @override
  void didUpdateWidget(FxLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.event?.id != oldWidget.event?.id && active && !reduced) {
      animation.duration = Duration(
        milliseconds: widget.event?.cleared.isEmpty ?? true
            ? widget.theme.tilePlaceMs
            : widget.theme.lineClearMs,
      );
      animation.forward(from: 0);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
    if (!active) animation.value = 1;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: animation,
          builder: (_, _) => CustomPaint(
            painter: _FxPainter(
              widget.theme,
              widget.event,
              reduced || !active ? 1 : animation.value,
            ),
          ),
        ),
      ),
    ),
  );
}

class _FxPainter extends CustomPainter {
  _FxPainter(this.theme, this.event, this.progress);
  final AppTheme theme;
  final CandyFxEvent? event;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    if (event == null || progress <= 0 || progress >= 1) return;
    final unit = size.width / 8;
    final paint = Paint();
    for (final cell in event!.placed) {
      final center = Offset((cell.col + .5) * unit, (cell.row + .5) * unit);
      final scale = 1 + math.sin(progress * math.pi) * .10;
      final rect = Rect.fromCenter(
        center: center,
        width: unit * .8 * scale,
        height: unit * .8 / scale,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(theme.tileRadius * .65)),
        paint
          ..color = theme
              .color('creamWhite')
              .withValues(alpha: (1 - progress) * .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    if (event!.cleared.isEmpty) return;
    // A small local glow precedes the confetti; never flash the full screen.
    for (final cell in event!.cleared) {
      final center = Offset((cell.col + .5) * unit, (cell.row + .5) * unit);
      canvas.drawCircle(
        center,
        unit * (.35 + progress * .2),
        paint
          ..style = PaintingStyle.fill
          ..color = theme
              .color('lemonYellow')
              .withValues(alpha: math.max(0, 1 - progress * 3) * .3),
      );
    }
    final count = math.min(theme.maxParticles, event!.cleared.length * 3);
    final names = ['candyPink', 'turquoise', 'lemonYellow', 'electricPurple'];
    for (var i = 0; i < count; i++) {
      final cell = event!.cleared[i % event!.cleared.length];
      final origin = Offset((cell.col + .5) * unit, (cell.row + .5) * unit);
      final angle = i * 2.399963;
      final radius = unit * progress * (1 + (i % 3) * .4);
      final point =
          origin +
          Offset(
            math.cos(angle) * radius,
            math.sin(angle) * radius + unit * progress * progress * .6,
          );
      canvas.drawCircle(
        point,
        unit * .07 * (1 - progress) + .4,
        paint
          ..style = PaintingStyle.fill
          ..color = theme.color(names[i % 4]).withValues(alpha: 1 - progress),
      );
    }
  }

  @override
  bool shouldRepaint(_FxPainter oldDelegate) =>
      oldDelegate.event != event ||
      oldDelegate.progress != progress ||
      oldDelegate.theme != theme;
}
