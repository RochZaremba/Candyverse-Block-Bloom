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
  Future<void> _settingsTail = Future.value();
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _writeTail = Future.value();
  Future<void> _commit(AppSaveV1 Function(AppSaveV1) change) {
    final operation = _writeTail.then((_) async {
      final value = change(_save).copyWith(settings: settings.snapshot);
      await repository.save(value);
      _save = value;
      error = null;
      _notify();
    });
    _writeTail = operation.then((_) {}, onError: (Object e) {});
    return operation;
  }

  Future<GameController> openRun() async {
    if (busy) throw StateError('Save operation already running.');
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
      return _game ??= GameController(
        engine: GameEngine.seeded(seed: run.seed),
        initialState: run.game,
        onSnapshot: _checkpoint,
        onRestart: _restart,
      );
    } catch (_) {
      error = 'Nie udało się zapisać podejścia. Spróbuj ponownie.';
      rethrow;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _checkpoint(GameState game) async {
    await _settingsTail;
    final run = _save.activeRun;
    if (run == null) throw StateError('No active run to checkpoint.');
    await _commit((s) => s.checkpoint(run.id, game));
  }

  Future<void> _restart() async {
    await _settingsTail;
    if (_save.activeRun != null) {
      throw StateError('Active run cannot be replaced.');
    }
    await _commit((s) => s.startRun(seedSource()));
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

  void _saveSettings() {
    // Read current progression inside the queued task, never capture an old
    // wallet while a previous game write is still completing.
    _settingsTail = _settingsTail.then((_) async {
      try {
        await _commit((s) => s.copyWith(settings: settings.snapshot));
      } catch (_) {
        error = 'Nie udało się zapisać ustawień.';
        _notify();
      }
    });
  }

  Future<void> flushSettings() => _settingsTail;
  @override
  void dispose() {
    _disposed = true;
    settings.removeListener(_saveSettings);
    settings.dispose();
    _game?.dispose();
    super.dispose();
  }
}
