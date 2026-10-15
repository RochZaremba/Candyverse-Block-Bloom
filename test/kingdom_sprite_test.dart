import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:candyverse/island/presentation/kingdom_sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _AtlasBundle extends CachingAssetBundle {
  _AtlasBundle(this.png);
  final ByteData png;
  @override
  Future<ByteData> load(String key) =>
      key == 'test-atlas.png' ? Future.value(png) : rootBundle.load(key);
}

void main() {
  testWidgets('atlas cells render separately without neighbouring artwork', (
    tester,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const colors = [Colors.red, Colors.green, Colors.blue, Colors.yellow];
    for (var index = 0; index < 4; index++) {
      canvas.drawRect(
        Rect.fromLTWH((index % 2) * 16, (index ~/ 2) * 16, 16, 16),
        Paint()..color = colors[index],
      );
    }
    final picture = recorder.endRecording();
    final image = (await tester.runAsync(() => picture.toImage(32, 32)))!;
    final png = (await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.png),
    ))!;
    final bundle = _AtlasBundle(png);
    image.dispose();
    picture.dispose();
    const boundary = ValueKey('atlas-boundary');
    for (var index = 0; index < 4; index++) {
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: bundle,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RepaintBoundary(
                key: boundary,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: KingdomSprite(
                    asset: 'test-atlas.png',
                    row: index ~/ 2,
                    column: index % 2,
                    rows: 2,
                    columns: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await precacheImage(
          AssetImage('test-atlas.png', bundle: bundle),
          tester.element(find.byType(KingdomSprite)),
        );
      });
      await tester.pump();
      final render = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(boundary),
      );
      final captured = (await tester.runAsync(() => render.toImage()))!;
      final bytes = (await tester.runAsync(() => captured.toByteData()))!.buffer
          .asUint8List();
      final offset = (20 * 40 + 20) * 4;
      final actual = Color.fromARGB(
        bytes[offset + 3],
        bytes[offset],
        bytes[offset + 1],
        bytes[offset + 2],
      );
      expect(actual.toARGB32(), colors[index].toARGB32());
      captured.dispose();
    }
    expect(tester.takeException(), isNull);
  });
}
