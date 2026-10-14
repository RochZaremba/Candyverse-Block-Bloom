import 'package:candyverse/save/application/app_session.dart';

import 'dart:io';

import 'package:candyverse/app/app.dart';
import 'package:candyverse/core/theme/app_theme.dart';
import 'package:candyverse/island/domain/island_state.dart';
import 'package:candyverse/island/presentation/island_scene.dart';
import 'package:candyverse/island/presentation/island_screen.dart';
import 'package:candyverse/settings/settings_model.dart';
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
  void viewport(
    WidgetTester tester, {
    double width = 320,
    double scale = 1,
    bool reduced = true,
  }) {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: reduced);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  for (var level = 0; level <= 3; level++) {
    testWidgets('real island level$level visual reference', (tester) async {
      viewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme.material,
          home: IslandScreen(
            theme: theme,
            island: IslandState(
              levels: {for (final kind in BuildingKind.values) kind: level},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final kind in CandyCharacter.values) {
        expect(find.byKey(ValueKey('character-${kind.name}')), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/island_level$level.png'),
      );
    });
  }
  testWidgets('four characters react without animation under reduced motion', (
    tester,
  ) async {
    viewport(tester);
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IslandScene(theme: theme, island: IslandState()),
          ),
        ),
      );
      for (final kind in CandyCharacter.values) {
        final target = find.byKey(ValueKey('character-${kind.name}'));
        final size = tester.getSize(target);
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
        await tester.tap(target);
        await tester.pump();
        expect(
          find.bySemanticsLabel('${characterName(kind)} wita Cię'),
          findsOneWidget,
        );
      }
      expect(tester.binding.transientCallbackCount, 0);
    } finally {
      semantics.dispose();
    }
  });
  testWidgets(
    'idle and tap tickers stop in background or reduced preferences',
    (tester) async {
      viewport(tester, reduced: false);
      final settings = SettingsModel();
      addTearDown(settings.dispose);
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      await tester.pumpWidget(
        SettingsScope(
          settings: settings,
          child: MaterialApp(
            home: Scaffold(
              body: IslandScene(theme: theme, island: IslandState()),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await tester.tap(find.byKey(const ValueKey('character-pinkMochi')));
      await tester.pump(const Duration(milliseconds: 100));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      settings.setReduceMotion(true);
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(const SizedBox());
      expect(tester.binding.transientCallbackCount, 0);
    },
  );
  testWidgets('Home opens actual island and building information', (
    tester,
  ) async {
    viewport(tester);
    await tester.pumpWidget(
      CandyverseApp(theme: theme, session: AppSession.memory()),
    );
    await tester.ensureVisible(find.text('Odwiedź wyspę'));
    await tester.tap(find.text('Odwiedź wyspę'));
    await tester.pumpAndSettle();
    expect(find.byType(IslandScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('building-candyTree')));
    await tester.pumpAndSettle();
    expect(find.text('Cukierkowe drzewo'), findsWidgets);
    await tester.tap(find.text('Wróć na wyspę'));
    await tester.pumpAndSettle();
    expect(find.byType(IslandScreen), findsOneWidget);
  });
  for (final width in [320.0, 412.0]) {
    testWidgets('island fits $width dp at text2 without overflow', (
      tester,
    ) async {
      viewport(tester, width: width, scale: 2);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme.material,
          home: IslandScreen(theme: theme, island: IslandState()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('character-mintyMonster')),
        findsOneWidget,
      );
    });
  }
}
