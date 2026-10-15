enum BuildingKind { candyTree, jellyHouse, rainbowFountain }

enum CandyCharacter { pinkMochi, blueJelly, lemonBlob, mintyMonster }

/// Pure local visual progression; purchasing belongs to the economy reducer.
class IslandState {
  IslandState({Map<BuildingKind, int>? levels, this.stars = 0})
    : levels = Map.unmodifiable(
        levels ?? {for (final kind in BuildingKind.values) kind: 0},
      ) {
    // Rates are persisted/displayed as native signed integers. Validate the
    // largest reachable rate so later growth can never wrap an accepted save.
    final largestRate =
        BigInt.from(maxLevel) * (BigInt.from(stars) + BigInt.from(10));
    if (largestRate > BigInt.parse('9223372036854775807') ||
        stars < 0 ||
        this.levels.length != BuildingKind.values.length ||
        BuildingKind.values.any((kind) => !this.levels.containsKey(kind)) ||
        this.levels.values.any((level) => level < 0 || level > maxLevel)) {
      throw ArgumentError(
        'Island requires all three building levels in 0..30 and representable non-negative income rates.',
      );
    }
  }
  static const maxLevel = 30;
  final int stars;
  final Map<BuildingKind, int> levels;
  int get totalLevels => levels.values.fold(0, (sum, level) => sum + level);
  bool get canPrestige => levels.values.every((level) => level == maxLevel);
  int get incomeTenthsPerMinute => ((totalLevels + 2) ~/ 3) * (10 + stars);
  IslandState prestige() => canPrestige ? IslandState(stars: stars + 1) : this;
  int level(BuildingKind kind) => levels[kind]!;
  IslandState withLevel(BuildingKind kind, int level) =>
      IslandState(levels: {...levels, kind: level}, stars: stars);
}
