import 'package:candyverse/save/application/app_session.dart';

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
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    theme = await AppTheme.load();
  });
  Future<VoidCallback> showHome(WidgetTester tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      CandyverseApp(theme: theme, session: AppSession.memory()),
    );
    await tester.runAsync(() async {
      for (final asset in ['brand-sheet.png', 'mascots.png']) {
        await precacheImage(
          AssetImage('assets/kingdom/$asset'),
          tester.element(find.byType(Scaffold).first),
        );
      }
    });
    await tester.pump();
    return semantics.dispose;
  }

  testWidgets('Home starts using the checked-in candy palette', (tester) async {
    expect(theme.color('ink'), const Color(0xFF372858));
    final disposeSemantics = await showHome(tester);
    expect(find.bySemanticsLabel('Candyverse: Block & Bloom'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('ISLAND'), findsOneWidget);
    expect(tester.takeException(), isNull);
    disposeSemantics();
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
        final disposeSemantics = await showHome(tester);
        expect(tester.takeException(), isNull);
        expect(
          find.bySemanticsLabel('Candyverse: Block & Bloom'),
          findsOneWidget,
        );
        disposeSemantics();
      });
    }
  }

  testWidgets('Home visual reference at 320dp', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final disposeSemantics = await showHome(tester);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/home_320.png'),
    );
    disposeSemantics();
  });
}
