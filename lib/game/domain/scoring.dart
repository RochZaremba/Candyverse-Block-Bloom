import '../../core/config/game_balance.dart';

class MoveScore {
  const MoveScore({required this.points, required this.streak});
  final int points;
  final int streak;
}

MoveScore calculateScore({
  required int placedCells,
  required int clearedLines,
  required int previousStreak,
  int sugarRushLevel = 0,
  GameBalance balance = const GameBalance(),
}) {
  balance.validate();
  if (placedCells < 0 ||
      clearedLines < 0 ||
      previousStreak < 0 ||
      sugarRushLevel < 0 ||
      sugarRushLevel > 2) {
    throw ArgumentError('Invalid scoring input.');
  }
  final streak = clearedLines == 0 ? 0 : previousStreak + 1;
  final extraLines = clearedLines > 0 ? clearedLines - 1 : 0;
  final base =
      balance.lineClear * clearedLines + balance.multiClearBonus * extraLines;
  final comboNumerator = streak == 0 ? 4 : 4 + (streak - 1).clamp(0, 4);
  // Combo and Sugar Rush multiply; floor once after their combined fraction.
  final clearPoints = base * comboNumerator * (4 + sugarRushLevel) ~/ 16;
  return MoveScore(
    points: balance.placementPerCell * placedCells + clearPoints,
    streak: streak,
  );
}
