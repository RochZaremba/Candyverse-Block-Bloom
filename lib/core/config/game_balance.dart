/// Integer-only V1 balance. Changing these values changes deterministic replay.
class GameBalance {
  const GameBalance({
    this.placementPerCell = 10,
    this.lineClear = 100,
    this.multiClearBonus = 40,
    this.crowdedBoardThreshold = 32,
    this.largePieceCells = 4,
    this.crowdedLargeWeightDivisor = 3,
    this.pieceWeights = const {
      'horizontal_1': 6,
      'horizontal_2': 8,
      'horizontal_3': 7,
      'horizontal_4': 4,
      'vertical_2': 8,
      'vertical_3': 7,
      'vertical_4': 4,
      'square_2': 6,
      'l_down': 6,
      'l_up': 6,
      't': 4,
      's': 4,
      'z': 4,
      'square_3': 2,
    },
  });

  final int placementPerCell;
  final int lineClear;
  final int multiClearBonus;
  final int crowdedBoardThreshold;
  final int largePieceCells;
  final int crowdedLargeWeightDivisor;
  final Map<String, int> pieceWeights;

  void validate() {
    if (placementPerCell < 0 ||
        lineClear < 0 ||
        multiClearBonus < 0 ||
        crowdedBoardThreshold < 0 ||
        crowdedBoardThreshold > 64 ||
        largePieceCells < 1 ||
        crowdedLargeWeightDivisor < 1 ||
        pieceWeights.isEmpty ||
        pieceWeights.values.any((weight) => weight < 1)) {
      throw ArgumentError('Invalid game balance.');
    }
  }
}
