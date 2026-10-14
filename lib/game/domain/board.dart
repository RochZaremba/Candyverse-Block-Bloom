import 'cell.dart';

/// Immutable 8×8 board. A null cell is empty; a skin never changes the rules.
class Board {
  Board.empty() : _cells = List<String?>.unmodifiable(List.filled(64, null));

  factory Board.fromRows(Iterable<Iterable<String?>> rows) {
    final copied = rows.map((row) => row.toList()).toList();
    if (copied.length != size || copied.any((row) => row.length != size)) {
      throw ArgumentError('A board must have exactly 8 rows of 8 cells.');
    }
    final cells = copied.expand((row) => row).toList();
    if (cells.any((skin) => skin != null && skin.isEmpty)) {
      throw ArgumentError('Occupied cells need a nonempty skin ID.');
    }
    return Board._(cells);
  }

  Board._(Iterable<String?> cells) : _cells = List.unmodifiable(cells);

  static const size = 8;
  final List<String?> _cells;

  static bool contains(Cell cell) =>
      cell.row >= 0 && cell.row < size && cell.col >= 0 && cell.col < size;

  String? at(Cell cell) {
    if (!contains(cell)) throw RangeError('Cell outside the board: $cell');
    return _cells[cell.row * size + cell.col];
  }

  int get occupiedCount => _cells.where((skin) => skin != null).length;

  /// Copies and validates updates; the original board remains untouched.
  Board withCells(Map<Cell, String?> updates) {
    final cells = _cells.toList();
    for (final entry in updates.entries) {
      if (!contains(entry.key)) throw RangeError('Cell outside the board.');
      if (entry.value != null && entry.value!.isEmpty) {
        throw ArgumentError('Occupied cells need a nonempty skin ID.');
      }
      cells[entry.key.row * size + entry.key.col] = entry.value;
    }
    return Board._(cells);
  }
}
