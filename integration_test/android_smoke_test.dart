import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:candyverse/app/app.dart';
import 'package:candyverse/core/theme/app_theme.dart';
import 'package:candyverse/game/domain/board.dart';
import 'package:candyverse/game/domain/game_state.dart';
import 'package:candyverse/game/domain/piece.dart';
import 'package:candyverse/game/presentation/game_screen.dart';
import 'package:candyverse/island/domain/island_state.dart';
import 'package:candyverse/save/application/app_session.dart';
import 'package:candyverse/save/data/save_repository.dart';
import 'package:candyverse/save/domain/app_save.dart';
import 'package:candyverse/upgrades/domain/upgrade.dart';

// This target is never imported by lib/. Test fixtures and storage namespace
// cannot become production features or replace the real player's save.
class QaStorage implements SaveStorage {
  final delegate = PreferencesStorage();
  String scoped(String key) => 'candyverse.qa.smoke.$key';
  @override
  Future<String?> read(String key) => delegate.read(scoped(key));
  @override
  Future<void> write(String key, String value) =>
      delegate.write(scoped(key), value);
  @override
  Future<void> remove(String key) => delegate.remove(scoped(key));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android native persistence, six screens and active smoke', (
    tester,
  ) async {
    const minutes = int.fromEnvironment(
      'CANDYVERSE_SMOKE_MINUTES',
      defaultValue: 0,
    );
    final elapsed = Stopwatch()..start();
    final builds = <int>[];
    final rasters = <int>[];
    void timings(List<FrameTiming> frames) {
      for (final frame in frames) {
        builds.add(frame.buildDuration.inMicroseconds);
        rasters.add(frame.rasterDuration.inMicroseconds);
      }
    }

    SchedulerBinding.instance.addTimingsCallback(timings);
    addTearDown(() => SchedulerBinding.instance.removeTimingsCallback(timings));
    final repo = SaveRepository(QaStorage());
    await repo.reset();
    final theme = await AppTheme.load();
    AppSession? session;
    const captureUi = bool.fromEnvironment('CANDYVERSE_CAPTURE_FLUTTER_UI');
    final captureBoundary = GlobalKey();
    Future<void> mount(AppSaveV1 save) async {
      await tester.pumpWidget(const SizedBox());
      await repo.save(save);
      session = AppSession(repo, await repo.load(), seedSource: () => 8);
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureBoundary,
          child: CandyverseApp(theme: theme, session: session!),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> until(bool Function() condition) async {
      final wait = Stopwatch()..start();
      while (!condition()) {
        if (wait.elapsed > const Duration(minutes: 5)) {
          fail('Timed out waiting for native UI/persistence');
        }
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
    }

    Future<void> tap(Finder finder) async {
      debugPrint('QA tap: $finder');
      await until(() => finder.evaluate().isNotEmpty);
      await tester.ensureVisible(finder.first);
      await tester.pump();
      await tester.tap(finder.first);
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> capture(String name) async {
      debugPrint('QA milestone: $name');
      if (!captureUi) return;
      await tester.pump(const Duration(milliseconds: 300));
      // Keep the production SurfaceView intact. Native PixelCopy conversion
      // changes rendering for the entire performance run and crashes this
      // emulator renderer. Separate signed-APK smoke uses actual adb captures.
      final boundary =
          captureBoundary.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(
          pixelRatio: binding.platformDispatcher.views.first.devicePixelRatio,
        );
        try {
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          expect(png, isNotNull);
          binding.reportData ??= <String, dynamic>{};
          binding.reportData!['screenshots'] ??= <dynamic>[];
          (binding.reportData!['screenshots'] as List<dynamic>).add({
            'screenshotName': name,
            'bytes': png!.buffer.asUint8List().toList(),
          });
        } finally {
          image.dispose();
        }
      });
    }

    Future<void> checkpoint() async {
      await until(
        () =>
            tester
                .widget<GameScreen>(find.byType(GameScreen))
                .controller!
                .blocked ==
            false,
      );
    }

    Future<void> leaveGame() async {
      await tap(find.byTooltip('Back to menu'));
      await tap(find.text('Back to menu'));
      await until(() => find.byType(GameScreen).evaluate().isEmpty);
    }

    final dot = pieceCatalog.first;
    final milestone = GameState(
      board: Board.empty().withCells({
        for (var c = 0; c < 7; c++) (row: 0, col: c): 'candyPink',
      }),
      tray: [dot, dot, dot],
      rngState: 2,
      totalClearedLines: 9,
      score: 1500,
      eraserAcquired: 1,
      eraserUses: 1,
    );
    await mount(AppSaveV1(nextRunId: 2, activeRun: SavedRun(1, 2, milestone)));
    await capture('home-pl');
    await tap(find.text('Ustawienia'));
    await tap(find.text('English'));
    await until(() => find.text('Settings').evaluate().isNotEmpty);
    await tap(find.text('Sound'));
    await tap(find.text('Haptics'));
    await tap(find.text('Reduced motion'));
    await session!.flushSettings();
    expect((await repo.load()).settings.language, 'en');
    expect(session!.settings.sound, isFalse);
    expect(session!.settings.haptics, isFalse);
    expect(session!.settings.reduceMotion, isTrue);
    await capture('settings-en');
    await tap(find.byTooltip('Back'));
    await tap(find.text('RESUME'));
    await until(() => find.byType(GameScreen).evaluate().isNotEmpty);
    final controller = tester
        .widget<GameScreen>(find.byType(GameScreen))
        .controller!;
    // Illegal drag and tap leave tray/score unchanged.
    final before = controller.state;
    await tester.ensureVisible(find.byKey(const ValueKey('tray-0')));
    final start = tester.getCenter(find.byKey(const ValueKey('tray-0')));
    final occupied = tester.getCenter(find.byKey(const ValueKey('cell-0-0')));
    final gesture = await tester.startGesture(start);
    await gesture.moveTo(occupied + const Offset(0, 64));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 200));
    expect(controller.state, same(before));
    await tap(find.byKey(const ValueKey('tray-0')));
    await tap(find.byKey(const ValueKey('cell-0-0')));
    expect(controller.state, same(before));
    await tap(find.byKey(const ValueKey('cell-0-7')));
    await checkpoint();
    expect(controller.state.totalClearedLines, 10);
    expect(controller.state.board.occupiedCount, 0);
    await capture('upgrade-en');
    await tap(find.byKey(const ValueKey('upgrade-sugarRush')));
    await checkpoint();
    expect(controller.state.sugarRushLevel, 1);
    await tap(find.byKey(const ValueKey('tray-1')));
    await tap(find.byKey(const ValueKey('cell-1-1')));
    await checkpoint();
    final eraserBefore = controller.state;
    await tap(find.text('Rainbow Eraser (1)'));
    await tap(find.byKey(const ValueKey('cell-1-1')));
    await tap(find.text('Cancel'));
    expect(controller.state, same(eraserBefore));
    await tap(find.byKey(const ValueKey('cell-1-1')));
    await tap(find.text('Erase cell'));
    await checkpoint();
    expect(controller.state.eraserUses, 0);
    expect(controller.state.board.occupiedCount, 0);
    expect(controller.state.score, eraserBefore.score);
    await capture('game-en');
    final snapshot = session!.save.encode();
    await leaveGame();
    await tester.pumpWidget(const SizedBox());
    session = AppSession(repo, await repo.load(), seedSource: () => 8);
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureBoundary,
        child: CandyverseApp(theme: theme, session: session!),
      ),
    );
    await tap(find.text('RESUME'));
    await checkpoint();
    expect(session!.save.encode(), snapshot);

    // Explicit test-only no-move fixture exercises the actual UI award/retry.
    final terminal = GameState(
      board: Board.fromRows([
        for (var r = 0; r < 8; r++)
          [for (var c = 0; c < 8; c++) (r + c).isEven ? 'candyPink' : null],
      ]),
      tray: List.filled(3, pieceCatalog.singleWhere((p) => p.id == 'square_3')),
      rngState: 2,
      totalClearedLines: 50,
      score: 10000,
      sugarRushLevel: 2,
      luckyJellyLevel: 2,
      eraserAcquired: 2,
      eraserUses: 1,
      phase: RunPhase.needsEraserDecision,
    );
    await mount(
      AppSaveV1(
        nextRunId: 2,
        activeRun: SavedRun(1, 2, terminal),
        settings: session!.settings.snapshot,
      ),
    );
    await tap(find.text('RESUME'));
    await tap(find.text('Finish run'));
    await checkpoint();
    expect(session!.save.wallet, 375);
    expect((await repo.load()).lastAwardedRunId, 1);
    await capture('result-en');
    await tap(find.text('Play again'));
    await checkpoint();
    expect(session!.save.activeRun!.id, 2);
    expect(session!.save.wallet, 375);
    await leaveGame();
    await tap(find.text('Visit island'));
    final names = ['Candy Tree', 'Jelly House', 'Rainbow Fountain'];
    for (final kind in BuildingKind.values) {
      for (var level = 1; level <= 3; level++) {
        final cost = session!.save.price(kind)!;
        final wallet = session!.save.wallet;
        await tap(find.text(names[kind.index]));
        await tap(find.text('Upgrade • $cost Candy Coins'));
        await until(
          () => !session!.busy && session!.save.island.level(kind) == level,
        );
        expect(session!.save.wallet, wallet - cost);
        expect((await repo.load()).island.level(kind), level);
      }
    }
    expect(session!.save.wallet, 90);
    for (final character in CandyCharacter.values) {
      await tap(find.byKey(ValueKey('character-${character.name}')));
    }
    await capture('island-en');
    // Animation profiling uses true motion, still with muted optional feedback.
    session!.settings.setReduceMotion(false);
    await session!.flushSettings();
    final systemReducedMotion =
        binding.platformDispatcher.accessibilityFeatures.disableAnimations;
    var moves = 0;
    var reactions = 0;
    var cycles = 0;
    final active = Stopwatch()..start();
    while (active.elapsed < Duration(minutes: minutes)) {
      for (
        var i = 0;
        i < 20 && active.elapsed < Duration(minutes: minutes);
        i++
      ) {
        await tap(
          find.byKey(
            ValueKey('character-${CandyCharacter.values[i % 4].name}'),
          ),
        );
        reactions++;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)),
        );
      }
      await tap(find.byTooltip('Back to menu'));
      await tap(find.text(session!.save.activeRun == null ? 'PLAY' : 'RESUME'));
      for (
        var i = 0;
        i < 20 && active.elapsed < Duration(minutes: minutes);
        i++
      ) {
        final game = tester
            .widget<GameScreen>(find.byType(GameScreen))
            .controller!;
        await checkpoint();
        if (game.isGameOver) {
          await tap(find.text('Play again'));
          await checkpoint();
        } else if (game.state.phase == RunPhase.upgrade) {
          await tap(
            find.byKey(
              ValueKey('upgrade-${game.state.upgradeChoices.first.name}'),
            ),
          );
        } else if (game.state.phase == RunPhase.needsEraserDecision) {
          await tap(find.text('Finish run'));
        } else {
          final slot = game.state.tray.indexWhere(
            (p) =>
                p != null &&
                game.engine.getLegalPlacements(game.state.board, p).isNotEmpty,
          );
          expect(slot, greaterThanOrEqualTo(0));
          final cell = game.engine
              .getLegalPlacements(game.state.board, game.state.tray[slot]!)
              .first;
          await tap(find.byKey(ValueKey('tray-$slot')));
          await tap(find.byKey(ValueKey('cell-${cell.row}-${cell.col}')));
          moves++;
        }
      }
      final game = tester
          .widget<GameScreen>(find.byType(GameScreen))
          .controller!;
      await checkpoint();
      if (game.isGameOver) {
        await tap(find.text('Back to menu'));
      } else {
        await leaveGame();
      }
      await tap(find.text('Visit island'));
      cycles++;
    }
    final activeDwellSeconds = active.elapsed.inSeconds;
    await tap(find.byTooltip('Back to menu'));
    await tap(find.text('Settings'));
    await tap(find.byKey(const Key('reset-data')));
    await tap(find.text('Cancel'));
    expect(session!.save.island.level(BuildingKind.candyTree), 3);
    await tap(find.byKey(const Key('reset-data')));
    await tap(find.byKey(const Key('confirm-reset')));
    await until(() => find.text('GRAJ').evaluate().isNotEmpty);
    expect(session!.save.wallet, 0);
    expect(session!.save.activeRun, isNull);
    expect((await repo.load()).wallet, 0);
    await capture('home-reset-pl');
    int percentile(List<int> samples, double p) {
      if (samples.isEmpty) return 0;
      final sorted = samples.toList()..sort();
      return sorted[((sorted.length - 1) * p).round()];
    }

    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['metrics'] = {
      'elapsedSeconds': elapsed.elapsed.inSeconds,
      'activeDwellSeconds': activeDwellSeconds,
      'requestedActiveMinutes': minutes,
      'dwellMoves': moves,
      'dwellReactions': reactions,
      'dwellCycles': cycles,
      'frameCount': builds.length,
      'systemReducedMotion': systemReducedMotion,
      'buildP95Micros': percentile(builds, .95),
      'rasterP95Micros': percentile(rasters, .95),
      'buildOver16667': builds.where((v) => v > 16667).length,
      'rasterOver16667': rasters.where((v) => v > 16667).length,
      'fixtureProgression': true,
      'captureMethod': captureUi ? 'flutter-repaint-boundary' : 'disabled',
      'representativeHardware': false,
      'softwareRendering': const bool.fromEnvironment(
        'CANDYVERSE_SOFTWARE_RENDERING',
      ),
    };
    await tester.pumpWidget(const SizedBox());
    await repo.reset();
  }, timeout: const Timeout(Duration(hours: 1)));
}
