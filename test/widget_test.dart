import 'dart:io';

import 'package:candyverse/app/app.dart';
import 'package:candyverse/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppTheme theme;
  setUpAll(() async {
    final fonts = FontLoader('Roboto');
    for (final weight in ['Regular', 'Bold', 'Black']) {
      fonts.addFont(
        Future.value(
          ByteData.sublistView(
            File('test/fonts/Roboto-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    await fonts.load();
    theme = await AppTheme.load();
  });
  testWidgets('Home starts using the checked-in candy palette', (tester) async {
    expect(theme.color('ink'), const Color(0xFF372858));
    await tester.pumpWidget(CandyverseApp(theme: theme));
    expect(find.text('Candyverse'), findsOneWidget);
    expect(find.text('BLOCK & BLOOM'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Home fits ${width}dp at text scale $scale', (tester) async {
        tester.view.physicalSize = Size(width, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(CandyverseApp(theme: theme));
        expect(tester.takeException(), isNull);
        expect(find.text('Candyverse'), findsOneWidget);
      });
    }
  }

  testWidgets('Home visual reference at 320dp', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(CandyverseApp(theme: theme));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/home_320.png'),
    );
  });
}
