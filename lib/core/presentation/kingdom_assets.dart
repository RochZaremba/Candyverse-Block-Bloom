import 'dart:async';

import 'package:flutter/painting.dart';

/// Decode once before the first Flutter frame; all routes share these same keys.
Future<void> warmKingdomAssets() async {
  for (final name in [
    'brand-sheet',
    'mascots',
    'buildings',
    'worlds',
    'menu-scene',
    'game-scene',
    'island-scene',
    'control-atlas',
    'reference-mascots',
    'reference-logo',
    'reference-buildings',
    'result-scene',
  ]) {
    final stream = AssetImage('assets/kingdom/$name.png')
        .resolve(ImageConfiguration.empty);
    final loaded = Completer<void>();
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (image, synchronousCall) {
        if (!loaded.isCompleted) loaded.complete();
        stream.removeListener(listener);
        image.dispose();
      },
      onError: (Object error, StackTrace? stack) {
        if (!loaded.isCompleted) loaded.completeError(error, stack);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    await loaded.future;
  }
}
