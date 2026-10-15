import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A single cell of a locally bundled atlas. All cells share Flutter's image
/// cache; the source rectangle keeps neighbouring artwork out of the frame.
class KingdomSprite extends StatefulWidget {
  const KingdomSprite({
    required this.asset,
    required this.row,
    required this.column,
    required this.rows,
    required this.columns,
    this.fit = BoxFit.contain,
    this.sourceRect,
    this.alignment = Alignment.center,
    super.key,
  }) : assert(rows > 0),
       assert(columns > 0),
       assert(row >= 0 && row < rows),
       assert(column >= 0 && column < columns);

  final String asset;
  final int row, column, rows, columns;
  final BoxFit fit;

  /// Optional source pixels for generated atlases with unequal cell heights.
  final Rect? sourceRect;
  final Alignment alignment;

  @override
  State<KingdomSprite> createState() => _KingdomSpriteState();
}

class _KingdomSpriteState extends State<KingdomSprite> {
  ImageStream? _stream;
  ImageInfo? _image;
  late final _listener = ImageStreamListener((image, _) {
    final previous = _image;
    setState(() => _image = image);
    previous?.dispose();
  });

  void _resolve() {
    final next = AssetImage(widget.asset)
        .resolve(createLocalImageConfiguration(context));
    if (next.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = next..addListener(_listener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(KingdomSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      _image?.dispose();
      _image = null;
      _resolve();
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _AtlasPainter(
      _image?.image,
      widget.row,
      widget.column,
      widget.rows,
      widget.columns,
      widget.fit,
      widget.sourceRect,
      widget.alignment,
    ),
    isComplex: true,
    child: const SizedBox.expand(),
  );
}

class _AtlasPainter extends CustomPainter {
  _AtlasPainter(
    this.image,
    this.row,
    this.column,
    this.rows,
    this.columns,
    this.fit,
    this.sourceRect,
    this.alignment,
  );
  final ui.Image? image;
  final int row, column, rows, columns;
  final BoxFit fit;
  final Rect? sourceRect;
  final Alignment alignment;

  @override
  void paint(Canvas canvas, Size size) {
    final bitmap = image;
    if (bitmap == null || size.isEmpty) return;
    final cell =
        sourceRect ??
        Rect.fromLTWH(
          column * bitmap.width / columns,
          row * bitmap.height / rows,
          bitmap.width / columns,
          bitmap.height / rows,
        );
    final cellSize = cell.size;
    final fitted = applyBoxFit(fit, cellSize, size);
    final crop = Alignment.center.inscribe(
      fitted.source,
      Offset.zero & cellSize,
    );
    final source = crop.shift(cell.topLeft);
    final destination = alignment.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    canvas.drawImageRect(
      bitmap,
      source,
      destination,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_AtlasPainter old) =>
      image != old.image ||
      row != old.row ||
      column != old.column ||
      rows != old.rows ||
      columns != old.columns ||
      fit != old.fit ||
      sourceRect != old.sourceRect ||
      alignment != old.alignment;
}
