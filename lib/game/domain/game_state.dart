import 'board.dart';
import 'piece.dart';
import 'random_source.dart';

class GameState {
  GameState({
    required this.board,
    required Iterable<Piece?> tray,
    this.score = 0,
    this.streak = 0,
    this.totalClearedLines = 0,
    this.sugarRushLevel = 0,
    this.rngState,
  }) : tray = List.unmodifiable(tray) {
    if (this.tray.length != traySize ||
        this.tray.every((piece) => piece == null)) {
      throw ArgumentError(
        'A ready state needs 3 slots and at least one piece.',
      );
    }
    if (score < 0 ||
        streak < 0 ||
        totalClearedLines < 0 ||
        sugarRushLevel < 0 ||
        sugarRushLevel > 2) {
      throw ArgumentError('Invalid run counters or upgrade level.');
    }
    if (rngState != null) SeededRandom.fromState(rngState!);
  }

  static const traySize = 3;
  final Board board;
  final List<Piece?> tray;
  final int score;
  final int streak;
  final int totalClearedLines;
  final int sugarRushLevel;
  final int? rngState;

  GameState copyWith({
    Board? board,
    Iterable<Piece?>? tray,
    int? score,
    int? streak,
    int? totalClearedLines,
    int? sugarRushLevel,
    int? rngState,
  }) => GameState(
    board: board ?? this.board,
    tray: tray ?? this.tray,
    score: score ?? this.score,
    streak: streak ?? this.streak,
    totalClearedLines: totalClearedLines ?? this.totalClearedLines,
    sugarRushLevel: sugarRushLevel ?? this.sugarRushLevel,
    rngState: rngState ?? this.rngState,
  );
}
