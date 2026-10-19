import 'dart:convert';

import 'package:candyverse/game/domain/board.dart';
import 'package:candyverse/game/domain/game_action.dart';
import 'package:candyverse/game/domain/game_engine.dart';
import 'package:candyverse/game/domain/game_state.dart';
import 'package:candyverse/game/domain/piece.dart';
import 'package:candyverse/save/domain/app_save.dart';
import 'package:candyverse/upgrades/domain/evolution.dart';
import 'package:candyverse/upgrades/domain/upgrade.dart';
import 'package:test/test.dart';

final dot = pieceCatalog.first;
GameEngine engine() => GameEngine(traySource: (_) => [dot, dot, dot]);
GameState run({
  Evolution? e,
  Board? board,
  int lines = 0,
  int streak = 0,
  List<Piece?>? tray,
}) => GameState(
  board: board ?? Board.empty(),
  tray: tray ?? [dot, dot, dot],
  rngState: 1234,
  evolution: e ?? Evolution(),
  totalClearedLines: lines,
  streak: streak,
);
Board full() =>
    Board.fromRows(List.generate(8, (_) => List.filled(8, 'candyPink')));

void main() {
  test('new runs evolve; explicit legacy start retains historical cards', () {
    final e = GameEngine.seeded(seed: 42);
    expect(e.start().evolution, isNotNull);
    expect(e.start(legacy: true).evolution, isNull);
  });
  test('all 12 cards follow prerequisite levels; queue exhausts at 4/4/4', () {
    final e = engine();
    var s = run().copyWith(pendingUpgradeChoices: 12);
    final seen = <Upgrade>{};
    for (var path = 0; path < 3; path++) {
      for (var rank = 1; rank <= 4; rank++) {
        s = e.resolvePhase(s);
        final card = s.upgradeChoices.singleWhere((c) => c.path == path);
        expect(card.rank, rank);
        seen.add(card);
        s = e.chooseUpgrade(s, card);
      }
    }
    expect(seen.length, 12);
    expect(e.availableUpgrades(s), isEmpty);
    expect(s.pendingUpgradeChoices, 0);
    expect(s.phase, RunPhase.playing);
  });
  test(
    'fifth accepted move offers cards, rejection and powers do not advance',
    () {
      final e = engine();
      var s = run(e: Evolution(moves: 4));
      expect(
        e.placePiece(s, PlacePiece(slot: -1, origin: (row: 0, col: 0))).state,
        same(s),
      );
      s = e.placePiece(s, PlacePiece(slot: 0, origin: (row: 0, col: 0))).state;
      expect(s.evolution!.moves, 5);
      expect(s.phase, RunPhase.upgrade);
      expect(s.upgradeChoices.toSet(), {
        Upgrade.explosiveCandy,
        Upgrade.rainbowMagic,
        Upgrade.luckyPaws,
      });
      expect(e.useRainbow(s, 1), same(s));
      expect(e.detonateBomb(s, (row: 0, col: 0)), same(s));
    },
  );
  test(
    'multi-clear and movement thresholds independently queue every earned card',
    () {
      final e = engine();
      final result = e
          .placePiece(
            run(
              e: Evolution(moves: 4),
              board: full().withCells({(row: 0, col: 0): null}),
              lines: 4,
            ),
            PlacePiece(slot: 0, origin: (row: 0, col: 0)),
          )
          .state;
      expect(result.totalClearedLines, 20);
      expect(result.pendingUpgradeChoices, 5);
      expect(result.evolution!.moves, 5);
    },
  );
  test('only cleared rows charge, including carry and level 4 threshold', () {
    final e = engine();
    final rowBoard = Board.empty().withCells({
      for (var c = 0; c < 7; c++) (row: 0, col: c): 'candyPink',
    });
    final charged = e
        .placePiece(
          run(e: Evolution(explosive: 1, rowProgress: 2), board: rowBoard),
          PlacePiece(slot: 0, origin: (row: 0, col: 7)),
        )
        .state
        .evolution!;
    expect(charged.bombCharges, 1);
    expect(charged.rowProgress, 0);
    expect(charged.bombs, isEmpty); // charge survives an empty board
    final colBoard = Board.empty().withCells({
      for (var r = 0; r < 7; r++) (row: r, col: 0): 'candyPink',
    });
    final col = e
        .placePiece(
          run(e: Evolution(explosive: 1, rowProgress: 2), board: colBoard),
          PlacePiece(slot: 0, origin: (row: 7, col: 0)),
        )
        .state
        .evolution!;
    expect(col.bombCharges, 0);
    expect(col.rowProgress, 2);
    final nova = e
        .placePiece(
          run(e: Evolution(explosive: 4, rowProgress: 1), board: rowBoard),
          PlacePiece(slot: 0, origin: (row: 0, col: 7)),
        )
        .state
        .evolution!;
    expect(nova.bombCharges, 1);
  });
  test(
    'cross and square blast geometry clips to edges; preview equals execution',
    () {
      final e = engine();
      for (final level in [1, 2]) {
        final s = run(
          e: Evolution(explosive: level, bombCharges: 1),
          board: full(),
        );
        final center = e.previewBomb(s, (row: 3, col: 3));
        expect(center.cells.length, level == 1 ? 5 : 9);
        expect(
          e.previewBomb(s, (row: 0, col: 0)).cells.length,
          level == 1 ? 3 : 4,
        );
        final after = e.detonateBomb(s, (row: 3, col: 3));
        expect(after.board.occupiedCount, 64 - center.cells.length);
        expect(after.score, s.score);
        expect(after.pendingCoins, 0);
        expect(after.totalClearedLines, 0);
        expect(after.evolution!.bombCharges, 0);
        expect(after.evolution!.moves, 0);
      }
    },
  );
  test(
    'L3 chained bomb union terminates, consumes charges, scores each cell once',
    () {
      final e = engine();
      final s = run(
        e: Evolution(
          explosive: 3,
          paws: 2,
          bombCharges: 3,
          bombs: [18, 27, 36],
        ),
        board: full(),
      );
      final blast = e.previewBomb(s, (row: 2, col: 2));
      expect(blast.chargesUsed, 3);
      expect(blast.cells, contains((row: 5, col: 5)));
      final after = e.detonateBomb(s, (row: 2, col: 2));
      expect(after.evolution!.bombCharges, 0);
      expect(after.evolution!.bombs, isEmpty);
      expect(after.pendingCoins, blast.cells.length);
    },
  );
  test(
    'Rainbow Explosion primes through reroll, selected color joins chain once',
    () {
      final e = engine();
      final board = full().withCells({(row: 7, col: 7): 'turquoise'});
      final s = run(
        e: Evolution(explosive: 3, rainbow: 3, paws: 2, bombCharges: 1),
        board: board,
      );
      final swapped = e.useRainbow(s, 1, color: 'turquoise');
      expect(swapped.tray[1]!.id, isNot(s.tray[1]!.id));
      expect(swapped.tray[1]!.skin, 'turquoise');
      expect(swapped.evolution!.rainbowPrimed, isTrue);
      expect(swapped.pendingCoins, 2); // Lucky Spectrum
      expect(e.detonateBomb(swapped, (row: 0, col: 0)), same(swapped));
      final preview = e.previewBomb(swapped, (
        row: 0,
        col: 0,
      ), color: 'turquoise');
      expect(preview.cells.length, 5);
      expect(preview.cells, contains((row: 7, col: 7)));
      final after = e.detonateBomb(swapped, (
        row: 0,
        col: 0,
      ), color: 'turquoise');
      expect(after.pendingCoins, 7);
      expect(after.evolution!.rainbowPrimed, isFalse);
    },
  );
  test('rainbow replay is independent of constructor seed; cooldown uses placements', () {
    final e = GameEngine.seeded(seed: 71);
    final s = run(e: Evolution(rainbow: 1));
    final a = e.useRainbow(s, 2);
    final b = GameEngine.seeded(seed: 900).useRainbow(s, 2);
    expect(a.tray[2]!.id, b.tray[2]!.id);
    expect(a.rngState, b.rngState);
    expect(a.evolution!.rainbowCooldown, 6);
    expect(e.useRainbow(a, 2), same(a));
    final moved = e
        .placePiece(a, PlacePiece(slot: 0, origin: (row: 0, col: 0)))
        .state;
    expect(moved.evolution!.rainbowCooldown, 5);
    final pending = e.resolvePhase(a.copyWith(pendingUpgradeChoices: 1));
    final faster = e.chooseUpgrade(pending, Upgrade.quickMagic);
    expect(faster.evolution!.rainbowCooldown, 4);
  });
  test('no-space rescue offers a fitting different shape, full board cannot reroll-save', () {
    final e = engine();
    final big = pieceCatalog.last;
    final almost = full().withCells({(row: 7, col: 7): null});
    final s = e.resolvePhase(
      run(e: Evolution(rainbow: 1), board: almost, tray: [big, big, big]),
    );
    expect(s.phase, RunPhase.needsEraserDecision);
    final rescue = e.useRainbow(s, 1);
    expect(rescue.tray[1]!.id, 'horizontal_1');
    expect(rescue.phase, RunPhase.playing);
    expect(
      e.resolvePhase(run(e: Evolution(rainbow: 1), board: full())).phase,
      RunPhase.gameOver,
    );
    final bomb = e.resolvePhase(
      run(e: Evolution(explosive: 1, bombCharges: 1), board: full()),
    );
    expect(bomb.phase, RunPhase.needsEraserDecision);
    expect(e.detonateBomb(bomb, (row: 0, col: 0)).phase, RunPhase.playing);
  });
  test('Paws combo rewards, Constellation recharge and reset boundaries', () {
    final e = engine();
    final rowBoard = Board.empty().withCells({
      for (var c = 0; c < 7; c++) (row: 0, col: c): 'candyPink',
    });
    final s = run(
      e: Evolution(explosive: 3, rainbow: 3, paws: 4),
      board: rowBoard,
      lines: 1,
      streak: 1,
    );
    final result = e.placePiece(
      s,
      PlacePiece(slot: 0, origin: (row: 0, col: 7)),
    );
    expect(result.scoreDelta, 10 + 125 + 160);
    expect(result.state.pendingCoins, 10 + 8 + 2);
    expect(result.state.evolution!.bombCharges, 1);
    final miss = e
        .placePiece(result.state, PlacePiece(slot: 1, origin: (row: 1, col: 1)))
        .state;
    expect(miss.streak, 0);
    expect(miss.evolution!.bonusCoins, 10);
  });
  test(
    'save/restoration preserves choice, charge, cooldown, priming and RNG',
    () {
      final e = GameEngine.seeded(seed: 82);
      var profile = AppSaveV1(wallet: 15).startRun(82);
      final s = e.resolvePhase(
        run(
          e: Evolution(
            explosive: 3,
            rainbow: 3,
            paws: 3,
            moves: 15,
            bombCharges: 2,
            bombs: [0],
            rainbowCooldown: 2,
            rainbowPrimed: true,
            bonusCoins: 27,
          ),
          board: Board.empty().withCells({(row: 0, col: 0): 'candyPink'}),
        ).copyWith(pendingUpgradeChoices: 2),
      );
      profile = profile.checkpoint(1, s);
      final restored = AppSaveV1.decode(profile.encode());
      expect(restored.encode(), profile.encode());
      expect(restored.activeRun!.game.upgradeChoices, s.upgradeChoices);
      expect(restored.wallet, 15);
      final chosen = e.chooseUpgrade(s, s.upgradeChoices.first);
      final replay = e.chooseUpgrade(
        restored.activeRun!.game,
        s.upgradeChoices.first,
      );
      expect(replay.evolution!.toJson(), chosen.evolution!.toJson());
      expect(replay.rngState, chosen.rngState);
    },
  );
  test('bonus reward is finalized once across restart, no wallet gain before finish', () {
    var p = AppSaveV1(wallet: 10).startRun(8);
    final finished = run(
      e: Evolution(paws: 2, bonusCoins: 17),
      board: full(),
      lines: 2,
    ).copyWith(phase: RunPhase.gameOver);
    p = p.checkpoint(1, finished);
    expect(p.wallet, 37);
    expect(p.lastResult!.bonusCoins, 17);
    final restored = AppSaveV1.decode(p.encode());
    expect(restored.completeRun(1).wallet, 37);
    expect(restored.startRun(100).activeRun!.game.evolution!.bonusCoins, 0);
  });
  for (final version in [1, 2]) {
    test('schema$version migrates without changing legacy run or RNG', () {
      var p = AppSaveV1(wallet: 25).startRun(23);
      final legacy = GameEngine.seeded(seed: 23).start(legacy: true);
      p = p.checkpoint(1, legacy);
      final d = jsonDecode(p.encode()) as Map<String, dynamic>;
      d['schemaVersion'] = version;
      (d['activeRun']['game'] as Map).remove('evolution');
      final restored = AppSaveV1.decode(jsonEncode(d));
      expect(restored.activeRun!.game.evolution, isNull);
      expect(restored.activeRun!.game.rngState, legacy.rngState);
      expect(restored.wallet, 25);
      expect(
        GameEngine.seeded(seed: 23).availableUpgrades(restored.activeRun!.game),
        [Upgrade.sugarRush, Upgrade.luckyJelly, Upgrade.rainbowEraser],
      );
      expect(jsonDecode(restored.encode())['schemaVersion'], 3);
    });
  }
  test(
    'path upgrades preserve accrued rows and clamp a running rainbow cooldown',
    () {
      final e = engine();
      final s = run(
        e: Evolution(
          explosive: 3,
          rainbow: 1,
          rowProgress: 2,
          rainbowCooldown: 5,
        ),
        board: Board.empty().withCells({(row: 0, col: 0): 'candyPink'}),
      );
      final pending = e.resolvePhase(s.copyWith(pendingUpgradeChoices: 2));
      final nova = e.chooseUpgrade(pending, Upgrade.sugarNova);
      expect(nova.evolution!.bombCharges, 1);
      expect(nova.evolution!.bombs, [0]);
      expect(nova.evolution!.rowProgress, 0);
      final quick = e.chooseUpgrade(nova, Upgrade.quickMagic);
      expect(quick.evolution!.rainbowCooldown, 4);
    },
  );
  test('malformed counters, markers and unsupported saves are rejected', () {
    for (final modify in <void Function(Map<String, dynamic>)>[
      (d) => d['explosive'] = 5,
      (d) => d['bombCharges'] = -1,
      (d) => d['bombs'] = [64],
      (d) => d['rainbowPrimed'] = true,
      (d) => d['moves'] = 1.5,
      (d) => d['rainbowCooldown'] = 7,
    ]) {
      final d = Map<String, dynamic>.from(Evolution().toJson());
      modify(d);
      expect(() => Evolution.fromJson(d), throwsA(anything));
    }
    final data = jsonDecode(AppSaveV1().startRun(23).encode());
    data['activeRun']['game']['evolution']['bombCharges'] = 1;
    data['activeRun']['game']['evolution']['explosive'] = 1;
    data['activeRun']['game']['evolution']['bombs'] = [0];
    expect(() => AppSaveV1.decode(jsonEncode(data)), throwsFormatException);
  });
}
