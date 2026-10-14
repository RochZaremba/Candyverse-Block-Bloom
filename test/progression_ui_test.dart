import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:candyverse/app/app.dart';
import 'package:candyverse/core/theme/app_theme.dart';
import 'package:candyverse/save/application/app_session.dart';
import 'package:candyverse/save/domain/app_save.dart';
import 'package:candyverse/island/domain/island_state.dart';
import 'package:candyverse/island/presentation/island_screen.dart';
import 'package:candyverse/game/presentation/game_screen.dart';
import 'package:candyverse/game/application/game_controller.dart';
import 'package:candyverse/game/domain/game_engine.dart';

import 'dart:io';

import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppTheme theme;
  setUpAll(() async {
    theme = await AppTheme.load();
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
  });
  Future<void> prepare(
    WidgetTester tester,
    Widget app, {
    double width = 412,
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 960);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'real island purchase updates scene and survives application restore',
    (tester) async {
      final session = AppSession.memory(save: AppSaveV1(wallet: 40));
      final repo = session.repository;
      await prepare(tester, CandyverseApp(theme: theme, session: session));
      await tester.tap(find.text('Odwiedź wyspę'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cukierkowe drzewo'));
      await tester.pumpAndSettle();
      expect(find.text('Rozbuduj • 10 Candy Coins'), findsOneWidget);
      await tester.tap(find.text('Rozbuduj • 10 Candy Coins'));
      await tester.pumpAndSettle();
      expect(session.save.wallet, 30);
      expect(session.save.island.level(BuildingKind.candyTree), 1);
      expect(find.text('Candy Coins: 30'), findsOneWidget);
      expect(find.text('Poziom 1/3'), findsOneWidget);
      await expectLater(
        find.byType(IslandScreen),
        matchesGoldenFile('goldens/island_purchase_412.png'),
      );
      await tester.pumpWidget(const SizedBox());
      final restored = AppSession(repo, await repo.load());
      await tester.pumpWidget(CandyverseApp(theme: theme, session: restored));
      await tester.pumpAndSettle();
      expect(find.text('Rekord: 0  •  Candy Coins: 30'), findsOneWidget);
      expect(restored.save.island.level(BuildingKind.candyTree), 1);
    },
  );
  testWidgets('pause and restart application retains board and offers resume', (
    tester,
  ) async {
    final session = AppSession.memory(seedSource: () => 8);
    final repo = session.repository;
    await prepare(tester, CandyverseApp(theme: theme, session: session));
    await tester.tap(find.text('GRAJ'));
    await tester.pumpAndSettle();
    final game = tester.widget<GameScreen>(find.byType(GameScreen)).controller!;
    final slot = game.state.tray.indexWhere((p) => p != null);
    final cell = game.engine
        .getLegalPlacements(game.state.board, game.state.tray[slot]!)
        .first;
    await tester.tap(find.byKey(ValueKey('tray-$slot')));
    await tester.pump();
    await tester.tap(find.byKey(ValueKey('cell-${cell.row}-${cell.col}')));
    await tester.pumpAndSettle();
    final raw = session.save.encode();
    await tester.tap(find.byTooltip('Wróć do menu'));
    await tester.pumpAndSettle();
    expect(
      find.text('Podejście pozostanie zapisane. Wznowisz je z menu.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Wróć do menu').last);
    await tester.pumpAndSettle();
    expect(find.text('WZNÓW'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    final next = AppSession(repo, await repo.load());
    await tester.pumpWidget(CandyverseApp(theme: theme, session: next));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WZNÓW'));
    await tester.pumpAndSettle();
    expect(next.save.encode(), raw);
    expect(
      tester
          .widget<GameScreen>(find.byType(GameScreen))
          .controller!
          .state
          .board
          .occupiedCount,
      greaterThan(0),
    );
  });
  testWidgets('save failure presents a real retry and blocks placement', (
    tester,
  ) async {
    bool fail = true;
    final controller = GameController(
      engine: GameEngine.seeded(seed: 8),
      onSnapshot: (_) async {
        if (fail) throw StateError('storage unavailable');
      },
    );
    addTearDown(controller.dispose);
    await prepare(
      tester,
      MaterialApp(
        theme: theme.material,
        home: GameScreen(theme: theme, controller: controller),
      ),
    );
    final cell = controller.engine
        .getLegalPlacements(
          controller.state.board,
          controller.state.tray.first!,
        )
        .first;
    await tester.tap(find.byKey(const ValueKey('tray-0')));
    await tester.pump();
    await tester.tap(find.byKey(ValueKey('cell-${cell.row}-${cell.col}')));
    await tester.pumpAndSettle();
    expect(find.text('Ponów zapis'), findsOneWidget);
    expect(controller.blocked, isTrue);
    fail = false;
    await tester.tap(find.text('Ponów zapis'));
    await tester.pumpAndSettle();
    expect(controller.blocked, isFalse);
    expect(find.text('Ponów zapis'), findsNothing);
  });
  testWidgets('purchase confirmation fits 320dp at double text size', (
    tester,
  ) async {
    await prepare(
      tester,
      CandyverseApp(
        theme: theme,
        session: AppSession.memory(save: AppSaveV1(wallet: 20)),
      ),
      width: 320,
      textScale: 2,
    );
    await tester.ensureVisible(find.text('Odwiedź wyspę'));
    await tester.tap(find.text('Odwiedź wyspę'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cukierkowe drzewo'));
    await tester.tap(find.text('Cukierkowe drzewo'));
    await tester.pumpAndSettle();
    expect(find.text('Rozbuduj • 10 Candy Coins'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
