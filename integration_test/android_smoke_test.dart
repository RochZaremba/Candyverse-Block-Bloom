import 'package:candyverse/upgrades/domain/evolution.dart';

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrintSynchronously;
import 'package:flutter/scheduler.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:candyverse/app/app.dart';
import 'package:candyverse/core/theme/app_theme.dart';
import 'package:candyverse/core/presentation/kingdom_assets.dart';
import 'package:candyverse/core/presentation/candy_message.dart';
import 'package:candyverse/island/presentation/persistent_island_screen.dart';
import 'package:candyverse/settings/settings_screen.dart';
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
  testWidgets(
    'Android native persistence, six screens and active smoke',
    (tester) async {
      final report = <String, dynamic>{};
      binding.reportData = report;
      await runSmokeScenario(
        tester,
        binding: binding,
        repo: SaveRepository(QaStorage()),
        reportData: report,
        storageKind: 'native-data-store',
        minutes: const int.fromEnvironment(
          'CANDYVERSE_SMOKE_MINUTES',
          defaultValue: 0,
        ),
        captureUi: const bool.fromEnvironment('CANDYVERSE_CAPTURE_FLUTTER_UI'),
        nativeScreenshots: const bool.fromEnvironment(
          'CANDYVERSE_NATIVE_SCREENSHOTS',
        ),
      );
    },
    timeout: const Timeout(Duration(hours: 1)),
  );
}

