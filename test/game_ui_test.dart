import 'package:candyverse/save/application/app_session.dart';

import 'dart:io';

import 'package:candyverse/app/app.dart';
import 'package:candyverse/core/theme/app_theme.dart';
import 'package:candyverse/game/application/game_controller.dart';
import 'package:candyverse/game/domain/board.dart';
import 'package:candyverse/game/domain/game_engine.dart';
import 'package:candyverse/game/domain/game_state.dart';
import 'package:candyverse/game/domain/piece.dart';
import 'package:candyverse/game/presentation/candy_tile.dart';
import 'package:candyverse/game/presentation/game_screen.dart';
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

  GameController singles({Board? board}) {
    final engine = GameEngine(
      traySource: (_) => [for (var i = 0; i < 3; i++) pieceCatalog.first],
    );
    return GameController(
      engine: engine,
      initialState: board == null
          ? null
          : GameState(
              board: board,
              tray: [for (var i = 0; i < 3; i++) pieceCatalog.first],
            ),
    );
  }

  Future<void> show(
    WidgetTester tester,
    GameController controller, {
    double width = 412,
    double height = 800,
    double scale = 1,
    bool reduced = false,
  }) async {
    tester.view.physicalSize = Size(width, height);
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

  Future<void> drag(
    WidgetTester tester,
    int slot,
    int row,
    int col, {
    bool drop = true,
  }) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(ValueKey('tray-$slot'))),
    );
    await gesture.moveBy(const Offset(0, -20));
    await gesture.moveTo(
      tester.getCenter(find.byKey(ValueKey('cell-$row-$col'))) +
          const Offset(0, 64),
    );
    await tester.pump();
    if (drop) {
      await gesture.up();
      await tester.pump();
    } else {
      await gesture.cancel();
      await tester.pump();
    }
  }

  for (final size in [const Size(393, 650), const Size(320, 592)]) {
    testWidgets('all three pieces stay visible on phone $size', (tester) async {
      final controller = singles();
      addTearDown(controller.dispose);
      await show(tester, controller, width: size.width, height: size.height);
      for (var slot = 0; slot < 3; slot++) {
        final bounds = tester.getRect(find.byKey(ValueKey('tray-$slot')));
        expect(bounds.bottom, lessThanOrEqualTo(size.height));
        expect(bounds.top, greaterThanOrEqualTo(0));
      }
      if (size.width == 393) {
        await expectLater(
          find.byType(GameScreen),
          matchesGoldenFile('goldens/game_phone_compact.png'),
        );
      }
      await tester.tap(find.byKey(const ValueKey('tray-2')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('cell-7-7')));
      await tester.pump();
      expect(controller.state.board.occupiedCount, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('all catalogue masks fit fully inside phone tray panels', (
    tester,
  ) async {
    for (final size in [const Size(320, 592), const Size(393, 650)]) {
      for (final piece in pieceCatalog) {
        await tester.pumpWidget(const SizedBox());
        final controller = GameController(
          engine: GameEngine(traySource: (_) => [piece, piece, piece]),
        );
        addTearDown(controller.dispose);
        await show(tester, controller, width: size.width, height: size.height);
        for (var slot = 0; slot < 3; slot++) {
          final tray = find.byKey(ValueKey('tray-$slot'));
          final bounds = tester.getRect(tray).deflate(8);
          final tiles = find.descendant(
            of: tray,
            matching: find.byType(CandyTile),
          );
          expect(tiles, findsNWidgets(piece.cells.length));
          for (final tile in tiles.evaluate()) {
            final rect = tester.getRect(
              find.byElementPredicate((e) => identical(e, tile)),
            );
            expect(
              rect.left,
              greaterThanOrEqualTo(bounds.left - .01),
              reason: piece.id,
            );
            expect(
              rect.top,
              greaterThanOrEqualTo(bounds.top - .01),
              reason: piece.id,
            );
            expect(
              rect.right,
              lessThanOrEqualTo(bounds.right + .01),
              reason: piece.id,
            );
            expect(
              rect.bottom,
              lessThanOrEqualTo(bounds.bottom + .01),
              reason: piece.id,
            );
          }
        }
      }
    }
  });

  testWidgets(
    'Home Play opens actual game and back confirmation preserves it',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        CandyverseApp(theme: theme, session: AppSession.memory()),
      );
      await tester.tap(find.text('GRAJ'));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Wróć do menu'));
      await tester.pumpAndSettle();
      expect(find.text('Wrócić do menu?'), findsOneWidget);
      await tester.tap(find.text('Graj dalej'));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Wróć do menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wróć do menu').last);
      await tester.pumpAndSettle();
      expect(find.text('WZNÓW'), findsOneWidget);
    },
  );

  testWidgets(
    'drag maps lifted first cell correctly and consumes only selected slot',
    (tester) async {
      final controller = singles();
      addTearDown(controller.dispose);
      await show(tester, controller);
      await drag(tester, 1, 3, 4);
      expect(controller.state.board.at((row: 3, col: 4)), 'candyPink');
      expect(controller.state.board.occupiedCount, 1);
      expect(controller.state.tray[1], isNull);
      expect(controller.state.tray[0], isNotNull);
      expect(controller.state.score, 10);
    },
  );

  testWidgets(
    'invalid drag and explicit reselection still allow a line clear',
    (tester) async {
      final controller = singles(
        board: Board.empty().withCells({
          for (var col = 0; col < 7; col++) (row: 0, col: col): 'candyPink',
        }),
      );
      addTearDown(controller.dispose);
      await show(tester, controller, reduced: true);
      final before = controller.state;
      await drag(tester, 0, 0, 0);
      expect(controller.state, same(before));
      for (final key in ['tray-1', 'tray-0', 'cell-0-0']) {
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pump();
      }
      expect(controller.state, same(before));
      await tester.tap(find.byKey(const ValueKey('cell-0-7')));
      await tester.pumpAndSettle();
      expect(controller.state.totalClearedLines, 1);
      expect(controller.state.board.occupiedCount, 0);
    },
  );

  testWidgets(
    'ghost reflects collision and canceled/illegal drags preserve snapshot',
    (tester) async {
      final controller = singles(
        board: Board.empty().withCells({(row: 2, col: 2): 'turquoise'}),
      );
      addTearDown(controller.dispose);
      final before = controller.state;
      await show(tester, controller);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('tray-0'))),
      );
      await gesture.moveBy(const Offset(0, -20));
      await gesture.moveTo(
        tester.getCenter(find.byKey(const ValueKey('cell-2-2'))) +
            const Offset(0, 64),
      );
      await tester.pump();
      final tiles = tester.widgetList<CandyTile>(find.byType(CandyTile));
      expect(tiles.any((tile) => tile.ghost && tile.invalid), isTrue);
      await gesture.up();
      await tester.pump();
      expect(controller.state, same(before));
      expect(
        find.text('Tu klocek się nie mieści. Wybierz inne pole.'),
        findsOneWidget,
      );
      await drag(tester, 0, 1, 1, drop: false);
      expect(controller.state, same(before));
      expect(
        tester
            .widgetList<CandyTile>(find.byType(CandyTile))
            .any((t) => t.ghost),
        isFalse,
      );
    },
  );

  testWidgets(
    'tap selection places at boundaries and refills after all three pieces',
    (tester) async {
      final controller = singles();
      addTearDown(controller.dispose);
      await show(tester, controller, width: 320);
      for (var slot = 0; slot < 3; slot++) {
        await tester.tap(find.byKey(ValueKey('tray-$slot')));
        await tester.pump();
        await tester.tap(find.byKey(ValueKey('cell-7-${7 - slot}')));
        await tester.pump();
        if (slot < 2) expect(controller.state.tray[slot], isNull);
      }
      expect(controller.state.tray.every((piece) => piece != null), isTrue);
      expect(controller.state.board.occupiedCount, 3);
      expect(controller.state.score, 30);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unfitting large shape at edge leaves board and tray unchanged', (
    tester,
  ) async {
    final engine = GameEngine(
      traySource: (_) => [
        pieceCatalog[7],
        pieceCatalog.first,
        pieceCatalog.first,
      ],
    );
    final controller = GameController(engine: engine);
    addTearDown(controller.dispose);
    final before = controller.state;
    await show(tester, controller);
    await drag(tester, 0, 7, 7);
    expect(controller.state, same(before));
  });

  testWidgets(
    'game over shows engine score then retry creates playable empty board',
    (tester) async {
      final engine = GameEngine(
        traySource: (_) => [
          pieceCatalog.first,
          pieceCatalog[7],
          pieceCatalog.last,
        ],
      );
      final board = Board.fromRows([
        for (var row = 0; row < 8; row++)
          [
            for (var col = 0; col < 8; col++)
              (row + col).isOdd ? 'turquoise' : null,
          ],
      ]);
      final controller = GameController(
        engine: engine,
        initialState: GameState(board: board, tray: engine.pickTray(board)),
      );
      addTearDown(controller.dispose);
      await show(tester, controller);
      await tester.tap(find.byKey(const ValueKey('tray-0')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('cell-0-0')));
      await tester.pump();
      expect(controller.isGameOver, isTrue);
      expect(find.text('Piękna układanka!'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/game_over_412.png'),
      );
      await tester.tap(find.text('Zagraj ponownie'));
      await tester.pump();
      expect(controller.state.board.occupiedCount, 0);
      expect(controller.state.score, 0);
      expect(controller.isGameOver, isFalse);
    },
  );

  testWidgets(
    'safe-area drag stays above finger and legal ghost is translucent',
    (tester) async {
      final controller = singles();
      addTearDown(controller.dispose);
      tester.view.padding = const FakeViewPadding(top: 24);
      addTearDown(tester.view.resetPadding);
      await show(tester, controller, width: 320);
      final destination = find.byKey(const ValueKey('cell-2-3'));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('tray-0'))),
      );
      await gesture.moveBy(const Offset(0, -20));
      await gesture.moveTo(tester.getCenter(destination) + const Offset(0, 64));
      await tester.pump();
      final lifted = find.byWidgetPredicate(
        (widget) => widget is Opacity && widget.opacity == .85,
      );
      expect(
        (tester.getTopLeft(lifted) - tester.getTopLeft(destination)).distance,
        lessThan(.01),
      );
      final ghost = find.byWidgetPredicate(
        (widget) => widget is CandyTile && widget.ghost,
      );
      expect(ghost, findsOneWidget);
      expect(
        tester
            .widget<Opacity>(
              find.descendant(of: ghost, matching: find.byType(Opacity)).first,
            )
            .opacity,
        .45,
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/game_ghost_320.png'),
      );
      await gesture.up();
      await tester.pump();
      expect(controller.state.board.at((row: 2, col: 3)), 'candyPink');
    },
  );

  testWidgets(
    'real drag line clear updates score and pending coins from engine',
    (tester) async {
      final board = Board.empty().withCells({
        for (var col = 0; col < 7; col++) (row: 0, col: col): 'turquoise',
      });
      final controller = singles(board: board);
      addTearDown(controller.dispose);
      await show(tester, controller);
      await drag(tester, 0, 0, 7);
      expect(controller.state.score, 110);
      expect(controller.state.totalClearedLines, 1);
      expect(controller.state.board.occupiedCount, 0);
      expect(find.text('110'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    },
  );

  testWidgets(
    'retry uses a fresh production seed while injected runs stay controlled',
    (tester) async {
      var seed = 100;
      final controller = GameController.fresh(seedSource: () => seed++);
      addTearDown(controller.dispose);
      final before = controller.state.rngState;
      controller.restart();
      expect(seed, 102);
      expect(controller.state.rngState, isNot(before));
      expect(controller.state.score, 0);
    },
  );

  testWidgets(
    'small 320x640 screen at text2 remains playable through scrolling',
    (tester) async {
      final controller = singles();
      addTearDown(controller.dispose);
      await show(tester, controller, width: 320, height: 640, scale: 2);
      final tray = find.byKey(const ValueKey('tray-0'));
      await tester.ensureVisible(tray);
      await tester.pumpAndSettle();
      await tester.tap(tray);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('cell-7-7')));
      await tester.pump();
      expect(controller.state.board.at((row: 7, col: 7)), 'candyPink');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a second finger cannot replace or place the active dragged slot',
    (tester) async {
      final controller = singles();
      addTearDown(controller.dispose);
      await show(tester, controller);
      final first = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('tray-0'))),
        pointer: 1,
      );
      await first.moveBy(const Offset(0, -20));
      await first.moveTo(
        tester.getCenter(find.byKey(const ValueKey('cell-1-1'))) +
            const Offset(0, 64),
      );
      await tester.pump();
      final before = controller.state;
      final boardTap = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('cell-4-4'))),
        pointer: 3,
      );
      await boardTap.up();
      await tester.pump();
      expect(controller.state, same(before));
      final second = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('tray-1'))),
        pointer: 2,
      );
      await second.moveBy(const Offset(0, -20));
      await second.moveTo(
        tester.getCenter(find.byKey(const ValueKey('cell-4-4'))) +
            const Offset(0, 64),
      );
      await tester.pump();
      await first.up();
      await tester.pump();
      await second.up();
      await tester.pump();
      expect(controller.state.tray[0], isNull);
      expect(controller.state.tray[1], isNotNull);
      expect(controller.state.board.at((row: 1, col: 1)), 'candyPink');
      expect(controller.state.board.occupiedCount, 1);
    },
  );

  for (final width in [320.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Game fits ${width}dp and text $scale with reduced motion', (
        tester,
      ) async {
        final controller = GameController(engine: GameEngine.seeded(seed: 42));
        addTearDown(controller.dispose);
        await show(
          tester,
          controller,
          width: width,
          scale: scale,
          reduced: true,
        );
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('tray-0')), findsOneWidget);
        if (scale == 1) {
          await expectLater(
            find.byType(Scaffold),
            matchesGoldenFile('goldens/game_${width.toInt()}.png'),
          );
        }
      });
    }
  }
}
