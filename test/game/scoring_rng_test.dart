import 'package:candyverse/core/config/game_balance.dart';
import 'package:candyverse/game/domain/board.dart';
import 'package:candyverse/game/domain/game_action.dart';
import 'package:candyverse/game/domain/game_engine.dart';
import 'package:candyverse/game/domain/game_state.dart';
import 'package:candyverse/game/domain/piece.dart';
import 'package:candyverse/game/domain/random_source.dart';
import 'package:candyverse/game/domain/scoring.dart';
import 'package:candyverse/game/domain/tray_generator.dart';
import 'package:test/test.dart';

List<String?> trayIds(GameState state) => state.tray.map((p) => p?.id).toList();
List<String?> cells(Board board) => [
  for (var row = 0; row < 8; row++)
    for (var col = 0; col < 8; col++) board.at((row: row, col: col)),
];

void expectSameRun(GameState actual, GameState expected) {
  expect(cells(actual.board), cells(expected.board));
  expect(trayIds(actual), trayIds(expected));
  expect(actual.tray.map((p) => p?.skin), expected.tray.map((p) => p?.skin));
  expect(actual.rngState, expected.rngState);
  expect(actual.score, expected.score);
  expect(actual.streak, expected.streak);
  expect(actual.totalClearedLines, expected.totalClearedLines);
}

