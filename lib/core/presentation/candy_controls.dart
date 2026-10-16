import 'package:flutter/material.dart';

import '../../island/presentation/kingdom_sprite.dart';

const candyInk = Color(0xff4b146d);

/// Local artwork is decorative; labels, amounts and hit targets stay live.
class CandyArt extends StatelessWidget {
  const CandyArt(this.asset, {this.fit = BoxFit.cover, super.key});
  final String asset;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      'assets/kingdom/$asset.png',
      fit: fit,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    ),
  );
}

class CandyLettering extends StatelessWidget {
  const CandyLettering(
    this.text, {
    this.size = 32,
    this.color = Colors.white,
    this.outline = candyInk,
    this.align = TextAlign.center,
    super.key,
  });
  final String text;
  final double size;
  final Color color, outline;
  final TextAlign align;
  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: align,
    style: TextStyle(
      fontFamily: 'LilitaOne',
      fontSize: size,
      height: 1.05,
      color: color,
      shadows: [
        for (final x in [-1.8, 0.0, 1.8])
          for (final y in [-1.8, 0.0, 1.8])
            if (x != 0 || y != 0) Shadow(color: outline, offset: Offset(x, y)),
        Shadow(color: outline, offset: const Offset(0, 3)),
      ],
    ),
  );
}

enum CandyButtonTone { gold, aqua, pink, cream }

class CandyAction extends StatelessWidget {
  const CandyAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = CandyButtonTone.gold,
    this.fontSize = 30,
    this.height = 72,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final CandyButtonTone tone;
  final double fontSize, height;
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onPressed == null ? .5 : 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: height, minWidth: 48),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: KingdomSprite(
                asset: 'assets/kingdom/control-atlas.png',
                row: tone.index,
                column: 0,
                rows: 4,
                columns: 1,
                fit: BoxFit.fill,
                sourceRect: switch (tone) {
                  CandyButtonTone.gold => const Rect.fromLTRB(0, 0, 1254, 324),
                  CandyButtonTone.aqua => const Rect.fromLTRB(
                    0,
                    323,
                    1254,
                    625,
                  ),
                  CandyButtonTone.pink => const Rect.fromLTRB(
                    0,
                    620,
                    1254,
                    930,
                  ),
                  CandyButtonTone.cream => const Rect.fromLTRB(
                    0,
                    922,
                    1254,
                    1254,
                  ),
                },
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(50),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: height <= 58 ? 10 : 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: fontSize * .95,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: candyInk,
                            blurRadius: 2,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: CandyLettering(
                        label,
                        size: fontSize,
                        color: tone == CandyButtonTone.cream
                            ? candyInk
                            : Colors.white,
                        outline:
                            tone == CandyButtonTone.gold ||
                                tone == CandyButtonTone.pink
                            ? const Color(0xffa30082)
                            : tone == CandyButtonTone.cream
                            ? Colors.white
                            : const Color(0xff00667a),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class CandyPanel extends StatelessWidget {
  const CandyPanel({
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = 24,
    super.key,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xfffffff5), Color(0xffffefdf)],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xffffe3ef), width: 3),
      boxShadow: const [
        BoxShadow(
          color: Color(0x90ff9bd5),
          blurRadius: 0,
          spreadRadius: 2,
          offset: Offset(0, 3),
        ),
        BoxShadow(
          color: Color(0x30a132b6),
          blurRadius: 10,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}

class CandyBadge extends StatelessWidget {
  const CandyBadge({this.trophy = false, this.size = 38, super.key});
  final bool trophy;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xffffff9e), Color(0xffffcc00), Color(0xffff9200)],
      ),
      border: Border.all(color: const Color(0xfffff3a5), width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0xffed8e08),
          offset: Offset(0, 2),
          spreadRadius: 1,
        ),
      ],
    ),
    child: Icon(
      trophy ? Icons.emoji_events_rounded : Icons.pets_rounded,
      color: const Color(0xffed9300),
      size: size * .72,
      shadows: const [Shadow(color: Color(0xfffffa95), offset: Offset(-1, -1))],
    ),
  );
}

