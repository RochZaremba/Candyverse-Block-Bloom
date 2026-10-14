import 'package:candyverse/game/domain/board.dart';
import 'package:candyverse/game/domain/cell.dart';
import 'package:candyverse/game/domain/game_action.dart';
import 'package:candyverse/game/domain/game_engine.dart';
import 'package:candyverse/game/domain/game_state.dart';
import 'package:candyverse/game/domain/piece.dart';
import 'package:test/test.dart';

Piece shape(String id) => pieceCatalog.singleWhere((piece) => piece.id == id);
final dot = shape('horizontal_1');
final square = shape('square_2');
Board filled(Iterable<Cell> cells) =>
    Board.empty().withCells({for (final cell in cells) cell: 'mint'});
GameState ready(Board board, [List<Piece?>? tray]) =>
    GameState(board: board, tray: tray ?? [dot, dot, dot]);
PlacePiece move(int slot, int row, int col) =>
    PlacePiece(slot: slot, origin: (row: row, col: col));

void main() {
  late GameEngine engine;
  late int refills;
  late Board? refillBoard;
  setUp(() {
    refills = 0;
    refillBoard = null;
    engine = GameEngine(
      traySource: (board) {
        refills++;
        refillBoard = board;
        return [dot, square, shape('horizontal_2')];
      },
    );
  });

  group('validated immutable models', () {
    test('board is exactly 8×8 with 64 initially empty cells', () {
      final board = Board.empty();
      expect(Board.size, 8);
      expect(board.occupiedCount, 0);
      for (var row = 0; row < 8; row++) {
        for (var col = 0; col < 8; col++) {
          expect(board.at((row: row, col: col)), isNull);
        }
      }
      expect(() => Board.fromRows([]), throwsArgumentError);
      expect(
        () => Board.fromRows(List.generate(8, (_) => List.filled(7, null))),
        throwsArgumentError,
      );
      expect(() => board.at((row: 8, col: 0)), throwsRangeError);
      expect(
        () => board.withCells({(row: -1, col: 0): 'pink'}),
        throwsRangeError,
      );
      expect(
        () => board.withCells({(row: 0, col: 0): ''}),
        throwsArgumentError,
      );
    });

    test('board snapshots do not alias caller rows or updates', () {
      final rows = List.generate(8, (_) => List<String?>.filled(8, null));
      rows[0][0] = 'pink';
      final board = Board.fromRows(rows);
      rows[0][0] = 'blue';
      final updates = {(row: 0, col: 1): 'yellow'};
      final next = board.withCells(updates);
      updates[(row: 0, col: 1)] = 'blue';
      expect(board.at((row: 0, col: 0)), 'pink');
      expect(board.at((row: 0, col: 1)), isNull);
      expect(next.at((row: 0, col: 1)), 'yellow');
      rows[1][1] = '';
      expect(() => Board.fromRows(rows), throwsArgumentError);
    });

    test('invalid piece masks and identifiers are rejected', () {
      for (final cells in <List<Cell>>[
        [],
        [(row: 0, col: 0), (row: 0, col: 0)],
        [(row: -1, col: 0)],
        [(row: 1, col: 0)],
        [(row: 0, col: 1)],
      ]) {
        expect(() => Piece(id: 'bad', cells: cells), throwsArgumentError);
      }
      expect(() => Piece(id: '', cells: dot.cells), throwsArgumentError);
      expect(
        () => Piece(id: 'bad', cells: dot.cells, skin: ''),
        throwsArgumentError,
      );
    });

    test('piece masks and trays are defensively copied and read-only', () {
      final cells = [(row: 0, col: 0)];
      final piece = Piece(id: 'dot', cells: cells);
      cells.add((row: 0, col: 1));
      expect(piece.cells, hasLength(1));
      expect(() => piece.cells.clear(), throwsUnsupportedError);
      final tray = <Piece?>[piece, null, dot];
      final state = ready(Board.empty(), tray);
      tray[0] = null;
      expect(state.tray[0], same(piece));
      expect(() => state.tray[0] = null, throwsUnsupportedError);
      expect(() => ready(Board.empty(), [dot]), throwsArgumentError);
      expect(
        () => ready(Board.empty(), [null, null, null]),
        throwsArgumentError,
      );
    });

    test(
      'catalog has 14 unique normalized masks including required shapes',
      () {
        expect(pieceCatalog, hasLength(14));
        expect(pieceCatalog.map((piece) => piece.id).toSet(), hasLength(14));
        final masks = <String>{};
        for (final piece in pieceCatalog) {
          final cells =
              piece.cells.map((cell) => '${cell.row}:${cell.col}').toList()
                ..sort();
          masks.add(cells.join(','));
          expect(piece.cells.toSet().length, piece.cells.length);
          expect(piece.cells.any((cell) => cell.row == 0), isTrue);
          expect(piece.cells.any((cell) => cell.col == 0), isTrue);
          expect(
            engine.canPlace(Board.empty(), piece, (row: 0, col: 0)),
            isTrue,
          );
        }
        expect(masks, hasLength(14));
        expect(shape('square_3').cells, hasLength(9));
        expect(() => pieceCatalog.clear(), throwsUnsupportedError);
      },
    );
  });

  group('placement and rejection', () {
    test('places entire mask with skin and consumes only selected slot', () {
      final state = ready(Board.empty(), [square, dot, dot]);
      final result = engine.placePiece(state, move(0, 6, 6));
      expect(result.accepted, isTrue);
      expect(result.placedCells, {
        (row: 6, col: 6),
        (row: 6, col: 7),
        (row: 7, col: 6),
        (row: 7, col: 7),
      });
      expect(result.state.board.occupiedCount, 4);
      for (final cell in result.placedCells) {
        expect(result.state.board.at(cell), square.skin);
      }
      expect(result.state.tray, [null, dot, dot]);
      expect(state.board.occupiedCount, 0);
      expect(state.tray[0], same(square));
      expect(result.clear!.lineCount, 0);
      expect(refills, 0);
    });

    test(
      'overlap, all edges, empty and invalid slots preserve exact state',
      () {
        final state = ready(filled([(row: 3, col: 3)]), [square, null, dot]);
        for (final action in [
          move(0, 3, 3),
          move(0, 2, 2),
          move(0, -1, 0),
          move(0, 0, -1),
          move(0, 7, 0),
          move(0, 0, 7),
          move(1, 0, 0),
          move(-1, 0, 0),
          move(3, 0, 0),
        ]) {
          final result = engine.placePiece(state, action);
          expect(result.accepted, isFalse);
          expect(result.state, same(state));
          expect(result.clear, isNull);
          expect(result.placedCells, isEmpty);
          expect(result.refilled, isFalse);
        }
        expect(refills, 0);
        expect(state.board.occupiedCount, 1);
      },
    );

    test('legal placement search includes boundaries and skips collisions', () {
      expect(engine.getLegalPlacements(Board.empty(), dot), hasLength(64));
      expect(engine.getLegalPlacements(Board.empty(), square), hasLength(49));
      final placements = engine.getLegalPlacements(
        filled([(row: 0, col: 0)]),
        square,
      );
      expect(placements, hasLength(48));
      expect(placements, contains((row: 6, col: 6)));
      expect(placements, isNot(contains((row: 0, col: 0))));
      expect(placements, isNot(contains((row: 7, col: 7))));
    });

    test(
      'every catalog shape matches independent geometry over all origins',
      () {
        final board = filled([
          for (var r = 0; r < 8; r++) (row: r, col: (r * 3) % 8),
        ]);
        for (final piece in pieceCatalog) {
          final expected = <Cell>[];
          for (var row = -1; row <= 8; row++) {
            for (var col = -1; col <= 8; col++) {
              final origin = (row: row, col: col);
              final legal = piece.cells.every((offset) {
                final r = row + offset.row;
                final c = col + offset.col;
                return r >= 0 &&
                    r < 8 &&
                    c >= 0 &&
                    c < 8 &&
                    board.at((row: r, col: c)) == null;
              });
              expect(
                engine.canPlace(board, piece, origin),
                legal,
                reason: '${piece.id} at $origin',
              );
              if (legal) expected.add(origin);
            }
          }
          expect(engine.getLegalPlacements(board, piece), expected);
        }
      },
    );
  });

  group('simultaneous line clearing', () {
    for (final horizontal in [true, false]) {
      test(
        'placement completes and clears one ${horizontal ? 'row' : 'column'}',
        () {
          final board = filled([
            for (var i = 0; i < 7; i++)
              horizontal ? (row: 7, col: i) : (row: i, col: 7),
            (row: 0, col: 0),
          ]);
          final result = engine.placePiece(ready(board), move(0, 7, 7));
          expect(result.clear!.lineCount, 1);
          expect(result.clear!.rows, horizontal ? [7] : isEmpty);
          expect(result.clear!.columns, horizontal ? isEmpty : [7]);
          expect(result.clear!.cells, hasLength(8));
          expect(result.state.board.occupiedCount, 1);
          expect(result.state.board.at((row: 0, col: 0)), 'mint');
          expect(board.occupiedCount, 8);
        },
      );
    }

    test('intersection removes 15 unique cells while counting two lines', () {
      final board = filled([
        for (var i = 0; i < 7; i++) (row: 7, col: i),
        for (var i = 0; i < 7; i++) (row: i, col: 7),
      ]);
      final result = engine.placePiece(ready(board), move(0, 7, 7));
      expect(result.clear!.rows, [7]);
      expect(result.clear!.columns, [7]);
      expect(result.clear!.lineCount, 2);
      expect(result.clear!.cells, hasLength(15));
      expect(result.state.board.occupiedCount, 0);
    });

    test(
      'multi-cell placement completes two rows and two columns together',
      () {
        final board = filled([
          for (var row = 0; row < 8; row++)
            for (var col = 0; col < 8; col++)
              if ((row >= 6 || col >= 6) && !(row >= 6 && col >= 6))
                (row: row, col: col),
        ]);
        final result = engine.placePiece(
          ready(board, [square, dot, dot]),
          move(0, 6, 6),
        );
        expect(result.clear!.lineCount, 4);
        expect(result.clear!.rows, [6, 7]);
        expect(result.clear!.columns, [6, 7]);
        expect(result.clear!.cells, hasLength(28));
        expect(result.state.board.occupiedCount, 0);
        expect(() => result.clear!.cells.clear(), throwsUnsupportedError);
      },
    );

    test('full board clears all 16 lines and 64 cells once', () {
      final board = filled([
        for (var r = 0; r < 8; r++)
          for (var c = 0; c < 8; c++) (row: r, col: c),
      ]);
      final clear = engine.clearLines(board);
      expect(clear.lineCount, 16);
      expect(clear.cells, hasLength(64));
      expect(clear.board.occupiedCount, 0);
      expect(board.occupiedCount, 64);
    });
  });

  group('tray lifecycle and game over', () {
    test('start generates exactly three pieces', () {
      final state = engine.start();
      expect(state.tray, [dot, square, shape('horizontal_2')]);
      expect(state.board.occupiedCount, 0);
      expect(refills, 1);
      expect(engine.isGameOver(state), isFalse);
    });

    test('slots stay empty and refill exactly once after the third piece', () {
      var state = ready(Board.empty());
      for (final slot in [2, 0]) {
        final result = engine.placePiece(state, move(slot, 0, slot));
        expect(result.refilled, isFalse);
        expect(result.state.tray[slot], isNull);
        state = result.state;
      }
      expect(state.tray, [null, dot, null]);
      expect(refills, 0);
      final result = engine.placePiece(state, move(1, 0, 1));
      expect(result.refilled, isTrue);
      expect(refills, 1);
      expect(result.state.tray.whereType<Piece>(), hasLength(3));
      expect(refillBoard!.occupiedCount, 3);
    });

    test('refill sees cleared board and new pieces determine game over', () {
      final board = filled([
        for (var col = 0; col < 7; col++) (row: 0, col: col),
      ]);
      final result = engine.placePiece(
        ready(board, [null, dot, null]),
        move(1, 0, 7),
      );
      expect(result.refilled, isTrue);
      expect(refillBoard, same(result.state.board));
      expect(refillBoard!.occupiedCount, 0);
      expect(engine.isGameOver(result.state), isFalse);
    });

    test('only remaining slots count; one playable figure keeps run alive', () {
      final board = filled([
        for (var r = 0; r < 8; r++)
          for (var c = 0; c < 8; c++)
            if ((r + c).isEven) (row: r, col: c),
      ]);
      expect(engine.isGameOver(ready(board, [square, null, null])), isTrue);
      expect(engine.isGameOver(ready(board, [square, null, dot])), isFalse);
      final result = engine.placePiece(
        ready(board, [dot, square, null]),
        move(0, 0, 1),
      );
      expect(result.accepted, isTrue);
      expect(engine.isGameOver(result.state), isTrue);
      expect(refills, 0);
    });

    test(
      'clearing can make a previously blocked remaining figure playable',
      () {
        final board = filled([
          for (var r = 0; r < 8; r++)
            for (var c = 0; c < 8; c++)
              if ((r == 0 && c < 7) || (r > 0 && (r + c).isEven))
                (row: r, col: c),
        ]);
        final longPiece = shape('horizontal_4');
        expect(engine.getLegalPlacements(board, longPiece), isEmpty);
        final result = engine.placePiece(
          ready(board, [dot, longPiece, null]),
          move(0, 0, 7),
        );
        expect(result.clear!.lineCount, 1);
        expect(result.refilled, isFalse);
        expect(engine.isGameOver(result.state), isFalse);
        expect(
          engine.getLegalPlacements(result.state.board, longPiece),
          contains((row: 0, col: 0)),
        );
      },
    );

    test('game over after refill uses new tray, not consumed piece', () {
      final board = filled([
        for (var r = 0; r < 8; r++)
          for (var c = 0; c < 8; c++)
            if ((r + c).isEven) (row: r, col: c),
      ]);
      final blockingEngine = GameEngine(
        traySource: (_) => [square, square, square],
      );
      final result = blockingEngine.placePiece(
        ready(board, [dot, null, null]),
        move(0, 0, 1),
      );
      expect(result.refilled, isTrue);
      expect(blockingEngine.isGameOver(result.state), isTrue);
    });

    test('invalid generator cannot return an empty or partial tray', () {
      for (final pieces in <List<Piece>>[
        [],
        [dot],
        [dot, dot],
        [dot, dot, dot, dot],
      ]) {
        final broken = GameEngine(traySource: (_) => pieces);
        expect(broken.start, throwsStateError);
        final state = ready(Board.empty(), [dot, null, null]);
        expect(() => broken.placePiece(state, move(0, 0, 0)), throwsStateError);
        expect(state.board.occupiedCount, 0);
        expect(state.tray[0], same(dot));
      }
    });
  });
}
