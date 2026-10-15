import 'dart:convert';

import 'package:candyverse/island/domain/island_state.dart';
import 'package:candyverse/save/domain/app_save.dart';
import 'package:test/test.dart';

IslandState levels(int level, {int stars = 0}) => IslandState(
  levels: {for (final kind in BuildingKind.values) kind: level},
  stars: stars,
);

void main() {
  test('all 30 levels retain introductory prices then grow quadratically', () {
    for (final kind in BuildingKind.values) {
      var save = AppSaveV1(wallet: 10000000);
      var previousPrice = 0;
      for (var level = 0; level < IslandState.maxLevel; level++) {
        final cost = save.price(kind)!;
        expect(cost, greaterThan(previousPrice));
        previousPrice = cost;
        final before = save.wallet;
        save = AppSaveV1.decode(save.purchase(kind).encode());
        expect(save.island.level(kind), level + 1);
        expect(save.wallet, before - cost);
      }
      expect(save.price(kind), isNull);
      expect(identical(save.purchase(kind), save), isTrue);
    }
  });

  test(
    'offline income has no cap and small ticks retain fractional income',
    () {
      var save = AppSaveV1(island: levels(1)).accrueIncome(0);
      for (var second = 1; second <= 60; second++) {
        save = AppSaveV1.decode(save.accrueIncome(second * 1000).encode());
      }
      expect(save.wallet, 1);
      expect(save.incomeRemainder, 0);
      expect(save.accrueIncome(60 * 1000 * 60 * 24 * 365).wallet, 525600);
      expect(AppSaveV1().accrueIncome(0).accrueIncome(86400000).wallet, 0);
    },
  );

  test('prestige bonus keeps tenths and rollback keeps the high watermark', () {
    var save = AppSaveV1(island: levels(1, stars: 1)).accrueIncome(60000);
    save = save.accrueIncome(120000);
    expect(save.wallet, 1);
    expect(save.incomeRemainder, 60000);
    expect(identical(save.accrueIncome(0), save), isTrue);
    expect(save.incomeTimestampMs, 120000);
    save = save.accrueIncome(660000);
    expect(save.wallet, 11);
    expect(save.incomeRemainder, 0);
  });

  test('accrue old rate before building upgrade or prestige', () {
    var save = AppSaveV1(
      wallet: 1000,
      island: IslandState(
        levels: {
          BuildingKind.candyTree: 3,
          BuildingKind.jellyHouse: 0,
          BuildingKind.rainbowFountain: 0,
        },
      ),
    ).accrueIncome(0);
    save = save.accrueIncome(60000).purchase(BuildingKind.jellyHouse);
    expect(save.wallet, 986); // 1000 + one old-rate coin - 15.
    save = save.accrueIncome(120000);
    expect(save.wallet, 988); // Four total levels now yield two/minute.
    var full = AppSaveV1(island: levels(30)).accrueIncome(0);
    full = full.accrueIncome(60000).prestige();
    expect(full.wallet, 30);
    expect(full.accrueIncome(120000).wallet, 30); // Empty new island.
  });

  test(
    'prestige requires all three completed buildings and preserves profile',
    () {
      final incomplete = AppSaveV1(island: levels(29));
      expect(identical(incomplete.prestige(), incomplete), isTrue);
      final save = AppSaveV1(
        wallet: 123,
        bestScore: 77,
        settings: const SavedSettings(language: 'pl', sound: false),
        island: levels(30, stars: 2),
      ).startRun(42).accrueIncome(9000);
      final next = AppSaveV1.decode(save.prestige().encode());
      expect(next.island.stars, 3);
      expect(next.island.totalLevels, 0);
      expect(next.wallet, 123);
      expect(next.bestScore, 77);
      expect(next.settings.language, 'pl');
      expect(next.settings.sound, isFalse);
      expect(next.activeRun!.game.rngState, save.activeRun!.game.rngState);
      expect(next.nextRunId, save.nextRunId);
      expect(next.incomeTimestampMs, 9000);
    },
  );

  test(
    'schema1 migrates losslessly without pre-update income, EN for new only',
    () {
      final legacy = AppSaveV1(
        wallet: 120,
        bestScore: 90,
        island: levels(3),
        settings: const SavedSettings(language: 'pl'),
      ).startRun(58);
      final raw = jsonDecode(legacy.encode()) as Map<String, dynamic>;
      raw['schemaVersion'] = 1;
      raw.remove('incomeTimestampMs');
      raw.remove('incomeRemainder');
      raw.remove('stars');
      var migrated = AppSaveV1.decode(jsonEncode(raw));
      expect(migrated.wallet, 120);
      expect(migrated.island.levels, legacy.island.levels);
      expect(migrated.settings.language, 'pl');
      expect(
        migrated.activeRun!.game.rngState,
        legacy.activeRun!.game.rngState,
      );
      expect(migrated.incomeTimestampMs, isNull);
      migrated = migrated.accrueIncome(999999999999);
      expect(migrated.wallet, 120);
      expect(migrated.incomeRemainder, 0);
      expect(AppSaveV1().settings.language, 'en');
      expect(jsonDecode(migrated.encode())['schemaVersion'], 2);
    },
  );

  test('invalid schema2 economy data is rejected without clamping', () {
    final source = AppSaveV1().encode();
    for (final entry in <String, Object>{
      'stars': -1,
      'incomeRemainder': AppSaveV1.incomeDenominator,
      'incomeTimestampMs': -1,
    }.entries) {
      final value = jsonDecode(source) as Map<String, dynamic>;
      value[entry.key] = entry.value;
      expect(() => AppSaveV1.decode(jsonEncode(value)), throwsFormatException);
    }
  });
}
