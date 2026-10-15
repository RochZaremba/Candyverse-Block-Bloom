import 'dart:async';

import 'package:flutter/painting.dart';

/// Decode once before the first Flutter frame; all routes share these same keys.
Future<void> warmKingdomAssets() async {
  for (final name in ['brand-sheet', 'mascots', 'buildings', 'worlds']) {
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
