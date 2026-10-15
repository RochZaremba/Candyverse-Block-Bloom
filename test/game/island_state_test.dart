import 'package:candyverse/island/domain/island_state.dart';
import 'package:test/test.dart';

void main() {
  test('island defaults to exactly three unpurchased buildings', () {
    expect(IslandState().levels.values, everyElement(0));
    expect(IslandState().levels, hasLength(3));
  });
  test('levels are bounded immutable snapshots independent of caller maps', () {
    final levels = {for (final kind in BuildingKind.values) kind: 1};
    final state = IslandState(levels: levels);
    levels[BuildingKind.candyTree] = 3;
    expect(state.level(BuildingKind.candyTree), 1);
    expect(
      state.withLevel(BuildingKind.candyTree, 2).level(BuildingKind.candyTree),
      2,
    );
    expect(state.level(BuildingKind.candyTree), 1);
    expect(() => state.levels.clear(), throwsUnsupportedError);
    expect(() => IslandState(levels: {}), throwsArgumentError);
    expect(
      () => state.withLevel(BuildingKind.candyTree, -1),
      throwsArgumentError,
    );
    expect(
      () => state.withLevel(BuildingKind.candyTree, 31),
      throwsArgumentError,
    );
  });
}
