import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:candyverse/save/application/app_session.dart';
import 'package:candyverse/save/data/save_repository.dart';
import 'package:candyverse/save/domain/app_save.dart';
import 'package:candyverse/game/domain/game_state.dart';
import 'package:candyverse/game/domain/board.dart';
import 'package:candyverse/game/domain/piece.dart';
import 'package:candyverse/upgrades/domain/upgrade.dart';

class AckStorage extends MemoryStorage {
  bool failAfterWrite = false;
  Completer<void>? gate;
  int writes = 0;
  @override
  Future<void> write(String key, String value) async {
    writes++;
    final currentGate = gate;
    if (currentGate != null) await currentGate.future;
    await super.write(key, value);
    if (failAfterWrite) throw StateError('acknowledgement interrupted');
  }
}

Future<void> settle() => Future<void>.delayed(Duration.zero);
AppSaveV1 rescue() => AppSaveV1(
  nextRunId: 2,
  activeRun: SavedRun(
    1,
    2,
    GameState(
      board: Board.fromRows([
        for (var r = 0; r < 8; r++) List.filled(8, 'candyPink'),
      ]),
      tray: List.filled(3, pieceCatalog.first),
      rngState: 2,
      totalClearedLines: 7,
      luckyJellyLevel: 1,
      eraserAcquired: 1,
      eraserUses: 1,
      phase: RunPhase.needsEraserDecision,
    ),
  ),
);
void main() {
  test('settings never overwrite disk-committed reward after failed acknowledgement', () async {
    final storage = AckStorage();
    final repo = SaveRepository(storage);
    final session = AppSession(repo, rescue());
    final game = await session.openRun();
    storage.failAfterWrite = true;
    game.declineEraser();
    await settle();
    expect(game.saveError, isNotNull);
    expect((await repo.load()).wallet, 43);
    storage.failAfterWrite = false;
    final writes = storage.writes;
    session.settings.setSound(false);
    session.settings.setLanguage('en');
    await session.flushSettings();
    expect(storage.writes, writes);
    expect((await repo.load()).wallet, 43);
    game.retrySave();
    await settle();
    await session.flushSettings();
    final saved = await repo.load();
    expect(saved.wallet, 43);
    expect(saved.activeRun, isNull);
    expect(saved.settings.sound, isFalse);
    expect(saved.settings.language, 'en');
    expect(game.saveError, isNull);
    session.dispose();
  });
  test(
    'settings changed during a delayed checkpoint flush after success',
    () async {
      final storage = AckStorage();
      final repo = SaveRepository(storage);
      final session = AppSession(repo, rescue());
      final game = await session.openRun();
      storage.gate = Completer<void>();
      game.declineEraser();
      await settle();
      session.settings.setSound(false);
      await session.flushSettings();
      expect(storage.writes, 1);
      storage.gate!.complete();
      storage.gate = null;
      await settle();
      await session.flushSettings();
      expect((await repo.load()).wallet, 43);
      expect((await repo.load()).settings.sound, isFalse);
      expect(storage.writes, 2);
      session.dispose();
    },
  );
  test(
    'settings queued before checkpoint are rechecked at execution',
    () async {
      final storage = AckStorage();
      final repo = SaveRepository(storage);
      final session = AppSession(repo, rescue());
      final game = await session.openRun();
      session.settings.setSound(false);
      storage.failAfterWrite = true;
      game.declineEraser();
      await settle();
      expect(storage.writes, 1);
      expect(game.saveError, isNotNull);
      expect((await repo.load()).wallet, 43);
      expect((await repo.load()).settings.sound, isFalse);
      session.dispose();
    },
  );
  test(
    'reset discards deferred settings and stale checkpoint callbacks',
    () async {
      final storage = AckStorage();
      final repo = SaveRepository(storage);
      final session = AppSession(repo, rescue(), seedSource: () => 5);
      final stale = await session.openRun();
      storage.failAfterWrite = true;
      stale.declineEraser();
      await settle();
      session.settings.setSound(false);
      storage.failAfterWrite = false;
      await session.resetData();
      final next = await session.openRun();
      stale.retrySave();
      await settle();
      await session.flushSettings();
      final saved = await repo.load();
      expect(saved.wallet, 0);
      expect(saved.activeRun!.id, 1);
      expect(saved.activeRun!.game.score, 0);
      expect(saved.settings.sound, isTrue);
      expect(next.state.phase, RunPhase.playing);
      expect(stale.saveError, isNotNull);
      session.dispose();
    },
  );
  test(
    'disposing drops deferred settings without scheduling new writes',
    () async {
      final storage = AckStorage();
      final repo = SaveRepository(storage);
      final session = AppSession(repo, rescue());
      final game = await session.openRun();
      storage.gate = Completer<void>();
      game.declineEraser();
      await settle();
      session.settings.setSound(false);
      session.dispose();
      storage.gate!.complete();
      storage.gate = null;
      await settle();
      expect(storage.writes, 1);
      expect((await repo.load()).wallet, 43);
    },
  );
}
