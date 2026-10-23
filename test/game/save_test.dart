import 'dart:convert';

import 'package:test/test.dart';
import 'package:candyverse/save/domain/app_save.dart';
import 'package:candyverse/game/domain/game_engine.dart';
import 'package:candyverse/game/domain/board.dart';
import 'package:candyverse/game/domain/game_action.dart';
import 'package:candyverse/upgrades/domain/upgrade.dart';
import 'package:candyverse/island/domain/island_state.dart';

void main() {
  test('snapshot restores exact board, skins and RNG across refill', () {
    var save = AppSaveV1().startRun(45);
    final engine = GameEngine.seeded(seed: 45);
    for (var i = 0; i < 12; i++) {
      final game = save.activeRun!.game;
      final slot = game.tray.indexWhere(
        (p) => p != null && engine.getLegalPlacements(game.board, p).isNotEmpty,
      );
      if (slot < 0) break;
      final origin = engine
          .getLegalPlacements(game.board, game.tray[slot]!)
          .first;
      final restored = AppSaveV1.decode(save.encode());
      final action = PlacePiece(slot: slot, origin: origin);
      final first = engine.placePiece(game, action).state;
      final second = engine.placePiece(restored.activeRun!.game, action).state;
      expect(
        save.checkpoint(1, first).encode(),
        restored.checkpoint(1, second).encode(),
      );
      save = save.checkpoint(1, first);
      if (save.activeRun == null) break;
    }
  });
  test(
    'legacy placement counter survives resume and absent old counter starts at zero',
    () {
      final e = GameEngine.seeded(seed: 45);
      final legacy = e.start(legacy: true).copyWith(legacyMoves: 29);
      final save = AppSaveV1().startRun(45).checkpoint(1, legacy);
      final restored = AppSaveV1.decode(save.encode());
      expect(restored.activeRun!.game.acceptedMoves, 29);
      final game = restored.activeRun!.game;
      final piece = game.tray.first!;
      final next = e
          .placePiece(
            game,
            PlacePiece(
              slot: 0,
              origin: e.getLegalPlacements(game.board, piece).first,
            ),
          )
          .state;
      expect(next.phase, RunPhase.upgrade);
      expect(next.pendingUpgradeChoices, 1);
      final old = jsonDecode(save.encode()) as Map<String, dynamic>;
      (old['activeRun']['game'] as Map).remove('legacyMoves');
      expect(
        AppSaveV1.decode(jsonEncode(old)).activeRun!.game.acceptedMoves,
        0,
      );
      old['activeRun']['game']['legacyMoves'] = -1;
      expect(() => AppSaveV1.decode(jsonEncode(old)), throwsFormatException);
    },
  );
  test('choice queue and eraser counters survive without reroll', () {
    var save = AppSaveV1().startRun(2);
    final engine = GameEngine.seeded(seed: 2);
    final choice = engine.resolvePhase(
      save.activeRun!.game.copyWith(
        totalClearedLines: 10,
        pendingUpgradeChoices: 2,
        eraserAcquired: 1,
      ),
    );
    save = save.checkpoint(1, choice);
    final restored = AppSaveV1.decode(save.encode());
    expect(restored.encode(), save.encode());
    expect(restored.activeRun!.game.upgradeChoices, choice.upgradeChoices);
    expect(restored.activeRun!.game.eraserAcquired, 1);
    expect(restored.activeRun!.game.eraserUses, 0);
  });
  test('reward is rounded once, finalized exactly once and IDs grow', () {
    var save = AppSaveV1().startRun(3);
    final completed = save.activeRun!.game.copyWith(
      score: 1000,
      totalClearedLines: 7,
      luckyJellyLevel: 1,
      phase: RunPhase.gameOver,
    );
    save = save.checkpoint(1, completed);
    expect(save.wallet, 43);
    expect(save.bestScore, 1000);
    expect(save.activeRun, isNull);
    expect(identical(save.completeRun(1), save), isTrue);
    save = AppSaveV1.decode(save.encode());
    expect(save.completeRun(1).wallet, 43);
    save = save.startRun(5);
    expect(save.activeRun!.id, 2);
    expect(save.checkpoint(1, completed).wallet, 43);
    expect(save.completeRun(2).wallet, 43); // Playing cannot finalize.
  });
  test('prices, sequential purchase, insufficient funds and level cap', () {
    var save = AppSaveV1(wallet: 400);
    const prices = [
      [10, 25, 45],
      [15, 30, 50],
      [20, 35, 55],
    ];
    for (final kind in BuildingKind.values) {
      for (var level = 0; level < 3; level++) {
        expect(save.price(kind), prices[kind.index][level]);
        save = AppSaveV1.decode(save.purchase(kind).encode());
        expect(save.island.level(kind), level + 1);
      }
      expect(save.price(kind), greaterThan(prices[kind.index].last));
    }
    expect(save.wallet, 115);
    final poor = AppSaveV1(wallet: 9);
    expect(identical(poor.purchase(BuildingKind.candyTree), poor), isTrue);
  });
  test('ambiguous eraser phase cannot redraw choices during restore', () {
    final save = AppSaveV1().startRun(4);
    final invalid = save.activeRun!.game.copyWith(
      board: Board.fromRows([
        for (var r = 0; r < 8; r++) List.filled(8, 'candyPink'),
      ]),
      totalClearedLines: 5,
      pendingUpgradeChoices: 1,
      eraserAcquired: 1,
      eraserUses: 1,
      phase: RunPhase.needsEraserDecision,
    );
    expect(
      () => AppSaveV1.decode(save.checkpoint(1, invalid).encode()),
      throwsFormatException,
    );
  });
  test('bad schemas, counters, board, masks and RNG are rejected', () {
    final raw =
        jsonDecode(AppSaveV1().startRun(1).encode()) as Map<String, dynamic>;
    for (final mutation in <void Function(Map<String, dynamic>)>[
      (d) => d['schemaVersion'] = 4,
      (d) => d['wallet'] = -1,
      (d) => d['nextRunId'] = 1,
      (d) => d['activeRun']['game']['rng'] = 0,
      (d) => d['activeRun']['game']['board'] = [],
      (d) => d['activeRun']['game']['tray'][0]['id'] = 'unknown',
      (d) => d['activeRun']['game']['tray'][0]['cells'] = [
        [7, 7],
      ],
      (d) => d['activeRun']['game']['tray'][0].remove('cells'),
      (d) => d['activeRun']['game']['eraserUses'] = 1,
      (d) => d['activeRun']['game']['choices'] = ['sugarRush'],
      (d) => d['settings']['sound'] = 'true',
    ]) {
      final d = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
      mutation(d);
      expect(() => AppSaveV1.decode(jsonEncode(d)), throwsFormatException);
    }
  });
}
