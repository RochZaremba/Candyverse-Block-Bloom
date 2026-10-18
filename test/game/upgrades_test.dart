import 'package:candyverse/game/domain/board.dart';
import 'package:candyverse/game/domain/game_action.dart';
import 'package:candyverse/game/domain/game_engine.dart';
import 'package:candyverse/game/domain/game_state.dart';
import 'package:candyverse/game/domain/piece.dart';
import 'package:candyverse/upgrades/domain/upgrade.dart';
import 'package:test/test.dart';

final dot = Piece(id: 'dot', cells: [(row: 0, col: 0)], skin: 'candyPink');
GameEngine engine() => GameEngine(traySource: (_) => [dot, dot, dot]);
GameState state({
  Board? board,
  int lines = 0,
  int pending = 0,
  int sugar = 0,
  int lucky = 0,
  int acquired = 0,
  int uses = 0,
}) => GameState(
  board: board ?? Board.empty(),
  tray: [dot, dot, dot],
  rngState: 1234,
  totalClearedLines: lines,
  pendingUpgradeChoices: pending,
  sugarRushLevel: sugar,
  luckyJellyLevel: lucky,
  eraserAcquired: acquired,
  eraserUses: uses,
);

void main() {
  test('crossing 5, 10 and 15 in one move queues every choice', () {
    final e = engine();
    final board = Board.fromRows(
      List.generate(
        8,
        (r) => List.generate(8, (c) => r == 0 && c == 0 ? null : 'candyPink'),
      ),
    );
    final result = e.placePiece(
      state(board: board, lines: 4),
      PlacePiece(slot: 0, origin: (row: 0, col: 0)),
    );
    expect(result.state.totalClearedLines, 20);
    expect(result.state.pendingUpgradeChoices, 4);
    var next = result.state;
    for (var i = 0; i < 4; i++) {
      expect(next.phase, RunPhase.upgrade);
      expect(next.upgradeChoices.toSet().length, next.upgradeChoices.length);
      next = e.chooseUpgrade(
        next,
        i < 2 ? Upgrade.sugarRush : Upgrade.luckyJelly,
      );
      expect(next.pendingUpgradeChoices, 3 - i);
    }
    expect(next.phase, RunPhase.playing);
    expect(next.sugarRushLevel, 2);
    expect(next.luckyJellyLevel, 2);
  });

  test('seeded card order and queued choices replay from snapshot', () {
    final e = GameEngine.seeded(seed: 19);
    final pending = e.start(legacy: true).copyWith(pendingUpgradeChoices: 3);
    final a = e.resolvePhase(pending);
    final b = GameEngine.seeded(seed: 91).resolvePhase(pending);
    expect(a.upgradeChoices, b.upgradeChoices);
    expect(a.rngState, b.rngState);
    final afterA = e.chooseUpgrade(a, Upgrade.sugarRush);
    final afterB = e.chooseUpgrade(b, Upgrade.sugarRush);
    expect(afterA.upgradeChoices, afterB.upgradeChoices);
    expect(afterA.rngState, afterB.rngState);
    expect(e.resolvePhase(a), same(a));
  });

  test(
    'capped levels and lifetime eraser grants filter and skip exhausted queue',
    () {
      final e = engine();
      var next = e.resolvePhase(
        state(pending: 10, sugar: 2, lucky: 2, acquired: 1),
      );
      expect(next.upgradeChoices, [Upgrade.rainbowEraser]);
      next = e.chooseUpgrade(next, Upgrade.rainbowEraser);
      expect(next.pendingUpgradeChoices, 0);
      expect(next.phase, RunPhase.playing);
      expect(next.eraserUses, 1);
      expect(next.eraserAcquired, 2);
      final erased = e.useEraser(
        next.copyWith(
          board: Board.empty().withCells({(row: 1, col: 1): 'pink'}),
        ),
        (row: 1, col: 1),
      );
      expect(e.availableUpgrades(erased), isEmpty);
    },
  );

  test('Lucky Jelly reward rounds once over total base coins', () {
    expect(state(lines: 1, lucky: 1).pendingCoins, 6);
    expect(state(lines: 3, lucky: 1).pendingCoins, 18);
    expect(state(lines: 3, lucky: 2).pendingCoins, 22);
    expect(state(lines: 0, lucky: 2).pendingCoins, 0);
  });

  test('actual selected Sugar Rush changes next clear points only', () {
    final e = engine();
    final upgrade = e.chooseUpgrade(
      e.resolvePhase(state(pending: 1)),
      Upgrade.sugarRush,
    );
    final board = Board.empty().withCells({
      for (var c = 0; c < 7; c++) (row: 0, col: c): 'pink',
    });
    final cleared = e.placePiece(
      upgrade.copyWith(board: board),
      PlacePiece(slot: 0, origin: (row: 0, col: 7)),
    );
    expect(cleared.scoreDelta, 135);
    expect(cleared.state.pendingCoins, 5);
  });

  test(
    'eraser removes exactly one occupied cell with no points coins or RNG',
    () {
      final e = engine();
      final original = state(
        board: Board.empty().withCells({
          (row: 0, col: 0): 'pink',
          (row: 0, col: 1): 'pink',
        }),
        lines: 7,
        lucky: 1,
        acquired: 2,
        uses: 2,
      ).copyWith(score: 413, streak: 3);
      final next = e.useEraser(original, (row: 0, col: 0));
      expect(next.board.occupiedCount, 1);
      expect(next.eraserUses, 1);
      expect(next.score, 413);
      expect(next.streak, 3);
      expect(next.totalClearedLines, 7);
      expect(next.pendingCoins, original.pendingCoins);
      expect(next.rngState, original.rngState);
    },
  );

  test(
    'no-move offers eraser, escape resumes; decline finalizes base phase',
    () {
      final e = engine();
      final full = Board.fromRows(
        List.generate(8, (_) => List.filled(8, 'pink')),
      );
      final blocked = e.resolvePhase(state(board: full, acquired: 1, uses: 1));
      expect(blocked.phase, RunPhase.needsEraserDecision);
      final escaped = e.useEraser(blocked, (row: 2, col: 2));
      expect(escaped.phase, RunPhase.playing);
      expect(e.declineEraser(blocked).phase, RunPhase.gameOver);
      expect(e.resolvePhase(state(board: full)).phase, RunPhase.gameOver);
    },
  );

  test(
    'unsuccessful rescue consumes usage and returns decision or game over',
    () {
      final e = engine();
      final big = Piece(
        id: 'square',
        cells: [
          (row: 0, col: 0),
          (row: 0, col: 1),
          (row: 1, col: 0),
          (row: 1, col: 1),
        ],
        skin: 'pink',
      );
      final full = Board.fromRows(
        List.generate(8, (_) => List.filled(8, 'pink')),
      );
      final blocked = e.resolvePhase(
        state(
          board: full,
          acquired: 2,
          uses: 2,
        ).copyWith(tray: [big, big, big]),
      );
      final first = e.useEraser(blocked, (row: 0, col: 0));
      expect(first.phase, RunPhase.needsEraserDecision);
      final second = e.useEraser(first, (row: 1, col: 1));
      expect(second.phase, RunPhase.gameOver);
    },
  );

  test(
    'rejected choices erases and modal placements preserve identity and RNG',
    () {
      final e = engine();
      final playing = state();
      expect(e.chooseUpgrade(playing, Upgrade.sugarRush), same(playing));
      expect(e.useEraser(playing, (row: 0, col: 0)), same(playing));
      final pending = e.resolvePhase(state(pending: 1, sugar: 2));
      expect(e.chooseUpgrade(pending, Upgrade.sugarRush), same(pending));
      expect(e.useEraser(pending, (row: -1, col: 0)), same(pending));
      expect(
        e
            .placePiece(pending, PlacePiece(slot: 0, origin: (row: 0, col: 0)))
            .state,
        same(pending),
      );
    },
  );
  for (final milestone in [5, 10, 15]) {
    test('single clear crosses milestone $milestone exactly once', () {
      final e = engine();
      final board = Board.empty().withCells({
        for (var c = 0; c < 7; c++) (row: 0, col: c): 'pink',
      });
      final reached = e
          .placePiece(
            state(board: board, lines: milestone - 1),
            PlacePiece(slot: 0, origin: (row: 0, col: 7)),
          )
          .state;
      expect(reached.pendingUpgradeChoices, 1);
      expect(reached.totalClearedLines, milestone);
      final chosen = e.chooseUpgrade(reached, Upgrade.luckyJelly);
      final placed = e
          .placePiece(chosen, PlacePiece(slot: 1, origin: (row: 1, col: 1)))
          .state;
      expect(placed.phase, RunPhase.playing);
      expect(placed.pendingUpgradeChoices, 0);
      expect(placed.totalClearedLines, milestone);
    });
  }

  test('exhausted upgrades skip future milestone without consuming RNG', () {
    final e = engine();
    final fullLevels = state(
      lines: 29,
      sugar: 2,
      lucky: 2,
      acquired: 2,
      uses: 0,
      board: Board.empty().withCells({
        for (var c = 0; c < 7; c++) (row: 0, col: c): 'pink',
      }),
    );
    final next = e
        .placePiece(fullLevels, PlacePiece(slot: 0, origin: (row: 0, col: 7)))
        .state;
    expect(next.phase, RunPhase.playing);
    expect(next.pendingUpgradeChoices, 0);
    expect(next.rngState, fullLevels.rngState);
  });

  test('queued eraser choice is resolved before no-move decision', () {
    final e = engine();
    final full = Board.fromRows(
      List.generate(8, (_) => List.filled(8, 'pink')),
    );
    final pending = e.resolvePhase(state(board: full, pending: 1));
    expect(pending.phase, RunPhase.upgrade);
    final rescued = e.chooseUpgrade(pending, Upgrade.rainbowEraser);
    expect(rescued.phase, RunPhase.needsEraserDecision);
    expect(rescued.eraserUses, 1);
  });

  test('eraser invalid targets and empty board preserve snapshot', () {
    final e = engine();
    final original = state(acquired: 1, uses: 1);
    for (final cell in [
      (row: -1, col: 0),
      (row: 8, col: 0),
      (row: 0, col: 0),
    ]) {
      expect(e.useEraser(original, cell), same(original));
    }
  });
}
