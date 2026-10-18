import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:candyverse/save/application/app_session.dart';
import 'package:candyverse/save/data/save_repository.dart';
import 'package:candyverse/save/domain/app_save.dart';
import 'package:candyverse/game/application/game_controller.dart';
import 'package:candyverse/game/domain/board.dart';
import 'package:candyverse/game/domain/game_engine.dart';
import 'package:candyverse/game/domain/game_state.dart';
import 'package:candyverse/game/domain/piece.dart';
import 'package:candyverse/upgrades/domain/upgrade.dart';
import 'package:candyverse/island/domain/island_state.dart';

class ControlledStorage extends MemoryStorage {
  bool fail = false;
  bool failAfterWrite = false;
  Completer<void>? gate;
  @override
  Future<void> write(String key, String value) async {
    if (gate != null) await gate!.future;
    if (fail) throw StateError('write failed');
    await super.write(key, value);
    if (failAfterWrite) throw StateError('acknowledgement interrupted');
  }
}

Future<void> settle() => Future<void>.delayed(Duration.zero);
AppSaveV1 rescueRun() {
  final game = GameState(
    board: Board.fromRows([
      for (var row = 0; row < 8; row++) List.filled(8, 'candyPink'),
    ]),
    tray: List.filled(3, pieceCatalog.first),
    rngState: 2,
    score: 1300,
    totalClearedLines: 7,
    luckyJellyLevel: 1,
    eraserAcquired: 1,
    eraserUses: 1,
    phase: RunPhase.needsEraserDecision,
  );
  return AppSaveV1(nextRunId: 2, activeRun: SavedRun(1, 2, game));
}

