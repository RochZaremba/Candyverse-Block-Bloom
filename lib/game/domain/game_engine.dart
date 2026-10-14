import 'board.dart';
import 'cell.dart';
import 'game_action.dart';
import 'game_state.dart';
import 'piece.dart';

/// T-003 supplies seeded, weighted and fair generation through this boundary.
/// It receives the board AFTER clearing. No generator runs for rejected moves.
typedef TraySource = List<Piece> Function(Board board);

class LineClear {
  LineClear({
    required this.board,
    required Iterable<int> rows,
    required Iterable<int> columns,
    required Iterable<Cell> cells,
  }) : rows = List.unmodifiable(rows),
       columns = List.unmodifiable(columns),
       cells = Set.unmodifiable(cells);

  final Board board;
  final List<int> rows;
  final List<int> columns;
  final Set<Cell> cells;
  int get lineCount => rows.length + columns.length;
}

class PlacementResult {
  PlacementResult._({
    required this.state,
    required this.accepted,
    this.clear,
    Iterable<Cell> placedCells = const [],
    this.refilled = false,
  }) : placedCells = Set.unmodifiable(placedCells);

  final GameState state;
  final bool accepted;
  final LineClear? clear;
  final Set<Cell> placedCells;
  final bool refilled;
}

/// Pure Dart rules. Scoring/RNG (T-003) and eraser decisions (T-006) follow later.
class GameEngine {
  GameEngine({required this.traySource});

  final TraySource traySource;

  GameState start() {
    final board = Board.empty();
    return GameState(board: board, tray: pickTray(board));
  }

  List<Piece> pickTray(Board board) {
    final pieces = List<Piece>.unmodifiable(traySource(board));
    if (pieces.length != GameState.traySize) {
      throw StateError('Tray generation must return exactly 3 pieces.');
    }
    return pieces;
  }

  bool canPlace(Board board, Piece piece, Cell origin) => piece
      .at(origin)
      .every((cell) => Board.contains(cell) && board.at(cell) == null);

  List<Cell> getLegalPlacements(Board board, Piece piece) => List.unmodifiable([
    for (var row = 0; row < Board.size; row++)
      for (var col = 0; col < Board.size; col++)
        if (canPlace(board, piece, (row: row, col: col))) (row: row, col: col),
  ]);

  /// Base game-over rule. T-006 adds the available-eraser exception separately.
  bool isGameOver(GameState state) => !state.tray.whereType<Piece>().any(
    (piece) => getLegalPlacements(state.board, piece).isNotEmpty,
  );

  LineClear clearLines(Board board) {
    final rows = <int>[];
    final columns = <int>[];
    for (var index = 0; index < Board.size; index++) {
      if (List.generate(
        Board.size,
        (col) => board.at((row: index, col: col)),
      ).every((skin) => skin != null)) {
        rows.add(index);
      }
      if (List.generate(
        Board.size,
        (row) => board.at((row: row, col: index)),
      ).every((skin) => skin != null)) {
        columns.add(index);
      }
    }
    final cells = <Cell>{
      for (final row in rows)
        for (var col = 0; col < Board.size; col++) (row: row, col: col),
      for (final col in columns)
        for (var row = 0; row < Board.size; row++) (row: row, col: col),
    };
    return LineClear(
      board: cells.isEmpty
          ? board
          : board.withCells({for (final cell in cells) cell: null}),
      rows: rows,
      columns: columns,
      cells: cells,
    );
  }

  PlacementResult placePiece(GameState state, PlacePiece action) {
    if (action.slot < 0 || action.slot >= GameState.traySize) {
      return PlacementResult._(state: state, accepted: false);
    }
    final piece = state.tray[action.slot];
    if (piece == null || !canPlace(state.board, piece, action.origin)) {
      return PlacementResult._(state: state, accepted: false);
    }
    final placed = piece.at(action.origin).toSet();
    final clear = clearLines(
      state.board.withCells({for (final cell in placed) cell: piece.skin}),
    );
    final tray = state.tray.toList()..[action.slot] = null;
    final refilled = tray.every((piece) => piece == null);
    return PlacementResult._(
      state: GameState(
        board: clear.board,
        tray: refilled ? pickTray(clear.board) : tray,
      ),
      accepted: true,
      clear: clear,
      placedCells: placed,
      refilled: refilled,
    );
  }
}
