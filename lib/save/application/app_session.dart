import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../game/application/game_controller.dart';
import '../../game/domain/game_engine.dart';
import '../../game/domain/game_state.dart';
import '../../island/domain/island_state.dart';
import '../../settings/settings_model.dart';
import '../data/save_repository.dart';
import '../domain/app_save.dart';

/// Publishes state only after the single snapshot write has succeeded.
class AppSession extends ChangeNotifier with WidgetsBindingObserver {
  AppSession(
    this.repository,
    this._save, {
    int Function()? seedSource,
    DateTime Function()? clock,
  }) : seedSource = seedSource ?? (() => DateTime.now().microsecondsSinceEpoch),
       clock = clock ?? DateTime.now {
    settings = SettingsModel(initial: _save.settings)..persisted = true;
    settings.addListener(_saveSettings);
  }
  factory AppSession.memory({
    AppSaveV1? save,
    int Function()? seedSource,
    DateTime Function()? clock,
  }) => AppSession(
    SaveRepository(MemoryStorage()),
    save ?? AppSaveV1(),
    seedSource: seedSource,
    clock: clock,
  );
  final DateTime Function() clock;
  Timer? _incomeTimer;
  bool _trackingIncome = false;
  AppSaveV1? _pendingEconomy;
  String? _pendingEconomyOperation;
  int _pendingEconomyResult = 0;
  bool get incomeNeedsRetry => _pendingEconomy != null;
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
  bool resetNeedsRetry = false;
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
    bool economy = false,
  }) {
    final operation = _writeTail.then((_) async {
      if (resetNeedsRetry) throw const SaveResetUncertain();
      if (_pendingEconomy != null && !economy) {
        throw StateError('Retry the pending island save first.');
      }
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
    if (busy ||
        resetNeedsRetry ||
        incomeNeedsRetry ||
        (_game?.blocked ?? false)) {
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
    if (_resetting || resetNeedsRetry || generation != _generation) {
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
    if (_resetting || resetNeedsRetry || generation != _generation) {
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

  Future<bool> purchase(BuildingKind kind) async =>
      await _economicChange('purchase:${kind.name}', (s) {
        final next = s.purchase(kind);
        return (next, identical(next, s) ? 0 : 1);
      }) ==
      1;

  Future<bool> prestige() async =>
      await _economicChange('prestige', (s) {
        final next = s.prestige();
        return (next, identical(next, s) ? 0 : 1);
      }) ==
      1;

  Future<int> collectIncome() => _economicChange('income', (s) => (s, 0));

  Future<void> retryIncomeSave() async {
    final operation = _pendingEconomyOperation;
    if (operation != null) await _economicChange(operation, (s) => (s, 0));
  }

  Future<int> _economicChange(
    String operation,
    (AppSaveV1, int) Function(AppSaveV1) change,
  ) async {
    if (busy ||
        resetNeedsRetry ||
        (!incomeNeedsRetry && (_game?.blocked ?? false))) {
      return 0;
    }
    if (_pendingEconomyOperation != null &&
        _pendingEconomyOperation != operation) {
      throw StateError('Retry the pending island save first.');
    }
    busy = true;
    _notify();
    try {
      await _settingsTail;
      if (_pendingEconomy == null) {
        final accrued = _save.accrueIncome(clock().millisecondsSinceEpoch);
        final (next, result) = change(accrued);
        if (identical(next, _save)) return result;
        _pendingEconomy = next;
        _pendingEconomyOperation = operation;
        _pendingEconomyResult = operation == 'income'
            ? next.wallet - _save.wallet
            : result;
      }
      // Retain the exact target until acknowledgement: even a disk write whose
      // acknowledgement was lost retries the same economic target, never recalculated.
      await _commit((_) => _pendingEconomy!, economy: true);
      final result = _pendingEconomyResult;
      _pendingEconomy = null;
      _pendingEconomyOperation = null;
      if (_settingsRevision != _savedSettingsRevision) _queueSettingsSave();
      return result;
    } catch (_) {
      error = settings.language == 'en'
          ? 'Could not confirm the island save. Retry to continue safely.'
          : 'Nie można potwierdzić zapisu wyspy. Ponów zapis, aby kontynuować.';
      rethrow;
    } finally {
      busy = false;
      _notify();
    }
  }

  /// Only production bootstrap enables ticking; tests may advance an injected
  /// clock and explicitly collect. The timer runs only while the app is active.
  void startIncomeTracking() {
    if (_trackingIncome || _disposed) return;
    _trackingIncome = true;
    WidgetsBinding.instance.addObserver(this);
    _scheduleIncome();
  }

  void _scheduleIncome() {
    _incomeTimer?.cancel();
    _incomeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!busy && !incomeNeedsRetry && !resetNeedsRetry) {
        unawaited(collectIncome().catchError((Object _) => 0));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _incomeTimer?.cancel();
    if (state == AppLifecycleState.resumed && !_disposed) {
      if (!incomeNeedsRetry && !resetNeedsRetry) {
        unawaited(collectIncome().catchError((Object _) => 0));
      }
      _scheduleIncome();
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
      resetNeedsRetry = false;
      _generation++;
      _save = AppSaveV1();
      _pendingEconomy = null;
      _pendingEconomyOperation = null;
      _game?.removeListener(_gameSaveChanged);
      _game?.dispose();
      _game = null;
      settings.restore(_save.settings);
      _settingsRevision = 0;
      _savedSettingsRevision = 0;
      error = null;
    } catch (e) {
      if (e is SaveResetUncertain) resetNeedsRetry = true;
      error = resetNeedsRetry
          ? (settings.language == 'en'
                ? 'Could not confirm data deletion. Retry the reset before continuing.'
                : 'Nie można potwierdzić usunięcia danych. Ponów reset przed kontynuowaniem.')
          : (settings.language == 'en'
                ? 'Could not delete data. Try again.'
                : 'Nie udało się usunąć danych. Spróbuj ponownie.');
      rethrow;
    } finally {
      _resetting = false;
      busy = false;
      _notify();
    }
  }

  bool get _canWriteSettings =>
      !_disposed &&
      !_resetting &&
      !incomeNeedsRetry &&
      !resetNeedsRetry &&
      !(_game?.blocked ?? false);

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
    if (busy || _resetting || resetNeedsRetry) return;
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
    _incomeTimer?.cancel();
    if (_trackingIncome) WidgetsBinding.instance.removeObserver(this);
    settings.removeListener(_saveSettings);
    settings.dispose();
    _game?.removeListener(_gameSaveChanged);
    _game?.dispose();
    super.dispose();
  }
}
