import '../../upgrades/domain/upgrade.dart';

import 'package:flutter/foundation.dart';

import '../domain/cell.dart';
import '../domain/game_action.dart';
import '../domain/game_engine.dart';
import '../domain/game_state.dart';

/// Presents engine snapshots without owning any puzzle rules.
class GameController extends ChangeNotifier {
  GameController({required GameEngine engine, GameState? initialState})
    : _engine = engine,
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
  bool get isGameOver => _state.phase == RunPhase.gameOver;

  void _apply(GameState next) {
    if (identical(next, _state)) return;
    _state = next;
    notifyListeners();
  }

  void chooseUpgrade(Upgrade upgrade) =>
      _apply(engine.chooseUpgrade(_state, upgrade));
  void useEraser(Cell cell) => _apply(engine.useEraser(_state, cell));
  void declineEraser() => _apply(engine.declineEraser(_state));

  PlacementResult place(int slot, Cell origin) {
    final result = engine.placePiece(
      _state,
      PlacePiece(slot: slot, origin: origin),
    );
    if (result.accepted) {
      _state = result.state;
      notifyListeners();
    }
    return result;
  }

  void restart() {
    _engine = _engineFactory?.call() ?? _engine;
    _state = engine.start();
    notifyListeners();
  }
}
