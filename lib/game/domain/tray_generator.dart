import '../../core/config/game_balance.dart';
import 'board.dart';
import 'piece.dart';
import 'random_source.dart';

/// Weighted selection followed by one fair replacement only when needed.
class TrayGenerator {
  TrayGenerator({
    required this.random,
    GameBalance balance = const GameBalance(),
    List<Piece>? catalog,
  }) : balance = balance,
       catalog = List.unmodifiable(catalog ?? pieceCatalog) {
    balance.validate();
    if (this.catalog.isEmpty ||
        this.catalog.map((piece) => piece.id).toSet().length !=
            this.catalog.length ||
        this.catalog.any(
          (piece) => !balance.pieceWeights.containsKey(piece.id),
        )) {
      throw ArgumentError('Catalog IDs must be unique and configured.');
    }
  }

  final RandomSource random;
  final GameBalance balance;
  final List<Piece> catalog;

  bool _fits(Board board, Piece piece) {
    for (var row = 0; row < Board.size; row++) {
      for (var col = 0; col < Board.size; col++) {
        if (piece
            .at((row: row, col: col))
            .every((cell) => Board.contains(cell) && board.at(cell) == null))
          return true;
      }
    }
    return false;
  }

  int weightFor(Board board, Piece piece) {
    final base = balance.pieceWeights[piece.id]!;
    if (board.occupiedCount >= balance.crowdedBoardThreshold &&
        piece.cells.length >= balance.largePieceCells) {
      return (base ~/ balance.crowdedLargeWeightDivisor).clamp(1, base);
    }
    return base;
  }

  Piece _pick(Board board, List<Piece> candidates) {
    final weights = candidates.map((piece) => weightFor(board, piece)).toList();
    var roll = random.nextInt(weights.fold(0, (a, b) => a + b));
    for (var index = 0; index < candidates.length; index++) {
      if (roll < weights[index]) return candidates[index];
      roll -= weights[index];
    }
    throw StateError('Invalid weighted draw.');
  }

  List<Piece> pickTray(Board board) {
    final tray = [for (var slot = 0; slot < 3; slot++) _pick(board, catalog)];
    if (!tray.any((piece) => _fits(board, piece))) {
      final legal = catalog.where((piece) => _fits(board, piece)).toList();
      if (legal.isNotEmpty) {
        final slot = random.nextInt(tray.length);
        tray[slot] = _pick(board, legal);
      }
    }
    return List.unmodifiable(tray);
  }
}