void main() {
  group('integer scoring contract', () {
    test('placement, crossing and multi-line bonuses use line count', () {
      expect(
        calculateScore(
          placedCells: 3,
          clearedLines: 0,
          previousStreak: 4,
        ).points,
        30,
      );
      expect(
        calculateScore(
          placedCells: 1,
          clearedLines: 2,
          previousStreak: 0,
        ).points,
        250,
      );
      expect(
        calculateScore(
          placedCells: 9,
          clearedLines: 16,
          previousStreak: 0,
        ).points,
        2290,
      );
    });
    test('combo rises in quarters, caps at x2 and breaks without a clear', () {
      for (var previous = 0; previous < 10; previous++) {
        final result = calculateScore(
          placedCells: 1,
          clearedLines: 1,
          previousStreak: previous,
        );
        expect(result.streak, previous + 1);
        expect(result.points, 10 + 100 * (4 + previous.clamp(0, 4)) ~/ 4);
      }
      final reset = calculateScore(
        placedCells: 4,
        clearedLines: 0,
        previousStreak: 8,
        sugarRushLevel: 2,
      );
      expect(reset.points, 40);
      expect(reset.streak, 0);
    });
    test('Sugar Rush multiplies clear only; floor once after both factors', () {
      // 100 * 5 * 5 / 16 = 156.25: round once to 156, then add placement 10.
      expect(
        calculateScore(
          placedCells: 1,
          clearedLines: 1,
          previousStreak: 1,
          sugarRushLevel: 1,
        ).points,
        166,
      );
      expect(
        calculateScore(
          placedCells: 3,
          clearedLines: 2,
          previousStreak: 4,
          sugarRushLevel: 2,
        ).points,
        750,
      );
      // This distinguishes single rounding from rounding the combo first.
      const odd = GameBalance(lineClear: 101);
      expect(
        calculateScore(
          placedCells: 1,
          clearedLines: 1,
          previousStreak: 1,
          sugarRushLevel: 2,
          balance: odd,
        ).points,
        199,
      );
    });
    test('invalid counts, upgrades and balance fail explicitly', () {
      expect(
        () =>
            calculateScore(placedCells: 1, clearedLines: -1, previousStreak: 0),
        throwsArgumentError,
      );
      expect(
        () =>
            calculateScore(placedCells: 1, clearedLines: 1, previousStreak: -1),
        throwsArgumentError,
      );
      expect(
        () => calculateScore(
          placedCells: 1,
          clearedLines: 1,
          previousStreak: 0,
          sugarRushLevel: 3,
        ),
        throwsArgumentError,
      );
      expect(
        () => GameEngine.seeded(
          seed: 0,
          balance: const GameBalance(placementPerCell: -1),
        ),
        throwsArgumentError,
      );
    });
    test('engine accumulates score lines and streak preserving upgrades', () {
      final one = pieceCatalog.first;
      final engine = GameEngine(traySource: (_) => [one, one, one]);
      final board = Board.empty().withCells({
        for (var col = 0; col < 7; col++) (row: 0, col: col): 'pink',
      });
      final state = GameState(
        board: board,
        tray: [one, one, one],
        score: 1000,
        streak: 1,
        totalClearedLines: 3,
        sugarRushLevel: 1,
      );
      final move = engine.placePiece(
        state,
        const PlacePiece(slot: 0, origin: (row: 0, col: 7)),
      );
      expect(move.scoreDelta, 166);
      expect(move.state.score, 1166);
      expect(move.state.streak, 2);
      expect(move.state.totalClearedLines, 4);
      expect(move.state.sugarRushLevel, 1);
      final next = engine.placePiece(
        move.state,
        const PlacePiece(slot: 1, origin: (row: 2, col: 2)),
      );
      expect(next.state.score, 1176);
      expect(next.state.streak, 0);
      expect(next.state.totalClearedLines, 4);
      expect(state.score, 1000);
    });
  });

  group('serializable RNG', () {
    test(
      'known algorithm sequence is stable and snapshot restores exactly',
      () {
        final rng = SeededRandom.fromState(1);
        rng.nextInt(100);
        expect(rng.state, 16807);
        rng.nextInt(100);
        expect(rng.state, 282475249);
        final restored = SeededRandom.fromState(rng.state);
        for (var i = 0; i < 100; i++) {
          expect(rng.nextInt(73), restored.nextInt(73));
          expect(rng.state, restored.state);
        }
      },
    );
    test('seeds normalize, snapshots and random bounds validate', () {
      for (final seed in [-123, 0, 1, 2147483647]) {
        final rng = SeededRandom(seed);
        for (var i = 0; i < 100; i++) {
          expect(rng.nextInt(17), inInclusiveRange(0, 16));
          expect(rng.state, inInclusiveRange(1, SeededRandom.modulus - 1));
        }
      }
      expect(() => SeededRandom.fromState(0), throwsArgumentError);
      expect(
        () => SeededRandom.fromState(SeededRandom.modulus),
        throwsArgumentError,
      );
      expect(() => SeededRandom(1).nextInt(0), throwsRangeError);
      expect(
        () => SeededRandom(1).nextInt(SeededRandom.modulus),
        throwsRangeError,
      );
    });
  });

  group('weighted fair refill', () {
    test('catalog has positive configured weights and crowding limits large shapes', () {
      final generator = TrayGenerator(random: SeededRandom(9));
      final crowded = Board.empty().withCells({
        for (var row = 0; row < 4; row++)
          for (var col = 0; col < 8; col++) (row: row, col: col): 'pink',
      });
      for (final piece in pieceCatalog) {
        final before = generator.weightFor(Board.empty(), piece);
        final after = generator.weightFor(crowded, piece);
        expect(before, greaterThan(0));
        expect(after, greaterThan(0));
        expect(after, piece.cells.length >= 4 ? lessThan(before) : before);
      }
      expect(
        () => TrayGenerator(
          random: SeededRandom(1),
          balance: const GameBalance(pieceWeights: {'missing': 1}),
        ),
        throwsArgumentError,
      );
    });
    test('all sparse-hole boards include a legal element for 100 seeds', () {
      final engine = GameEngine.seeded(seed: 0);
      for (var hole = 0; hole < 64; hole++) {
        final board = Board.empty().withCells({
          for (var cell = 0; cell < 64; cell++)
            if (cell != hole) (row: cell ~/ 8, col: cell % 8): 'pink',
        });
        for (var seed = 0; seed < 100; seed++) {
          final tray = TrayGenerator(random: SeededRandom(seed))
              .pickTray(board);
          expect(tray.length, 3);
          expect(
            tray.any(
              (piece) => engine.getLegalPlacements(board, piece).isNotEmpty,
            ),
            isTrue,
            reason: 'hole=$hole seed=$seed',
          );
        }
      }
    });
    test(
      'full board produces natural game over without looping or removing cells',
      () {
        final board = Board.empty().withCells({
          for (var row = 0; row < 8; row++)
            for (var col = 0; col < 8; col++) (row: row, col: col): 'pink',
        });
        final tray = TrayGenerator(random: SeededRandom(1)).pickTray(board);
        expect(
          GameEngine.seeded(seed: 1)
              .isGameOver(GameState(board: board, tray: tray)),
          isTrue,
        );
        expect(board.occupiedCount, 64);
      },
    );
    test('weighted draws respect integer bucket boundaries before repair', () {
      final two = pieceCatalog.take(2).toList();
      const balance = GameBalance(
        pieceWeights: {'horizontal_1': 1, 'horizontal_2': 3},
      );
      final random = SequenceRandom([0, 1, 3, 0, 1, 2]);
      final tray = TrayGenerator(
        random: random,
        balance: balance,
        catalog: two,
      ).pickTray(Board.empty());
      expect(tray.map((piece) => piece.id), [
        'horizontal_1',
        'horizontal_2',
        'horizontal_2',
      ]);
      expect(random.calls, 6);
    });
    test(
      'failed initial draw replaces one slot only with a legal weighted piece',
      () {
        final random = SequenceRandom([1, 1, 1, 2, 0, 0, 1, 2]);
        final board = Board.empty().withCells({
          for (var cell = 0; cell < 63; cell++)
            (row: cell ~/ 8, col: cell % 8): 'pink',
        });
        final tray = TrayGenerator(
          random: random,
          catalog: pieceCatalog.take(2).toList(),
          balance: const GameBalance(
            pieceWeights: {'horizontal_1': 1, 'horizontal_2': 3},
          ),
        ).pickTray(board);
        expect(tray.map((piece) => piece.id), [
          'horizontal_2',
          'horizontal_2',
          'horizontal_1',
        ]);
        expect(random.calls, 8);
      },
    );
  });

  test(
    'mutable caller configuration cannot change engine or generator replay',
    () {
      final weights = Map<String, int>.from(const GameBalance().pieceWeights);
      final balance = GameBalance(pieceWeights: weights);
      final engine = GameEngine.seeded(seed: 17, balance: balance);
      final generator = TrayGenerator(
        random: SeededRandom(17),
        balance: balance,
      );
      final expected = engine.start();
      weights.clear();
      expectSameRun(engine.start(), expected);
      expect(generator.pickTray(Board.empty()).length, 3);
      expect(() => engine.balance.pieceWeights.clear(), throwsUnsupportedError);
      expect(
        () => GameEngine.seeded(
          seed: 1,
          balance: const GameBalance(pieceWeights: {'huge': 2147483647}),
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'generated trays use diverse palette skins and preserve catalog masks',
    () {
      final generator = TrayGenerator(random: SeededRandom(17));
      final seenSkins = <String>{};
      for (var draw = 0; draw < 100; draw++) {
        for (final piece in generator.pickTray(Board.empty())) {
          seenSkins.add(piece.skin);
          expect(
            piece.cells,
            pieceCatalog.singleWhere((p) => p.id == piece.id).cells,
          );
        }
      }
      expect(seenSkins, TrayGenerator.skinIds.toSet());
    },
  );

  group('snapshot-driven replay', () {
    test('same seed and actions replay 150 moves including refills', () {
      final engine = GameEngine.seeded(seed: 1234);
      final replica = GameEngine.seeded(seed: 1234);
      var state = engine.start();
      var replay = replica.start();
      expectSameRun(state, replay);
      var refills = 0;
      for (var move = 0; move < 150 && !engine.isGameOver(state); move++) {
        PlacePiece? action;
        for (var slot = 0; slot < 3; slot++) {
          final piece = state.tray[slot];
          if (piece == null) continue;
          final legal = engine.getLegalPlacements(state.board, piece);
          if (legal.isNotEmpty) {
            action = PlacePiece(slot: slot, origin: legal.first);
            break;
          }
        }
        final result = engine.placePiece(state, action!);
        if (result.refilled) refills++;
        state = result.state;
        replay = replica.placePiece(replay, action).state;
        expectSameRun(state, replay);
      }
      expect(refills, greaterThan(2));
    });
    test(
      'restored refill branches ignore intervening calls and constructor seed',
      () {
        final engine = GameEngine.seeded(seed: 99);
        final initial = engine.start();
        final one = pieceCatalog.first;
        final beforeRefill = initial.copyWith(tray: [null, null, one]);
        const action = PlacePiece(slot: 2, origin: (row: 0, col: 0));
        final branch = engine.placePiece(beforeRefill, action);
        expect(branch.refilled, isTrue);
        engine.start();
        engine.pickTray(Board.empty());
        expectSameRun(
          engine.placePiece(beforeRefill, action).state,
          branch.state,
        );
        final restored = GameState(
          board: beforeRefill.board,
          tray: beforeRefill.tray,
          rngState: beforeRefill.rngState,
          score: beforeRefill.score,
        );
        expectSameRun(
          GameEngine.seeded(seed: -999).placePiece(restored, action).state,
          branch.state,
        );
        expect(beforeRefill.rngState, initial.rngState);
      },
    );
    test('rejection preserves identity and does not consume RNG or score', () {
      final engine = GameEngine.seeded(seed: 7);
      final initial = engine.start();
      final rejected = engine.placePiece(
        initial,
        const PlacePiece(slot: 0, origin: (row: -1, col: -1)),
      );
      expect(rejected.state, same(initial));
      expect(rejected.scoreDelta, 0);
      final one = pieceCatalog.first;
      final noRefill = engine.placePiece(
        initial.copyWith(tray: [one, one, one]),
        const PlacePiece(slot: 0, origin: (row: 0, col: 0)),
      );
      expect(noRefill.state.rngState, initial.rngState);
    });
    test(
      'seeded transitions require a snapshot; game-state counters validate',
      () {
        final state = GameState(
          board: Board.empty(),
          tray: [pieceCatalog.first, null, null],
        );
        expect(
          () => GameEngine.seeded(seed: 0).placePiece(
            state,
            const PlacePiece(slot: 0, origin: (row: 0, col: 0)),
          ),
          throwsStateError,
        );
        expect(() => state.copyWith(score: -1), throwsArgumentError);
        expect(() => state.copyWith(rngState: 0), throwsArgumentError);
        expect(() => state.copyWith(sugarRushLevel: 3), throwsArgumentError);
      },
    );
  });
}

class SequenceRandom implements RandomSource {
  SequenceRandom(this.values);
  final List<int> values;
  int calls = 0;
  @override
  int get state => calls + 1;
  @override
  int nextInt(int upperBound) {
    final value = values[calls++];
    expect(value, inInclusiveRange(0, upperBound - 1));
    return value;
  }
}
