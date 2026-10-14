import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_save.dart';

abstract interface class SaveStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

class PreferencesStorage implements SaveStorage {
  PreferencesStorage() : preferences = SharedPreferencesAsync();
  final SharedPreferencesAsync preferences;
  @override
  Future<String?> read(String key) => preferences.getString(key);
  @override
  Future<void> write(String key, String value) =>
      preferences.setString(key, value);
  @override
  Future<void> remove(String key) => preferences.remove(key);
}

class MemoryStorage implements SaveStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

class SaveRecoveryRequired implements Exception {
  const SaveRecoveryRequired(this.raw);
  final String raw;
}

class SaveRepository {
  SaveRepository(this.storage);
  static const key = 'candyverse.save.v1';
  static const quarantineKey = 'candyverse.save.quarantine';
  final SaveStorage storage;
  Future<AppSaveV1> load() async {
    final raw = await storage.read(key);
    if (raw == null) return AppSaveV1();
    try {
      return AppSaveV1.decode(raw);
    } on FormatException {
      // Preserve evidence before offering an explicit recovery. Never overwrite
      // a corrupt or newer save just because the application was launched.
      await storage.write(quarantineKey, raw);
      throw SaveRecoveryRequired(raw);
    }
  }

  Future<void> save(AppSaveV1 value) => storage.write(key, value.encode());
  Future<void> reset() async {
    // Delete diagnostics first: a failure must not remove the playable profile.
    // The canonical key is the final destructive operation.
    await storage.remove(quarantineKey);
    await storage.remove(key);
  }
}