void main() {
  test('game-over result waits for write; retry awards exactly once', () async {
    final storage = ControlledStorage();
    final repo = SaveRepository(storage);
    await repo.save(rescueRun());
    final session = AppSession(repo, await repo.load(), seedSource: () => 12);
    final controller = await session.openRun();
    storage.gate = Completer<void>();
    controller.declineEraser();
    expect(controller.saving, isTrue);
    expect(controller.isGameOver, isFalse);
    expect(session.save.wallet, 0);
    await expectLater(session.openRun(), throwsStateError);
    expect(controller.place(0, (row: 0, col: 0)).accepted, isFalse);
    storage.fail = true;
    storage.gate!.complete();
    await settle();
    expect(controller.saveError, isNotNull);
    expect(controller.isGameOver, isFalse);
    expect((await repo.load()).activeRun, isNotNull);
    storage.fail = false;
    storage.gate = null;
    controller.retrySave();
    await settle();
    expect(controller.isGameOver, isTrue);
    expect(session.save.wallet, 43);
    expect((await repo.load()).wallet, 43);
    controller.declineEraser();
    await settle();
    expect(session.save.wallet, 43);
    controller.restart();
    await settle();
    expect(session.save.activeRun!.id, 2);
    expect(controller.state.score, 0);
    expect(controller.state.rngState, session.save.activeRun!.game.rngState);
    session.dispose();
  });
  test(
    'disk commit before interrupted acknowledgement stays idempotent',
    () async {
      final storage = ControlledStorage();
      final repo = SaveRepository(storage);
      await repo.save(rescueRun());
      final session = AppSession(repo, await repo.load());
      final controller = await session.openRun();
      storage.failAfterWrite = true;
      controller.declineEraser();
      await settle();
      expect(controller.saveError, isNotNull);
      expect(session.save.wallet, 0);
      final restarted = await repo.load();
      expect(restarted.wallet, 43);
      expect(restarted.activeRun, isNull);
      storage.failAfterWrite = false;
      controller.retrySave();
      await settle();
      expect(session.save.wallet, 43);
      expect((await repo.load()).wallet, 43);
      session.dispose();
    },
  );
  test(
    'eraser checkpoint restores exact occupancy and lifetime counters',
    () async {
      final repo = SaveRepository(MemoryStorage());
      final session = AppSession(repo, rescueRun());
      final controller = await session.openRun();
      controller.useEraser((row: 0, col: 0));
      await settle();
      final game = (await repo.load()).activeRun!.game;
      expect(game.board.at((row: 0, col: 0)), isNull);
      expect(game.eraserUses, 0);
      expect(game.eraserAcquired, 1);
      expect(game.score, 1300);
      expect(game.pendingCoins, 43);
      expect(game.rngState, 2);
      session.dispose();
    },
  );
  test(
    'failed restart retries allocation, not award or previous snapshot',
    () async {
      final storage = ControlledStorage();
      final repo = SaveRepository(storage);
      final session = AppSession(repo, rescueRun(), seedSource: () => 7);
      final controller = await session.openRun();
      controller.declineEraser();
      await settle();
      storage.fail = true;
      controller.restart();
      await settle();
      expect(controller.saveError, isNotNull);
      expect(session.save.nextRunId, 2);
      storage.fail = false;
      controller.retrySave();
      await settle();
      expect(controller.state.phase, RunPhase.playing);
      expect(session.save.activeRun!.id, 2);
      expect(session.save.wallet, 43);
      session.dispose();
    },
  );
  test(
    'purchase and settings racing with disk preserve committed progression',
    () async {
      final storage = ControlledStorage();
      final repo = SaveRepository(storage);
      final session = AppSession(repo, AppSaveV1(wallet: 40));
      storage.gate = Completer<void>();
      final purchase = session.purchase(BuildingKind.candyTree);
      await settle();
      session.settings.setSound(false);
      expect(session.save.wallet, 40);
      expect(await session.purchase(BuildingKind.candyTree), isFalse);
      storage.gate!.complete();
      expect(await purchase, isTrue);
      await session.flushSettings();
      final reloaded = await repo.load();
      expect(reloaded.wallet, 30);
      expect(reloaded.island.level(BuildingKind.candyTree), 1);
      expect(reloaded.settings.sound, isFalse);
      storage.gate = null;
      storage.fail = true;
      await expectLater(
        session.purchase(BuildingKind.jellyHouse),
        throwsStateError,
      );
      expect(session.save.wallet, 30);
      expect(session.save.island.level(BuildingKind.jellyHouse), 0);
      session.dispose();
    },
  );
  test('accepted move persists and restores in a new session', () async {
    final repo = SaveRepository(MemoryStorage());
    final first = AppSession(repo, AppSaveV1(), seedSource: () => 5);
    final controller = await first.openRun();
    final piece = controller.state.tray.first!;
    final origin = controller.engine
        .getLegalPlacements(controller.state.board, piece)
        .first;
    expect(controller.place(0, origin).accepted, isTrue);
    expect(controller.blocked, isTrue);
    await settle();
    final raw = first.save.encode();
    first.dispose();
    final second = AppSession(repo, await repo.load());
    final resumed = await second.openRun();
    expect(second.save.encode(), raw);
    expect(resumed.state.score, piece.cells.length * 10);
    second.dispose();
  });
  test('resume upgrade preserves generated order and queue', () async {
    final initial = AppSaveV1().startRun(8);
    final engine = GameEngine.seeded(seed: 8);
    final choice = engine.resolvePhase(
      initial.activeRun!.game.copyWith(
        totalClearedLines: 10,
        pendingUpgradeChoices: 2,
      ),
    );
    final repo = SaveRepository(MemoryStorage());
    await repo.save(initial.checkpoint(1, choice));
    final session = AppSession(repo, await repo.load());
    final controller = await session.openRun();
    expect(controller.state.upgradeChoices, choice.upgradeChoices);
    expect(controller.state.rngState, choice.rngState);
    controller.chooseUpgrade(Upgrade.explosiveCandy);
    await settle();
    final saved = await repo.load();
    expect(saved.activeRun!.game.pendingUpgradeChoices, 1);
    expect(saved.activeRun!.game.evolution!.explosive, 1);
    session.dispose();
  });
  test('a fresh Home run after result resets cached game controller', () async {
    final session = AppSession.memory(save: rescueRun());
    final old = await session.openRun();
    old.declineEraser();
    await settle();
    final next = await session.openRun();
    expect(next.state.score, 0);
    expect(next.state.phase, RunPhase.playing);
    expect(session.save.activeRun!.id, 2);
    session.dispose();
  });
  test(
    'disposed controller can finish pending write without notifying',
    () async {
      final gate = Completer<void>();
      final controller = GameController(
        engine: GameEngine.seeded(seed: 4),
        onSnapshot: (_) => gate.future,
      );
      final origin = controller.engine
          .getLegalPlacements(
            controller.state.board,
            controller.state.tray.first!,
          )
          .first;
      controller.place(0, origin);
      controller.dispose();
      gate.complete();
      await settle();
    },
  );
}
