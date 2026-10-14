import 'board.dart';
import 'piece.dart';

class GameState {
  GameState({required this.board, required Iterable<Piece?> tray})
    : tray = List.unmodifiable(tray) {
    if (this.tray.length != traySize ||
        this.tray.every((piece) => piece == null)) {
      throw ArgumentError(
        'A ready state needs 3 slots and at least one piece.',
      );
    }
  }

  static const traySize = 3;
  final Board board;
  final List<Piece?> tray;
}
