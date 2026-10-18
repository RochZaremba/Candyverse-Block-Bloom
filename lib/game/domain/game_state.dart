import '../../upgrades/domain/evolution.dart';
import '../../upgrades/domain/upgrade.dart';
import 'board.dart';
import 'piece.dart';
import 'random_source.dart';

class GameState {
  GameState({
    required this.board,
    required Iterable<Piece?> tray,
    this.evolution,
    this.score = 0,
    this.streak = 0,
    this.totalClearedLines = 0,
    this.sugarRushLevel = 0,
    this.rngState,
    this.luckyJellyLevel = 0,
    this.eraserAcquired = 0,
    this.eraserUses = 0,
    this.pendingUpgradeChoices = 0,
    this.phase = RunPhase.playing,
    Iterable<Upgrade> upgradeChoices = const [],
  }) : tray = List.unmodifiable(tray),
       upgradeChoices = List.unmodifiable(upgradeChoices) {
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
        sugarRushLevel > 2 ||
        luckyJellyLevel < 0 ||
        luckyJellyLevel > 2 ||
        eraserAcquired < 0 ||
        eraserAcquired > 2 ||
        eraserUses < 0 ||
        eraserUses > eraserAcquired ||
        pendingUpgradeChoices < 0) {
      throw ArgumentError('Invalid run counters or upgrade level.');
    }
    if (this.upgradeChoices.toSet().length != this.upgradeChoices.length ||
        this.upgradeChoices.length > 3 ||
        (phase == RunPhase.upgrade &&
            (pendingUpgradeChoices == 0 || this.upgradeChoices.isEmpty)) ||
        (phase != RunPhase.upgrade && this.upgradeChoices.isNotEmpty)) {
      throw ArgumentError('Invalid upgrade choice phase.');
    }
    if (rngState != null) SeededRandom.fromState(rngState!);
  }

  static const traySize = 3;
  final Evolution? evolution;
  final Board board;
  final List<Piece?> tray;
  final int score;
  final int streak;
  final int totalClearedLines;
  final int sugarRushLevel;
  final int? rngState;
  final int luckyJellyLevel;
  final int eraserAcquired;
  final int eraserUses;
  final int pendingUpgradeChoices;
  final RunPhase phase;
  final List<Upgrade> upgradeChoices;
  int get pendingCoins =>
      5 * totalClearedLines * (4 + luckyJellyLevel) ~/ 4 +
      (evolution?.bonusCoins ?? 0);
  int get nextUpgradeMilestone => (totalClearedLines ~/ 5 + 1) * 5;

  GameState copyWith({
    Evolution? evolution,
    Board? board,
    Iterable<Piece?>? tray,
    int? score,
    int? streak,
    int? totalClearedLines,
    int? sugarRushLevel,
    int? rngState,
    int? luckyJellyLevel,
    int? eraserAcquired,
    int? eraserUses,
    int? pendingUpgradeChoices,
    RunPhase? phase,
    Iterable<Upgrade>? upgradeChoices,
  }) => GameState(
    evolution: evolution ?? this.evolution,
    board: board ?? this.board,
    tray: tray ?? this.tray,
    score: score ?? this.score,
    streak: streak ?? this.streak,
    totalClearedLines: totalClearedLines ?? this.totalClearedLines,
    sugarRushLevel: sugarRushLevel ?? this.sugarRushLevel,
    rngState: rngState ?? this.rngState,
    luckyJellyLevel: luckyJellyLevel ?? this.luckyJellyLevel,
    eraserAcquired: eraserAcquired ?? this.eraserAcquired,
    eraserUses: eraserUses ?? this.eraserUses,
    pendingUpgradeChoices: pendingUpgradeChoices ?? this.pendingUpgradeChoices,
    phase: phase ?? this.phase,
    upgradeChoices: upgradeChoices ?? this.upgradeChoices,
  );
}
