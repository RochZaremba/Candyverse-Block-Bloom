import 'package:flutter/foundation.dart';

import '../../game/application/game_controller.dart';
import '../../game/domain/game_engine.dart';
import '../../game/domain/game_state.dart';
import '../../island/domain/island_state.dart';
import '../../settings/settings_model.dart';
import '../data/save_repository.dart';
import '../domain/app_save.dart';

/// Publishes state only after the single snapshot write has succeeded.
class AppSession extends ChangeNotifier {
  AppSession(this.repository, this._save, {int Function()? seedSource})
    : seedSource = seedSource ?? (() => DateTime.now().microsecondsSinceEpoch) {
    settings = SettingsModel(initial: _save.settings)..persisted = true;
    settings.addListener(_saveSettings);
  }
  factory AppSession.memory({AppSaveV1? save, int Function()? seedSource}) =>
      AppSession(
        SaveRepository(MemoryStorage()),
        save ?? AppSaveV1(),
        seedSource: seedSource,
      );
  final SaveRepository repository;
  final int Function() seedSource;
  AppSaveV1 _save;
  AppSaveV1 get save => _save;
  late final SettingsModel settings;
  GameController? _game;
  bool busy = false;
  String? error;
  bool _disposed = false;
  int _generation = 0;
  bool _resetting = false;
  Future<void> _settingsTail = Future.value();
  int _settingsRevision = 0;
  int _savedSettingsRevision = 0;
  bool _settingsQueued = false;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _writeTail = Future.value();
  Future<void> _commit(
    AppSaveV1 Function(AppSaveV1) change, {
    bool Function()? shouldWrite,
  }) {
    final operation = _writeTail.then((_) async {
      if (shouldWrite != null && !shouldWrite()) return;
      final revision = _settingsRevision;
      final value = change(_save).copyWith(settings: settings.snapshot);
      await repository.save(value);
      _save = value;
      _savedSettingsRevision = revision;
      error = null;
      _notify();
    });
    _writeTail = operation.then((_) {}, onError: (Object e) {});
    return operation;
  }

  Future<GameController> openRun() async {
    if (busy || (_game?.blocked ?? false)) {
      throw StateError('Save operation already running.');
    }
    busy = true;
    _notify();
    try {
      await _settingsTail;
      if (_save.activeRun == null) {
        await _commit((s) => s.startRun(seedSource()));
      }
      final run = _save.activeRun!;
      if (_game?.isGameOver == true) {
        _game!.restore(GameEngine.seeded(seed: run.seed), run.game);
      }
      final generation = _generation;
      _game ??= GameController(
        engine: GameEngine.seeded(seed: run.seed),
        initialState: run.game,
        onSnapshot: (game) => _checkpoint(game, generation),
        onRestart: () => _restart(generation),
      )..addListener(_gameSaveChanged);
      return _game!;
    } catch (_) {
      error = 'Nie udało się zapisać podejścia. Spróbuj ponownie.';
      rethrow;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _checkpoint(GameState game, int generation) async {
    if (_resetting || generation != _generation) {
      throw StateError('This run belongs to a reset profile.');
    }
    await _settingsTail;
    if (generation != _generation) throw StateError('Profile reset.');
    final run = _save.activeRun;
    if (run == null) throw StateError('No active run to checkpoint.');
    await _commit((s) {
      if (generation != _generation) throw StateError('Profile reset.');
      return s.checkpoint(run.id, game);
    });
  }

  Future<void> _restart(int generation) async {
    if (_resetting || generation != _generation) {
      throw StateError('This run belongs to a reset profile.');
    }
    await _settingsTail;
    if (generation != _generation) throw StateError('Profile reset.');
    if (_save.activeRun != null) {
      throw StateError('Active run cannot be replaced.');
    }
    await _commit((s) {
      if (generation != _generation) throw StateError('Profile reset.');
      return s.startRun(seedSource());
    });
    final run = _save.activeRun!;
    _game!.restore(GameEngine.seeded(seed: run.seed), run.game);
  }

  Future<bool> purchase(BuildingKind kind) async {
    if (busy || (_game?.blocked ?? false)) return false;
    busy = true;
    _notify();
    try {
      await _settingsTail;
      final next = _save.purchase(kind);
      if (identical(next, _save)) return false;
      await _commit((s) => s.purchase(kind));
      return true;
    } catch (_) {
      error = 'Zakup nie został zapisany. Monety pozostają na koncie.';
      rethrow;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> resetData() async {
    if (busy || _resetting) throw StateError('Save operation already running.');
    busy = true;
    _resetting = true;
    _notify();
    try {
      // Accepted writes finish before deletion, and no new mutation can enter.
      await _settingsTail;
      final operation = _writeTail.then((_) => repository.reset());
      _writeTail = operation.then((_) {}, onError: (Object e) {});
      await operation;
      _generation++;
      _save = AppSaveV1();
      _game?.removeListener(_gameSaveChanged);
      _game?.dispose();
      _game = null;
      settings.restore(_save.settings);
      _settingsRevision = 0;
      _savedSettingsRevision = 0;
      error = null;
    } catch (_) {
      error = settings.language == 'en'
          ? 'Could not delete data. Try again.'
          : 'Nie udało się usunąć danych. Spróbuj ponownie.';
      rethrow;
    } finally {
      _resetting = false;
      busy = false;
      _notify();
    }
  }

  bool get _canWriteSettings =>
      !_disposed && !_resetting && !(_game?.blocked ?? false);

  void _gameSaveChanged() {
    if (_canWriteSettings && _settingsRevision != _savedSettingsRevision) {
      _queueSettingsSave();
    }
  }

  void _saveSettings() {
    if (_disposed || _resetting) return;
    _settingsRevision++;
    _queueSettingsSave();
  }

  void _queueSettingsSave() {
    if (!_canWriteSettings || _settingsQueued) return;
    _settingsQueued = true;
    final generation = _generation;
    bool allowed() => _canWriteSettings && generation == _generation;
    // Do not await the game here: checkpoint awaits this tail. A blocked
    // checkpoint keeps the settings dirty until its retry succeeds instead.
    _settingsTail = _settingsTail.then((_) async {
      var failed = false;
      try {
        if (!allowed()) return;
        await _commit((s) => s, shouldWrite: allowed);
      } catch (_) {
        failed = true;
        error = 'Nie udało się zapisać ustawień.';
        _notify();
      } finally {
        _settingsQueued = false;
        if (!failed &&
            allowed() &&
            _settingsRevision != _savedSettingsRevision) {
          _queueSettingsSave();
        }
      }
    });
  }

  Future<void> retrySettingsSave() async {
    if (busy || _resetting) return;
    _saveSettings();
    await flushSettings();
  }

  Future<void> flushSettings() async {
    while (true) {
      final tail = _settingsTail;
      await tail;
      if (identical(tail, _settingsTail)) return;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    settings.removeListener(_saveSettings);
    settings.dispose();
    _game?.removeListener(_gameSaveChanged);
    _game?.dispose();
    super.dispose();
  }
}
