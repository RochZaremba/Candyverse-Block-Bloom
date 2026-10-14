import 'dart:io';

import 'package:candyverse/core/theme/app_theme.dart';
import 'package:candyverse/game/application/game_controller.dart';
import 'package:candyverse/game/domain/board.dart';
import 'package:candyverse/game/domain/game_engine.dart';
import 'package:candyverse/game/domain/game_state.dart';
import 'package:candyverse/game/domain/piece.dart';
import 'package:candyverse/game/presentation/game_screen.dart';
import 'package:candyverse/upgrades/domain/upgrade.dart';
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
  final dot = pieceCatalog.first;
  GameController create({
    Board? board,
    int lines = 0,
    int pending = 0,
    int erasers = 0,
  }) {
    final e = GameEngine(traySource: (_) => [dot, dot, dot]);
    return GameController(
      engine: e,
      initialState: GameState(
        board: board ?? Board.empty(),
        tray: [dot, dot, dot],
        totalClearedLines: lines,
        pendingUpgradeChoices: pending,
        eraserAcquired: erasers,
        eraserUses: erasers,
      ),
    );
  }

  Future<void> show(
    WidgetTester tester,
    GameController controller, {
    double width = 412,
    double scale = 1,
    bool reduced = false,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: reduced);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme.material,
        home: GameScreen(theme: theme, controller: controller),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'actual milestone waits for clear animation then chosen Lucky updates coins',
    (tester) async {
      final board = Board.empty().withCells({
        for (var c = 0; c < 7; c++) (row: 0, col: c): 'candyPink',
      });
      final controller = create(board: board, lines: 4);
      await show(tester, controller);
      await tester.tap(find.byKey(const ValueKey('tray-0')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('cell-0-7')));
      await tester.pump();
      expect(controller.state.phase, RunPhase.upgrade);
      expect(find.text('Wybierz ulepszenie'), findsNothing);
      final pending = controller.state;
      controller.place(1, (row: 1, col: 1));
      expect(controller.state, same(pending));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Wybierz ulepszenie'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('upgrade-luckyJelly')));
      await tester.pumpAndSettle();
      expect(controller.state.luckyJellyLevel, 1);
      expect(controller.state.pendingCoins, 31);
      expect(find.text('31'), findsOneWidget);
      expect(find.text('Następne ulepszenie: 5/10 linii'), findsOneWidget);
    },
  );

  testWidgets(
    'eraser cancel leaves snapshot; confirmation erases exactly one cell',
    (tester) async {
      final controller = create(
        board: Board.empty().withCells({(row: 0, col: 0): 'candyPink'}),
        erasers: 1,
      );
      await show(tester, controller);
      await tester.tap(find.text('Rainbow Eraser (1)'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('cell-0-0')));
      await tester.pumpAndSettle();
      final before = controller.state;
      await tester.tap(find.text('Anuluj'));
      await tester.pumpAndSettle();
      expect(controller.state, same(before));
      await tester.tap(find.byKey(const ValueKey('cell-0-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wymaż pole'));
      await tester.pumpAndSettle();
      expect(controller.state.board.occupiedCount, 0);
      expect(controller.state.eraserUses, 0);
      expect(controller.state.score, 0);
    },
  );

  testWidgets('no-move offers rescue and declining opens result', (
    tester,
  ) async {
    final full = Board.fromRows(
      List.generate(8, (_) => List.filled(8, 'candyPink')),
    );
    final controller = create(board: full, erasers: 1);
    await show(tester, controller);
    expect(find.text('Zagraj ponownie'), findsNothing);
    expect(find.text('Rainbow Eraser (1)'), findsOneWidget);
    await tester.tap(find.text('Zakończ podejście'));
    await tester.pumpAndSettle();
    expect(controller.isGameOver, isTrue);
    expect(find.text('Zagraj ponownie'), findsOneWidget);
  });

  testWidgets(
    'all cards remain readable selectable at 320dp text2 with semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();

      final controller = create(pending: 1);
      await show(tester, controller, width: 320, scale: 2);
      expect(tester.takeException(), isNull);
      final card = find.byKey(const ValueKey('upgrade-rainbowEraser'));
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(card).getSemanticsData().label,
        contains('Rainbow Eraser'),
      );
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(controller.state.eraserUses, 1);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
  testWidgets('cards show real descriptions and original candy emblems', (
    tester,
  ) async {
    await show(tester, create(pending: 2));
    expect(find.text('Pozostałe wybory: 2'), findsOneWidget);
    await expectLater(
      find.byType(GameScreen),
      matchesGoldenFile('goldens/upgrades_412.png'),
    );
  });

  testWidgets('queued choices stay modal until all choices are applied', (
    tester,
  ) async {
    final controller = create(pending: 2);
    await show(tester, controller);
    await tester.tap(find.byKey(const ValueKey('upgrade-sugarRush')));
    await tester.pump();
    expect(controller.state.pendingUpgradeChoices, 1);
    expect(find.text('Wybierz ulepszenie'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('upgrade-rainbowEraser')));
    await tester.pumpAndSettle();
    expect(controller.state.phase, RunPhase.playing);
    expect(controller.state.sugarRushLevel, 1);
    expect(controller.state.eraserAcquired, 1);
    expect(find.text('Wybierz ulepszenie'), findsNothing);
  });

  testWidgets('reduced motion milestone reveals choices without waiting', (
    tester,
  ) async {
    final controller = create(
      lines: 4,
      board: Board.empty().withCells({
        for (var c = 0; c < 7; c++) (row: 0, col: c): 'candyPink',
      }),
    );
    await show(tester, controller, reduced: true);
    controller.place(0, (row: 0, col: 7));
    await tester.pump();
    expect(find.text('Wybierz ulepszenie'), findsOneWidget);
  });

  testWidgets('confirmed no-move rescue enables pieces again', (tester) async {
    final controller = create(
      board: Board.fromRows(
        List.generate(8, (_) => List.filled(8, 'candyPink')),
      ),
      erasers: 1,
    );
    await show(tester, controller);
    await tester.tap(find.text('Rainbow Eraser (1)'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('cell-0-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wymaż pole'));
    await tester.pumpAndSettle();
    expect(controller.state.phase, RunPhase.playing);
    expect(controller.state.board.occupiedCount, 63);
    expect(controller.state.pendingCoins, 0);
    expect(find.text('Zakończ podejście'), findsNothing);
  });
  testWidgets('declining while choosing erase target cannot lock a fresh run', (
    tester,
  ) async {
    final controller = create(
      board: Board.fromRows(
        List.generate(8, (_) => List.filled(8, 'candyPink')),
      ),
      erasers: 1,
    );
    await show(tester, controller);
    await tester.tap(find.text('Rainbow Eraser (1)'));
    await tester.pump();
    await tester.tap(find.text('Zakończ podejście'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zagraj ponownie'));
    await tester.pumpAndSettle();
    expect(controller.state.eraserAcquired, 0);
    await tester.tap(find.byKey(const ValueKey('tray-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('cell-0-0')));
    await tester.pump();
    expect(controller.state.board.occupiedCount, 1);
  });
}