class CandyMetric extends StatelessWidget {
  const CandyMetric({
    required this.label,
    required this.value,
    this.trophy = false,
    this.compact = false,
    super.key,
  });
  final String label, value;
  final bool trophy, compact;
  @override
  Widget build(BuildContext context) => CandyPanel(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 6 : 8,
      vertical: compact ? 5 : 7,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CandyBadge(trophy: trophy, size: compact ? 27 : 32),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 9 : 10,
                  fontWeight: FontWeight.w800,
                  color: candyInk,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'LilitaOne',
                  fontSize: compact ? 27 : 30,
                  height: 1.05,
                  color: candyInk,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class CandyBanner extends StatelessWidget {
  const CandyBanner({super.key});
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 4.45,
    child: Stack(
      fit: StackFit.expand,
      children: [
        const KingdomSprite(
          asset: 'assets/kingdom/menu-scene.png',
          row: 0,
          column: 0,
          rows: 1,
          columns: 1,
          sourceRect: Rect.fromLTRB(28, 298, 914, 508),
          fit: BoxFit.fill,
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 65),
            child: Text(
              'Przyszła\nreklama',
              textScaler: TextScaler.noScaling,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'LilitaOne',
                color: Color(0xff913493),
                fontSize: 22,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class CandyLogo extends StatelessWidget {
  const CandyLogo({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Candyverse: Block & Bloom',
    image: true,
    child: const AspectRatio(
      aspectRatio: 3.0,
      child: CandyArt('reference-logo', fit: BoxFit.contain),
    ),
  );
}

class CandyFriends extends StatelessWidget {
  const CandyFriends({this.height = 130, super.key});
  final double height;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final index in [2, 0, 1])
            SizedBox(
              width: height * (index == 0 ? .95 : .72),
              height: height * (index == 0 ? 1 : .8),
              child: KingdomSprite(
                asset: 'assets/kingdom/reference-mascots.png',
                row: index ~/ 2,
                column: index % 2,
                rows: 3,
                columns: 2,
                sourceRect: referencePetRect(index),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Atlas order is part of the checked-in artwork contract.
enum CandySymbol { home, back, settings, play, success, attention, info, retry }

class CandyGlyph extends StatelessWidget {
  const CandyGlyph(this.symbol, {this.size = 48, super.key});
  final CandySymbol symbol;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: KingdomSprite(
        asset: 'assets/kingdom/navigation-atlas.png',
        row: symbol.index ~/ 2,
        column: symbol.index % 2,
        rows: 4,
        columns: 2,
        sourceRect: Rect.fromLTRB(
          symbol.index.isEven ? 88 : 520,
          (symbol.index ~/ 2) * 384,
          symbol.index.isEven ? 504 : 936,
          (symbol.index ~/ 2 + 1) * 384,
        ),
      ),
    ),
  );
}

class CandyIconButton extends StatelessWidget {
  const CandyIconButton({
    required this.symbol,
    required this.label,
    required this.onPressed,
    super.key,
  });
  final CandySymbol symbol;
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: onPressed,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    icon: Opacity(
      opacity: onPressed == null ? .5 : 1,
      child: CandyGlyph(symbol),
    ),
  );
}

/// Secondary screens share the same scenery and clearly labelled back action.
class CandyPage extends StatelessWidget {
  const CandyPage({
    required this.title,
    required this.backLabel,
    required this.child,
    super.key,
  });
  final String title, backLabel;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        const CandyArt('game-scene'),
        const ColoredBox(color: Color(0xd9fff4dd)),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(
                      children: [
                        if (Navigator.canPop(context))
                          CandyIconButton(
                            symbol: CandySymbol.back,
                            label: backLabel,
                            onPressed: () => Navigator.maybePop(context),
                          )
                        else
                          const SizedBox.square(dimension: 48),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CandyLettering(
                            title,
                            size: 28,
                            color: const Color(0xffff94d8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const SizedBox.square(dimension: 48),
                      ],
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