/// The same UI sequence can validate its assumptions on the host. Only the
/// native entrypoint above exercises Android DataStore and real-time dwell.
Future<void> runSmokeScenario(
  WidgetTester tester, {
  required TestWidgetsFlutterBinding binding,
  required SaveRepository repo,
  required Map<String, dynamic> reportData,
  required String storageKind,
  int minutes = 0,
  int minimumDwellCycles = 0,
  bool captureUi = false,
  bool nativeScreenshots = false,
  Duration uiTimeout = const Duration(minutes: 5),
}) async {
  await tester.runAsync(warmKingdomAssets);
  final elapsed = Stopwatch()..start();
  var qaClock = DateTime.utc(2026, 10, 15);
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
  await repo.reset();
  final theme = await AppTheme.load();
  AppSession? session;
  final captureBoundary = GlobalKey();
  Future<void> mount(AppSaveV1 save) async {
    await tester.pumpWidget(const SizedBox());
    await repo.save(save);
    session = AppSession(
      repo,
      await repo.load(),
      seedSource: () => 8,
      clock: () => qaClock,
    );
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
      if (wait.elapsed > uiTimeout) {
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
    await until(() => finder.hitTestable().evaluate().isNotEmpty);
    await tester.tap(finder.hitTestable().first);
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> capture(String name) async {
    // Async persistence/navigation may mount a route or snackbar at the end of
    // the preceding pump. Advance its transition before asking adb for pixels.
    await tester.pump(const Duration(milliseconds: 400));
    debugPrintSynchronously('QA milestone: $name');
    // Keep this UI stable while the external adb observer captures the real surface.
    if (nativeScreenshots) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 3)),
      );
    }
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
        reportData['screenshots'] ??= <dynamic>[];
        (reportData['screenshots'] as List<dynamic>).add({
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
          find.byType(GameScreen).evaluate().isNotEmpty &&
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
    legacyMoves: 29,
    score: 1500,
    eraserAcquired: 1,
    eraserUses: 1,
  );
  await mount(
    AppSaveV1(
      nextRunId: 2,
      activeRun: SavedRun(1, 2, milestone),
      settings: const SavedSettings(language: 'pl'),
    ),
  );
  await capture('home-pl');
  await tap(find.byKey(const Key('home-settings')));
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
  await tap(find.text('PLAY'));
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
  // An invalid drag keeps its selected piece; select a different slot first
  // so this sequence explicitly selects slot0 instead of toggling it off.
  await tap(find.byKey(const ValueKey('tray-1')));
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
  await tap(find.byKey(const Key('game-eraser')));
  await tap(find.byKey(const ValueKey('cell-1-1')));
  await tap(find.text('Cancel'));
  expect(controller.state, same(eraserBefore));
  await tap(find.byKey(const ValueKey('cell-1-1')));
  await tap(find.text('Erase cell'));
  await checkpoint();
  expect(controller.state.eraserUses, 0);
  expect(controller.state.board.occupiedCount, 0);
  expect(controller.state.score, eraserBefore.score);
  // Keep an occupied cell in the persisted snapshot: an empty board would
  // not detect accidental clearing when navigating through the island.
  await tap(find.byKey(const ValueKey('tray-2')));
  await tap(find.byKey(const ValueKey('cell-2-2')));
  await checkpoint();
  expect(controller.state.board.occupiedCount, 1);
  await capture('game-en');
  final snapshot = session!.save.encode();
  await leaveGame();
  await tester.pumpWidget(const SizedBox());
  session = AppSession(
    repo,
    await repo.load(),
    seedSource: () => 8,
    clock: () => qaClock,
  );
  await tester.pumpWidget(
    RepaintBoundary(
      key: captureBoundary,
      child: CandyverseApp(theme: theme, session: session!),
    ),
  );
  await tap(find.text('PLAY'));
  await checkpoint();
  expect(session!.save.encode(), snapshot);

  // T-020: exercise the new navigation and notices against the native repository.
  final navigationGame = session!.save.activeRun!.game;
  List<String?> cells(GameState game) => [
    for (var r = 0; r < 8; r++)
      for (var c = 0; c < 8; c++) game.board.at((row: r, col: c)),
  ];
  await tap(find.byKey(const Key('game-info')));
  await tap(find.text('Sound and motion'));
  await until(() => find.byType(SettingsScreen).evaluate().isNotEmpty);
  await capture('candy-settings-return');
  await tap(find.byTooltip('Back'));
  await checkpoint();
  expect(cells(session!.save.activeRun!.game), cells(navigationGame));
  await leaveGame();
  for (var tab = 0; tab < 4; tab++) {
    await tap(find.byKey(const Key('home-island')));
    await tap(find.byKey(ValueKey('island-tab-$tab')));
    expect(find.byKey(const Key('island-menu')).hitTestable(), findsOneWidget);
    expect(find.byKey(const Key('island-play')).hitTestable(), findsOneWidget);
    if (tab == 3) await capture('candy-island-map');
    await tap(find.byKey(const Key('island-menu')));
    await until(() => find.byType(PersistentIslandScreen).evaluate().isEmpty);
    expect(find.byType(GameScreen), findsNothing);
  }
  await tap(find.byKey(const Key('home-island')));
  await tap(find.text('COLLECT'));
  await until(() => find.byType(CandyNotice).evaluate().isNotEmpty);
  expect(
    find.text('Income is up to date. Your island earns while you are away.'),
    findsOneWidget,
  );
  await capture('candy-notice-info');
  await tap(find.byTooltip('Dismiss message'));
  await until(() => find.byType(CandyNotice).evaluate().isEmpty);
  await tap(find.byKey(const ValueKey('island-tab-3')));
  await tap(find.byKey(const Key('island-play')));
  await checkpoint();
  await until(() => find.byType(PersistentIslandScreen).evaluate().isEmpty);
  expect(find.byType(PersistentIslandScreen), findsNothing);
  expect(cells(session!.save.activeRun!.game), cells(navigationGame));
  expect(session!.save.activeRun!.game.rngState, navigationGame.rngState);
  expect(session!.save.activeRun!.game.score, navigationGame.score);
  expect(cells((await repo.load()).activeRun!.game), cells(navigationGame));

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
  await tap(find.text('PLAY'));
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
  await tap(find.byKey(const Key('home-island')));
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
      if (kind == BuildingKind.candyTree && level == 1) {
        expect(find.text('Your island is blooming!'), findsOneWidget);
        await capture('candy-notice-success');
      }
      await tap(find.byTooltip('Dismiss message'));
      await until(() => find.byType(CandyNotice).evaluate().isEmpty);
    }
  }
  expect(session!.save.wallet, 90);
  for (final character in CandyCharacter.values) {
    await tap(find.byKey(ValueKey('character-${character.name}')));
  }
  await capture('island-en');
  // Test-only controlled clock verifies native persisted passive income.
  qaClock = qaClock.add(const Duration(minutes: 2));
  expect(await session!.collectIncome(), 6);
  expect(session!.save.wallet, 96);
  expect((await repo.load()).wallet, 96);
  expect(await session!.collectIncome(), 0);
  // High-level fixture avoids weeks of earning without adding a production cheat.
  await mount(
    session!.save.copyWith(
      wallet: 60000,
      island: IslandState(
        levels: {for (final kind in BuildingKind.values) kind: 29},
      ),
    ),
  );
  await tap(find.byKey(const Key('home-island')));
  for (final kind in BuildingKind.values) {
    final cost = session!.save.price(kind)!;
    await tap(find.text(names[kind.index]));
    await tap(find.text('Upgrade • $cost Candy Coins'));
    await until(() => !session!.busy && session!.save.island.level(kind) == 30);
  }
  final beforePrestige = session!.save;
  await tap(find.byKey(const Key('island-prestige')));
  await tap(find.text('Cancel'));
  expect(session!.save.island.canPrestige, isTrue);
  expect(session!.save.island.stars, 0);
  await tap(find.byKey(const Key('island-prestige')));
  await tap(find.text('Discover island'));
  await until(() => !session!.busy && session!.save.island.stars == 1);
  expect(session!.save.island.totalLevels, 0);
  expect(session!.save.wallet, beforePrestige.wallet);
  expect(session!.save.activeRun!.id, beforePrestige.activeRun!.id);
  expect((await repo.load()).island.stars, 1);
  await capture('prestige-world-en');
  // Animation profiling uses true motion, still with muted optional feedback.
  session!.settings.setReduceMotion(false);
  await session!.flushSettings();
  final systemReducedMotion =
      binding.platformDispatcher.accessibilityFeatures.disableAnimations;
  var moves = 0;
  var reactions = 0;
  var cycles = 0;
  final active = Stopwatch()..start();
  bool dwelling() =>
      active.elapsed < Duration(minutes: minutes) ||
      cycles < minimumDwellCycles;
  while (dwelling()) {
    for (var i = 0; i < 20 && dwelling(); i++) {
      await tap(
        find.byKey(ValueKey('character-${CandyCharacter.values[i % 4].name}')),
      );
      reactions++;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
    }
    await tap(find.byTooltip('Back to menu'));
    await tap(find.text('PLAY'));
    for (var i = 0; i < 20 && dwelling(); i++) {
      await checkpoint();
      final game = tester
          .widget<GameScreen>(find.byType(GameScreen))
          .controller!;
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
    await checkpoint();
    final game = tester.widget<GameScreen>(find.byType(GameScreen)).controller!;
    // The final placement of this dwell batch may open a modal card choice.
    // Finish earned choices before trying the deliberately blocked menu button.
    while (game.state.phase == RunPhase.upgrade) {
      await tap(
        find.byKey(ValueKey('upgrade-${game.state.upgradeChoices.first.name}')),
      );
      await checkpoint();
    }
    if (game.state.phase == RunPhase.needsEraserDecision) {
      await tap(find.text('Finish run'));
      await checkpoint();
    }
    if (game.isGameOver) {
      await tap(find.text('Back to menu'));
    } else {
      await leaveGame();
    }
    await tap(find.byKey(const Key('home-island')));
    cycles++;
  }
  final activeDwellSeconds = active.elapsed.inSeconds;
  await tap(find.byTooltip('Back to menu'));
  await tap(find.byKey(const Key('home-settings')));
  await until(() => find.byType(SettingsScreen).evaluate().isNotEmpty);
  await tester.scrollUntilVisible(
    find.byKey(const Key('reset-data')),
    200,
    scrollable: find
        .descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tap(find.byKey(const Key('reset-data')));
  await tap(find.text('Cancel'));
  expect(session!.save.island.stars, 1);
  await tap(find.byKey(const Key('reset-data')));
  await tap(find.byKey(const Key('confirm-reset')));
  await until(() => find.text('PLAY').evaluate().isNotEmpty);
  expect(session!.save.wallet, 0);
  expect(session!.save.activeRun, isNull);
  expect((await repo.load()).wallet, 0);
  await capture('home-reset-en');
  expect((await repo.load()).settings.language, 'en');
  // T-021 fixture: real power inputs, checkpoint and a reconstructed session.
  final evolutionFixture = GameState(
    board: Board.empty().withCells({
      (row: 2, col: 2): 'candyPink',
      (row: 2, col: 3): 'candyPink',
      (row: 3, col: 3): 'lemonYellow',
      (row: 7, col: 7): 'blueberry',
    }),
    tray: [dot, null, pieceCatalog.last],
    rngState: 1234,
    evolution: Evolution(
      explosive: 3,
      rainbow: 3,
      paws: 3,
      moves: 15,
      bombCharges: 2,
      bombs: [18, 27],
    ),
  );
  await mount(
    AppSaveV1(
      nextRunId: 2,
      activeRun: SavedRun(1, 59, evolutionFixture),
      settings: const SavedSettings(language: 'en', reduceMotion: true),
    ),
  );
  await tap(find.byKey(const Key('home-play')));
  await tap(find.byKey(const Key('evolution-rainbow')));
  await tap(find.byKey(const Key('rainbow-slot-2')));
  await tap(find.byKey(const Key('power-color-blueberry')));
  await checkpoint();
  final evolved = (await repo.load()).activeRun!.game;
  expect(evolved.evolution!.rainbowPrimed, isTrue);
  expect(evolved.evolution!.rainbowCooldown, 4);
  expect(evolved.evolution!.synergies.length, 4);
  expect(evolved.tray[2]!.id, isNot(pieceCatalog.last.id));
  expect(evolved.pendingCoins, 2);
  expect(session!.save.wallet, 0);
  await capture('evolution-powers');
  await leaveGame();
  final powerSave = await repo.load();
  await mount(powerSave);
  await tap(find.byKey(const Key('home-play')));
  expect(
    session!.save.activeRun!.game.evolution!.toJson(),
    evolved.evolution!.toJson(),
  );
  expect(session!.save.activeRun!.game.rngState, evolved.rngState);
  await tap(find.byKey(const Key('evolution-bomb')));
  await tap(find.byKey(const Key('power-color-blueberry')));
  await tap(find.byKey(const Key('cell-2-2')));
  expect(find.text('Remove 4 blocks. Charges: 2.'), findsOneWidget);
  await capture('evolution-bomb-preview');
  await tap(find.byKey(const Key('confirm-bomb')));
  await checkpoint();
  final exploded = (await repo.load()).activeRun!.game;
  expect(exploded.board.occupiedCount, 0);
  expect(exploded.evolution!.bombCharges, 0);
  expect(exploded.evolution!.rainbowPrimed, isFalse);
  expect(exploded.pendingCoins, 6);
  expect(exploded.rngState, evolved.rngState);
  expect(session!.save.wallet, 0);
  await capture('evolution-cleared');

  int percentile(List<int> samples, double p) {
    if (samples.isEmpty) return 0;
    final sorted = samples.toList()..sort();
    return sorted[((sorted.length - 1) * p).round()];
  }

  reportData['metrics'] = {
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
    'evolutionPowersVerified': true,
    'evolutionRestoreVerified': true,
    'candyNavigationVerified': true,
    'candyNoticesVerified': true,
    'islandPlayResumesFullBoard': true,
    'settingsReturnPreservesRun': true,
    'fixtureProgression': true,
    'passiveIncomeVerified': true,
    'level30Verified': true,
    'prestigeVerified': true,
    'storageKind': storageKind,
    'runToken': const String.fromEnvironment('CANDYVERSE_QA_RUN_TOKEN'),
    'captureMethod': captureUi
        ? 'flutter-repaint-boundary'
        : nativeScreenshots
        ? 'native-adb-milestone-observer'
        : 'disabled',
    'representativeHardware': false,
    'softwareRendering': const bool.fromEnvironment(
      'CANDYVERSE_SOFTWARE_RENDERING',
    ),
  };
  debugPrintSynchronously(
    'CANDYVERSE_QA_REPORT:${jsonEncode(reportData['metrics'])}',
  );
  await tester.pumpWidget(const SizedBox());
  await repo.reset();
}
