import 'package:flutter_test/flutter_test.dart';
import 'package:candyverse/save/application/app_session.dart';
import 'package:candyverse/save/data/save_repository.dart';
import 'package:candyverse/save/domain/app_save.dart';
import 'package:candyverse/island/domain/island_state.dart';

class ResetAckStorage extends MemoryStorage {
  bool deleteThenThrow = false;
  bool failRead = false;
  bool retainThenThrow = false;
  int writes = 0;
  @override
  Future<void> write(String key, String value) async {
    writes++;
    await super.write(key, value);
  }

  @override
  Future<String?> read(String key) async {
    if (failRead) throw StateError('read unavailable');
    return super.read(key);
  }

  @override
  Future<void> remove(String key) async {
    if (key == SaveRepository.key && retainThenThrow) {
      throw StateError('deletion failed');
    }
    await super.remove(key);
    if (key == SaveRepository.key && deleteThenThrow) {
      throw StateError('delete acknowledgement interrupted');
    }
  }
}

void main() {
  test(
    'delete then lost acknowledgement with absent readback succeeds',
    () async {
      final storage = ResetAckStorage();
      final repo = SaveRepository(storage);
      await repo.save(
        AppSaveV1(wallet: 80, settings: const SavedSettings(language: 'pl')),
      );
      final session = AppSession(repo, await repo.load());
      storage.deleteThenThrow = true;
      await session.resetData();
      expect(session.resetNeedsRetry, isFalse);
      expect(session.save.wallet, 0);
      expect(session.error, isNull);
      expect((await repo.load()).wallet, 0);
      session.dispose();
    },
  );
  test('known failed deletion retains profile and reports failure', () async {
    final storage = ResetAckStorage();
    final repo = SaveRepository(storage);
    await repo.save(
      AppSaveV1(wallet: 80, settings: const SavedSettings(language: 'pl')),
    );
    final session = AppSession(repo, await repo.load());
    storage.retainThenThrow = true;
    await expectLater(session.resetData(), throwsStateError);
    expect(session.resetNeedsRetry, isFalse);
    expect(session.save.wallet, 80);
    expect((await repo.load()).wallet, 80);
    session.dispose();
  });
  test(
    'unknown deletion blocks all old-profile writes until reset retry',
    () async {
      final storage = ResetAckStorage();
      final repo = SaveRepository(storage);
      await repo.save(
        AppSaveV1(wallet: 80, settings: const SavedSettings(language: 'pl')),
      );
      final session = AppSession(repo, await repo.load(), seedSource: () => 8);
      final stale = await session.openRun();
      storage.deleteThenThrow = true;
      storage.failRead = true;
      await expectLater(
        session.resetData(),
        throwsA(isA<SaveResetUncertain>()),
      );
      expect(session.resetNeedsRetry, isTrue);
      expect(session.error, contains('Ponów reset'));
      expect(storage.values.containsKey(SaveRepository.key), isFalse);
      final writes = storage.writes;
      session.settings.setSound(false);
      await session.retrySettingsSave();
      await session.flushSettings();
      await expectLater(session.openRun(), throwsStateError);
      expect(await session.purchase(BuildingKind.candyTree), isFalse);
      final piece = stale.state.tray.first!;
      final origin = stale.engine
          .getLegalPlacements(stale.state.board, piece)
          .first;
      stale.place(0, origin);
      await Future<void>.delayed(Duration.zero);
      expect(stale.saveError, isNotNull);
      expect(storage.writes, writes);
      expect(storage.values.containsKey(SaveRepository.key), isFalse);
      storage.deleteThenThrow = false;
      storage.failRead = false;
      await session.resetData();
      expect(session.resetNeedsRetry, isFalse);
      expect(session.save.wallet, 0);
      expect(session.settings.sound, isTrue);
      final next = await session.openRun();
      stale.retrySave();
      await Future<void>.delayed(Duration.zero);
      final saved = await repo.load();
      expect(saved.wallet, 0);
      expect(saved.activeRun!.id, 1);
      expect(saved.activeRun!.game.score, 0);
      expect(next.state.score, 0);
      session.dispose();
    },
  );
}
