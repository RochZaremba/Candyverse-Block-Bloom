import 'package:flutter_test/flutter_test.dart';
import 'package:candyverse/save/data/save_repository.dart';
import 'package:candyverse/save/domain/app_save.dart';

class FailingStorage extends MemoryStorage {
  bool fail = false;
  @override
  Future<void> write(String key, String value) async {
    if (fail) throw StateError('disk failure');
    await super.write(key, value);
  }
}

void main() {
  test('repository reloads one canonical snapshot', () async {
    final storage = MemoryStorage();
    final repo = SaveRepository(storage);
    final value = (await repo.load()).startRun(3);
    await repo.save(value);
    expect((await SaveRepository(storage).load()).encode(), value.encode());
    expect(storage.values.length, 1);
  });
  test('write failure preserves last committed state for restart', () async {
    final storage = FailingStorage();
    final repo = SaveRepository(storage);
    await repo.save(AppSaveV1(wallet: 30));
    storage.fail = true;
    await expectLater(repo.save(AppSaveV1(wallet: 0)), throwsStateError);
    expect((await repo.load()).wallet, 30);
  });
  test(
    'malformed save is preserved, quarantined and never reset on load',
    () async {
      final storage = MemoryStorage();
      storage.values[SaveRepository.key] = '{broken';
      final repo = SaveRepository(storage);
      await expectLater(repo.load(), throwsA(isA<SaveRecoveryRequired>()));
      expect(storage.values[SaveRepository.key], '{broken');
      expect(storage.values[SaveRepository.quarantineKey], '{broken');
      await repo.reset();
      expect(storage.values, isEmpty);
      expect((await repo.load()).wallet, 0);
    },
  );
}
