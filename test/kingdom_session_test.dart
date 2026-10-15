import 'package:candyverse/island/domain/island_state.dart';
import 'package:candyverse/save/application/app_session.dart';
import 'package:candyverse/save/data/save_repository.dart';
import 'package:candyverse/save/domain/app_save.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

class InterruptedStorage extends MemoryStorage {
  bool interrupt = false;
  bool failBeforeWrite = false;
  @override
  Future<void> write(String key, String value) async {
    if (failBeforeWrite) throw StateError('disk unavailable');
    await super.write(key, value);
    if (interrupt) throw StateError('lost acknowledgement');
  }
}

IslandState levels(int level, {int stars = 0}) => IslandState(
  levels: {for (final kind in BuildingKind.values) kind: level},
  stars: stars,
);

void main() {
  test(
    'income retry after lost acknowledgement keeps exact target and timestamp',
    () async {
      var time = DateTime.fromMillisecondsSinceEpoch(60000);
      final storage = InterruptedStorage();
      final repository = SaveRepository(storage);
      final initial = AppSaveV1(island: levels(1)).accrueIncome(0);
      await repository.save(initial);
      final session = AppSession(repository, initial, clock: () => time);
      addTearDown(session.dispose);
      storage.interrupt = true;
      await expectLater(session.collectIncome(), throwsStateError);
      expect(session.save.wallet, 0);
      expect(session.incomeNeedsRetry, isTrue);
      final written = storage.values[SaveRepository.key];
      expect((await repository.load()).wallet, 1);
      time = DateTime.fromMillisecondsSinceEpoch(180000);
      storage.interrupt = false;
      expect(await session.collectIncome(), 1);
      expect(session.save.encode(), written);
      expect(session.incomeNeedsRetry, isFalse);
      expect(await session.collectIncome(), 2);
      expect(session.save.wallet, 3);
      final restored = AppSession(
        repository,
        await repository.load(),
        clock: () => time,
      );
      addTearDown(restored.dispose);
      expect(await restored.collectIncome(), 0);
      expect(restored.save.wallet, 3);
    },
  );

  test(
    'purchase retries do not buy another level and other mutations wait',
    () async {
      var time = DateTime.fromMillisecondsSinceEpoch(60000);
      final storage = InterruptedStorage();
      final repo = SaveRepository(storage);
      final session = AppSession(
        repo,
        AppSaveV1(wallet: 100, island: levels(1)).accrueIncome(0),
        clock: () => time,
      );
      addTearDown(session.dispose);
      storage.interrupt = true;
      await expectLater(
        session.purchase(BuildingKind.candyTree),
        throwsStateError,
      );
      expect(session.save.island.level(BuildingKind.candyTree), 1);
      final disk = (await repo.load()).encode();
      await expectLater(session.prestige(), throwsStateError);
      await expectLater(session.openRun(), throwsStateError);
      time = DateTime.fromMillisecondsSinceEpoch(600000);
      storage.interrupt = false;
      expect(await session.purchase(BuildingKind.candyTree), isTrue);
      expect(session.save.island.level(BuildingKind.candyTree), 2);
      expect(session.save.wallet, 76); // old income + 100 - second-level25
      expect(session.save.encode(), disk);
    },
  );

  test('prestige is durable once, does not replace run, and empty island earns zero', () async {
    var time = DateTime.fromMillisecondsSinceEpoch(60000);
    final storage = InterruptedStorage();
    final repo = SaveRepository(storage);
    final session = AppSession(
      repo,
      AppSaveV1(wallet: 10, island: levels(30)).startRun(42).accrueIncome(0),
      clock: () => time,
    );
    addTearDown(session.dispose);
    storage.interrupt = true;
    await expectLater(session.prestige(), throwsStateError);
    expect((await repo.load()).island.stars, 1);
    expect(session.save.island.stars, 0);
    storage.interrupt = false;
    await session.retryIncomeSave();
    expect(session.save.island.stars, 1);
    expect(session.save.island.totalLevels, 0);
    expect(session.save.activeRun!.id, 1);
    expect(session.save.wallet, 40);
    expect(await session.prestige(), isFalse);
    time = DateTime.fromMillisecondsSinceEpoch(120000);
    expect(await session.collectIncome(), 0);
    expect(session.save.wallet, 40);
  });

  test(
    'failed disk write exposes retry and preserves prior durable profile',
    () async {
      final storage = InterruptedStorage();
      final repo = SaveRepository(storage);
      final initial = AppSaveV1(wallet: 100).accrueIncome(0);
      await repo.save(initial);
      final session = AppSession(
        repo,
        initial,
        clock: () => DateTime.fromMillisecondsSinceEpoch(60000),
      );
      addTearDown(session.dispose);
      storage.failBeforeWrite = true;
      await expectLater(
        session.purchase(BuildingKind.candyTree),
        throwsStateError,
      );
      expect(session.save.wallet, 100);
      expect((await repo.load()).encode(), initial.encode());
      storage.failBeforeWrite = false;
      await session.retryIncomeSave();
      expect(session.save.wallet, 90);
      expect(session.save.island.level(BuildingKind.candyTree), 1);
    },
  );

  test('migration establishes a single persisted boundary before any elapsed income', () async {
    var time = DateTime.fromMillisecondsSinceEpoch(100000000);
    final repo = SaveRepository(MemoryStorage());
    final first = AppSession(
      repo,
      AppSaveV1(wallet: 100, island: levels(3)),
      clock: () => time,
    );
    expect(await first.collectIncome(), 0);
    first.dispose();
    time = time.add(const Duration(minutes: 2));
    final second = AppSession(repo, await repo.load(), clock: () => time);
    addTearDown(second.dispose);
    expect(await second.collectIncome(), 6);
    expect(second.save.wallet, 106);
  });
  testWidgets(
    'online clock accrues once per minute, pauses, then resumes offline interval',
    (tester) async {
      var time = DateTime.fromMillisecondsSinceEpoch(0);
      final session = AppSession.memory(
        save: AppSaveV1(island: levels(1)).accrueIncome(0),
        clock: () => time,
      );
      addTearDown(session.dispose);
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      session.startIncomeTracking();
      time = DateTime.fromMillisecondsSinceEpoch(60000);
      await tester.pump(const Duration(minutes: 1));
      await tester.pump();
      expect(session.save.wallet, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      time = DateTime.fromMillisecondsSinceEpoch(600000);
      await tester.pump(const Duration(minutes: 9));
      expect(session.save.wallet, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(session.save.wallet, 10);
      session.didChangeAppLifecycleState(AppLifecycleState.paused);
    },
  );

  test(
    'pending island transaction also blocks opening an existing run',
    () async {
      final storage = InterruptedStorage();
      final repo = SaveRepository(storage);
      final session = AppSession(
        repo,
        AppSaveV1(wallet: 100, island: levels(1)).startRun(42).accrueIncome(0),
        clock: () => DateTime.fromMillisecondsSinceEpoch(60000),
      );
      addTearDown(session.dispose);
      storage.interrupt = true;
      await expectLater(session.collectIncome(), throwsStateError);
      await expectLater(session.openRun(), throwsStateError);
      session.settings.setSound(false);
      await session.flushSettings();
      expect((await repo.load()).wallet, 101);
      storage.interrupt = false;
      await session.retryIncomeSave();
      await session.flushSettings();
      final game = await session.openRun();
      expect(game.state.rngState, session.save.activeRun!.game.rngState);
      expect((await repo.load()).wallet, 101);
      expect((await repo.load()).settings.sound, isFalse);
    },
  );
}
