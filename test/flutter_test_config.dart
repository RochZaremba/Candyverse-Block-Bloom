import 'dart:async';
import 'dart:io';

import 'package:candyverse/core/presentation/kingdom_assets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Match production's first-frame asset warmup in every widget-test isolate.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bodyFont = FontLoader('Roboto');
  for (final weight in ['Regular', 'Bold', 'Black']) {
    bodyFont.addFont(
      Future.value(
        ByteData.sublistView(
          File('test/fonts/Roboto-$weight.ttf').readAsBytesSync(),
        ),
      ),
    );
  }
  await bodyFont.load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  await (FontLoader(
    'LilitaOne',
  )..addFont(rootBundle.load('assets/fonts/LilitaOne-Regular.ttf'))).load();
  await warmKingdomAssets();
  await testMain();
}
