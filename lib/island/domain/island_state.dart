enum BuildingKind { candyTree, jellyHouse, rainbowFountain }

enum CandyCharacter { pinkMochi, blueJelly, lemonBlob, mintyMonster }

/// Pure local visual progression; purchasing belongs to the economy reducer.
class IslandState {
  IslandState({Map<BuildingKind, int>? levels})
    : levels = Map.unmodifiable(
        levels ?? {for (final kind in BuildingKind.values) kind: 0},
      ) {
    if (this.levels.length != BuildingKind.values.length ||
        BuildingKind.values.any((kind) => !this.levels.containsKey(kind)) ||
        this.levels.values.any((level) => level < 0 || level > 3)) {
      throw ArgumentError('Island requires all three building levels in 0..3.');
    }
  }
  final Map<BuildingKind, int> levels;
  int level(BuildingKind kind) => levels[kind]!;
  IslandState withLevel(BuildingKind kind, int level) =>
      IslandState(levels: {...levels, kind: level});
}
