import 'cell.dart';

class Piece {
  factory Piece({
    required String id,
    required Iterable<Cell> cells,
    String skin = 'candyPink',
  }) {
    final copied = cells.toList();
    if (id.isEmpty || skin.isEmpty || copied.isEmpty) {
      throw ArgumentError('A piece needs an ID, skin and nonempty mask.');
    }
    if (copied.toSet().length != copied.length ||
        copied.any((cell) => cell.row < 0 || cell.col < 0) ||
        !copied.any((cell) => cell.row == 0) ||
        !copied.any((cell) => cell.col == 0)) {
      throw ArgumentError('Piece masks must be unique and normalized.');
    }
    return Piece._(id, copied, skin);
  }

  Piece._(this.id, Iterable<Cell> cells, this.skin)
    : cells = List.unmodifiable(cells);

  final String id;
  final List<Cell> cells;
  final String skin;

  Iterable<Cell> at(Cell origin) => cells.map(
    (cell) => (row: origin.row + cell.row, col: origin.col + cell.col),
  );
}

/// Fixed orientations only; players cannot rotate pieces in V1.
final List<Piece> pieceCatalog = List.unmodifiable([
  for (var length = 1; length <= 4; length++)
    Piece(
      id: 'horizontal_$length',
      cells: [for (var col = 0; col < length; col++) (row: 0, col: col)],
    ),
  for (var length = 2; length <= 4; length++)
    Piece(
      id: 'vertical_$length',
      cells: [for (var row = 0; row < length; row++) (row: row, col: 0)],
    ),
  Piece(
    id: 'square_2',
    cells: [
      for (var r = 0; r < 2; r++)
        for (var c = 0; c < 2; c++) (row: r, col: c),
    ],
  ),
  Piece(
    id: 'l_down',
    cells: [(row: 0, col: 0), (row: 1, col: 0), (row: 1, col: 1)],
  ),
  Piece(
    id: 'l_up',
    cells: [(row: 0, col: 0), (row: 0, col: 1), (row: 1, col: 1)],
  ),
  Piece(
    id: 't',
    cells: [
      (row: 0, col: 0),
      (row: 0, col: 1),
      (row: 0, col: 2),
      (row: 1, col: 1),
    ],
  ),
  Piece(
    id: 's',
    cells: [
      (row: 0, col: 1),
      (row: 0, col: 2),
      (row: 1, col: 0),
      (row: 1, col: 1),
    ],
  ),
  Piece(
    id: 'z',
    cells: [
      (row: 0, col: 0),
      (row: 0, col: 1),
      (row: 1, col: 1),
      (row: 1, col: 2),
    ],
  ),
  Piece(
    id: 'square_3',
    cells: [
      for (var r = 0; r < 3; r++)
        for (var c = 0; c < 3; c++) (row: r, col: c),
    ],
  ),
]);
