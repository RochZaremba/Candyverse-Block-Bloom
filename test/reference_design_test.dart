import 'dart:io';

import 'package:candyverse/core/theme/app_theme.dart';
import 'package:candyverse/game/application/game_controller.dart';
import 'package:candyverse/game/domain/board.dart';
import 'package:candyverse/game/domain/game_engine.dart';
import 'package:candyverse/game/domain/game_state.dart';
import 'package:candyverse/game/domain/piece.dart';
import 'package:candyverse/game/presentation/game_screen.dart';
import 'package:candyverse/home/home_screen.dart';
import 'package:candyverse/island/domain/island_state.dart';
import 'package:candyverse/island/presentation/persistent_island_screen.dart';
import 'package:candyverse/save/application/app_session.dart';
import 'package:candyverse/save/application/app_session_scope.dart';
import 'package:candyverse/save/domain/app_save.dart';
import 'package:candyverse/settings/settings_model.dart';
import 'package:candyverse/upgrades/domain/upgrade.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  AppSession profile({int Function()? clock}) {
    final session = AppSession.memory(
      clock: clock == null
          ? null
          : () => DateTime.fromMillisecondsSinceEpoch(clock()),
      save: AppSaveV1(
        wallet: 280,
        bestScore: 280,
        island: IslandState(
          levels: {
            BuildingKind.candyTree: 2,
            BuildingKind.jellyHouse: 1,
            BuildingKind.rainbowFountain: 1,
          },
        ),
      ),
    );
    addTearDown(session.dispose);
    return session;
  }

  Future<void> show(
    WidgetTester tester,
    AppSession session,
    Widget home,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      SettingsScope(
        settings: session.settings,
        child: AppSessionScope(
          session: session,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme.material,
            home: home,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  GameController puzzle({bool over = false}) {
    final blue = <(int, int)>[
      (5, 3),
      (5, 4),
      (5, 5),
      (6, 4),
      (6, 5),
      (6, 6),
      (7, 4),
      (7, 5),
    ];
    final yellow = <(int, int)>[(4, 6), (4, 7), (5, 6), (5, 7), (7, 6), (7, 7)];
    final board = Board.empty().withCells({
      for (final (r, c) in blue) (row: r, col: c): 'blueberry',
      for (final (r, c) in yellow) (row: r, col: c): 'lemonYellow',
    });
    Piece colored(String id, String skin) {
      final p = pieceCatalog.firstWhere((p) => p.id == id);
      return Piece(id: p.id, cells: p.cells, skin: skin);
    }

    final engine = GameEngine.seeded(seed: 46);
    final controller = GameController(
      engine: engine,
      onSnapshot: (_) async {},
      initialState: GameState(
        board: board,
        rngState: engine.start().rngState,
        score: over ? 280 : 140,
        tray: [
          null,
          colored('z', 'electricPurple'),
          colored('l_up', 'blueberry'),
        ],
        phase: over ? RunPhase.gameOver : RunPhase.playing,
      ),
    );
    addTearDown(controller.dispose);
    return controller;
  }

  testWidgets('reference menu uses live profile values at 9 by 16', (
    tester,
  ) async {
    final session = profile();
    await show(tester, session, HomeScreen(theme: theme, session: session));
    expect(find.text('280'), findsNWidgets(2));
    expect(
      tester.getRect(find.byKey(const Key('home-island'))).bottom,
      lessThanOrEqualTo(640),
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/reference_menu_360.png'),
    );
  });

  testWidgets('reference board remains playable with the pictured state', (
    tester,
  ) async {
    final session = profile();
    final controller = puzzle();
    await show(
      tester,
      session,
      GameScreen(theme: theme, controller: controller),
    );
    await tester.tap(find.byKey(const ValueKey('tray-1')));
    await tester.pump();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/reference_game_360.png'),
    );
    await tester.tap(find.byKey(const ValueKey('cell-0-0')));
    await tester.pumpAndSettle();
    expect(controller.state.score, 180);
    expect(controller.state.tray[1], isNull);
  });

  testWidgets('reference return dialog keeps the same run on cancellation', (
    tester,
  ) async {
    final session = profile();
    final controller = puzzle();
    await show(
      tester,
      session,
      GameScreen(theme: theme, controller: controller),
    );
    final before = controller.state;
    await tester.tap(find.byTooltip('Back to menu'));
    await tester.pumpAndSettle();
    expect(
      find.text('Your run stays saved. Resume it from the menu.'),
      findsOneWidget,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/reference_return_360.png'),
    );
    await tester.tap(find.text('Keep playing'));
    await tester.pumpAndSettle();
    expect(identical(before, controller.state), isTrue);
  });

  testWidgets('reference result actions restart the real controller', (
    tester,
  ) async {
    final session = profile();
    final controller = puzzle(over: true);
    await show(
      tester,
      session,
      GameScreen(theme: theme, controller: controller),
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/reference_result_360.png'),
    );
    await tester.tap(find.text('Play again'));
    await tester.pumpAndSettle();
    expect(controller.isGameOver, isFalse);
    expect(controller.state.board.occupiedCount, 0);
  });

  testWidgets(
    'reference island cards persist purchases and collect actual income',
    (tester) async {
      var now = 1000;
      final session = profile(clock: () => now);
      await show(
        tester,
        session,
        PersistentIslandScreen(theme: theme, session: session),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/reference_island_360.png'),
      );
      final tabs = tester.getRect(find.byKey(const ValueKey('island-tab-3')));
      expect(tabs.bottom, lessThanOrEqualTo(640));
      final price = session.save.price(BuildingKind.candyTree)!;
      await tester.ensureVisible(
        find.byKey(const ValueKey('upgrade-card-candyTree')),
      );
      await tester.tap(find.byKey(const ValueKey('upgrade-card-candyTree')));
      await tester.pumpAndSettle();
      expect(session.save.wallet, 280 - price);
      expect(
        (await session.repository.load()).island.level(BuildingKind.candyTree),
        3,
      );
      now += 3600000;
      await tester.ensureVisible(find.text('COLLECT'));
      await tester.tap(find.text('COLLECT'));
      await tester.pumpAndSettle();
      expect(session.save.wallet, 280 - price + 120);
      for (final index in [1, 2, 3, 0]) {
        await tester.tap(find.byKey(ValueKey('island-tab-$index')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
}
