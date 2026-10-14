import 'dart:async';

import '../../upgrades/domain/upgrade.dart';

import 'package:flutter/foundation.dart';

import '../domain/cell.dart';
import '../domain/game_action.dart';
import '../domain/game_engine.dart';
import '../domain/game_state.dart';

/// Presents engine snapshots without owning any puzzle rules.
class GameController extends ChangeNotifier {
  GameController({
    required GameEngine engine,
    GameState? initialState,
    this.onSnapshot,
    this.onRestart,
  }) : _engine = engine,
       _state = engine.resolvePhase(initialState ?? engine.start());

  factory GameController.fresh({int Function()? seedSource}) {
    final nextSeed = seedSource ?? () => DateTime.now().microsecondsSinceEpoch;
    GameEngine createEngine() => GameEngine.seeded(seed: nextSeed());
    return GameController(engine: createEngine())
      .._engineFactory = createEngine;
  }

  GameEngine Function()? _engineFactory;
  GameEngine _engine;
  GameEngine get engine => _engine;
  GameState _state;
  GameState get state => _state;
  final Future<void> Function(GameState)? onSnapshot;
  final Future<void> Function()? onRestart;
  bool saving = false;
  Object? saveError;
  bool _disposed = false;
  bool _retryRestart = false;
  bool get persistent => onSnapshot != null;
  bool get blocked => saving || saveError != null;
  bool get isGameOver => _state.phase == RunPhase.gameOver && !blocked;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _persist() async {
    try {
      await onSnapshot!(_state);
      saveError = null;
    } catch (e) {
      saveError = e;
    } finally {
      saving = false;
      _notify();
    }
  }

  void retrySave() {
    if (saving || saveError == null) return;
    saving = true;
    saveError = null;
    _notify();
    unawaited(_retryRestart ? _restartPersisted() : _persist());
  }

  void restore(GameEngine engine, GameState state) {
    _engine = engine;
    _state = state;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _apply(GameState next) {
    if (blocked || identical(next, _state)) return;
    _state = next;
    if (persistent) saving = true;
    _notify();
    if (persistent) unawaited(_persist());
  }

  void chooseUpgrade(Upgrade upgrade) =>
      _apply(engine.chooseUpgrade(_state, upgrade));
  void useEraser(Cell cell) => _apply(engine.useEraser(_state, cell));
  void declineEraser() => _apply(engine.declineEraser(_state));

  PlacementResult place(int slot, Cell origin) {
    if (blocked) return PlacementResult.rejected(_state);
    final result = engine.placePiece(
      _state,
      PlacePiece(slot: slot, origin: origin),
    );
    if (result.accepted) {
      _apply(result.state);
    }
    return result;
  }

  void restart() {
    if (blocked) return;
    if (onRestart != null) {
      saving = true;
      _notify();
      unawaited(_restartPersisted());
      return;
    }
    _engine = _engineFactory?.call() ?? _engine;
    _state = engine.start();
    notifyListeners();
  }

  Future<void> _restartPersisted() async {
    _retryRestart = true;
    try {
      await onRestart!();
      _retryRestart = false;
      saveError = null;
    } catch (e) {
      saveError = e;
    } finally {
      saving = false;
      _notify();
    }
  }
}
