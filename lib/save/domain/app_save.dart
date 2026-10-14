import 'dart:convert';

import '../../game/domain/board.dart';
import '../../game/domain/game_engine.dart';
import '../../game/domain/game_state.dart';
import '../../game/domain/piece.dart';
import '../../game/domain/tray_generator.dart';
import '../../island/domain/island_state.dart';
import '../../upgrades/domain/upgrade.dart';

class SavedRun {
  const SavedRun(this.id, this.seed, this.game);
  final int id;
  final int seed;
  final GameState game;
}

class RunResult {
  const RunResult(this.id, this.score, this.lines, this.coins, this.luckyLevel);
  final int id, score, lines, coins, luckyLevel;
}

class SavedSettings {
  const SavedSettings({
    this.sound = true,
    this.haptics = true,
    this.reduceMotion = false,
    this.language = 'pl',
  });
  final bool sound, haptics, reduceMotion;
  final String language;
}

/// All durable progression is one immutable value. No Flutter dependency.
class AppSaveV1 {
  AppSaveV1({
    this.nextRunId = 1,
    this.lastAwardedRunId = 0,
    this.wallet = 0,
    this.bestScore = 0,
    IslandState? island,
    this.settings = const SavedSettings(),
    this.activeRun,
    this.lastResult,
  }) : island = island ?? IslandState() {
    if (nextRunId < 1 ||
        lastAwardedRunId < 0 ||
        lastAwardedRunId >= nextRunId ||
        wallet < 0 ||
        bestScore < 0 ||
        (activeRun != null &&
            (activeRun!.id <= lastAwardedRunId ||
                activeRun!.id != nextRunId - 1 ||
                activeRun!.game.rngState == null)) ||
        (lastResult != null &&
            (lastResult!.id != lastAwardedRunId ||
                lastResult!.score > bestScore)) ||
        (lastAwardedRunId > 0 && lastResult == null) ||
        !['pl', 'en'].contains(settings.language)) {
      throw ArgumentError('Inconsistent application snapshot.');
    }
  }
  final int nextRunId, lastAwardedRunId, wallet, bestScore;
  final IslandState island;
  final SavedSettings settings;
  final SavedRun? activeRun;
  final RunResult? lastResult;

  AppSaveV1 copyWith({
    int? nextRunId,
    int? lastAwardedRunId,
    int? wallet,
    int? bestScore,
    IslandState? island,
    SavedSettings? settings,
    SavedRun? activeRun,
    bool clearRun = false,
    RunResult? lastResult,
  }) => AppSaveV1(
    nextRunId: nextRunId ?? this.nextRunId,
    lastAwardedRunId: lastAwardedRunId ?? this.lastAwardedRunId,
    wallet: wallet ?? this.wallet,
    bestScore: bestScore ?? this.bestScore,
    island: island ?? this.island,
    settings: settings ?? this.settings,
    activeRun: clearRun ? null : activeRun ?? this.activeRun,
    lastResult: lastResult ?? this.lastResult,
  );

  AppSaveV1 startRun(int seed) {
    if (activeRun != null) return this;
    return copyWith(
      nextRunId: nextRunId + 1,
      activeRun: SavedRun(
        nextRunId,
        seed,
        GameEngine.seeded(seed: seed).start(),
      ),
    );
  }

  AppSaveV1 checkpoint(int id, GameState game) {
    final run = activeRun;
    if (run == null || run.id != id) return this;
    final next = copyWith(activeRun: SavedRun(id, run.seed, game));
    return game.phase == RunPhase.gameOver ? next.completeRun(id) : next;
  }

  AppSaveV1 completeRun(int id) {
    final run = activeRun;
    if (id <= lastAwardedRunId ||
        run == null ||
        run.id != id ||
        run.game.phase != RunPhase.gameOver) {
      return this;
    }
    final game = run.game;
    return copyWith(
      wallet: wallet + game.pendingCoins,
      bestScore: game.score > bestScore ? game.score : bestScore,
      lastAwardedRunId: id,
      clearRun: true,
      lastResult: RunResult(
        id,
        game.score,
        game.totalClearedLines,
        game.pendingCoins,
        game.luckyJellyLevel,
      ),
    );
  }

  int? price(BuildingKind kind) {
    final level = island.level(kind);
    return level == 3
        ? null
        : switch (kind) {
            BuildingKind.candyTree => [10, 25, 45][level],
            BuildingKind.jellyHouse => [15, 30, 50][level],
            BuildingKind.rainbowFountain => [20, 35, 55][level],
          };
  }

  AppSaveV1 purchase(BuildingKind kind) {
    final cost = price(kind);
    if (cost == null || wallet < cost) return this;
    return copyWith(
      wallet: wallet - cost,
      island: island.withLevel(kind, island.level(kind) + 1),
    );
  }

  String encode() => jsonEncode({
    'schemaVersion': 1,
    'nextRunId': nextRunId,
    'lastAwardedRunId': lastAwardedRunId,
    'wallet': wallet,
    'bestScore': bestScore,
    'island': {for (final k in BuildingKind.values) k.name: island.level(k)},
    'settings': {
      'sound': settings.sound,
      'haptics': settings.haptics,
      'reduceMotion': settings.reduceMotion,
      'language': settings.language,
    },
    'activeRun': activeRun == null
        ? null
        : {
            'id': activeRun!.id,
            'seed': activeRun!.seed,
            'game': _encodeGame(activeRun!.game),
          },
    'lastResult': lastResult == null
        ? null
        : {
            'id': lastResult!.id,
            'score': lastResult!.score,
            'lines': lastResult!.lines,
            'coins': lastResult!.coins,
            'luckyLevel': lastResult!.luckyLevel,
          },
  });

  static AppSaveV1 decode(String raw) {
    try {
      final data = _map(jsonDecode(raw));
      if (data['schemaVersion'] != 1) {
        throw const FormatException('Unsupported save version.');
      }
      final island = _map(data['island']);
      final settings = _map(data['settings']);
      final run = data['activeRun'] == null ? null : _map(data['activeRun']);
      final result = data['lastResult'] == null
          ? null
          : _map(data['lastResult']);
      RunResult? parsedResult;
      if (result != null) {
        final lucky = _int(result, 'luckyLevel', max: 2);
        final lines = _int(result, 'lines');
        final coins = _int(result, 'coins');
        if (coins != 5 * lines * (4 + lucky) ~/ 4) {
          throw const FormatException('Invalid reward.');
        }
        parsedResult = RunResult(
          _int(result, 'id', min: 1),
          _int(result, 'score'),
          lines,
          coins,
          lucky,
        );
      }
      return AppSaveV1(
        nextRunId: _int(data, 'nextRunId', min: 1),
        lastAwardedRunId: _int(data, 'lastAwardedRunId'),
        wallet: _int(data, 'wallet'),
        bestScore: _int(data, 'bestScore'),
        island: IslandState(
          levels: {
            for (final k in BuildingKind.values)
              k: _int(island, k.name, max: 3),
          },
        ),
        settings: SavedSettings(
          sound: _bool(settings, 'sound'),
          haptics: _bool(settings, 'haptics'),
          reduceMotion: _bool(settings, 'reduceMotion'),
          language: settings['language'] as String,
        ),
        activeRun: run == null
            ? null
            : SavedRun(
                _int(run, 'id', min: 1),
                run['seed'] as int,
                _decodeGame(_map(run['game'])),
              ),
        lastResult: parsedResult,
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid save snapshot.');
    }
  }
}

Map<String, Object?> _encodeGame(GameState g) => {
  'board': [
    for (var r = 0; r < 8; r++)
      [for (var c = 0; c < 8; c++) g.board.at((row: r, col: c))],
  ],
  'tray': [
    for (final p in g.tray) p == null ? null : {'id': p.id, 'skin': p.skin},
  ],
  'score': g.score,
  'streak': g.streak,
  'lines': g.totalClearedLines,
  'sugar': g.sugarRushLevel,
  'lucky': g.luckyJellyLevel,
  'rng': g.rngState,
  'eraserAcquired': g.eraserAcquired,
  'eraserUses': g.eraserUses,
  'pendingChoices': g.pendingUpgradeChoices,
  'phase': g.phase.name,
  'choices': [for (final u in g.upgradeChoices) u.name],
};
String? _skin(Object? value) {
  if (value == null) return null;
  if (value is! String || !TrayGenerator.skinIds.contains(value)) {
    throw const FormatException('Unknown skin.');
  }
  return value;
}

GameState _decodeGame(Map<String, dynamic> d) {
  final tray = (d['tray'] as List).map((value) {
    if (value == null) return null;
    final p = _map(value);
    final mask = pieceCatalog.singleWhere((entry) => entry.id == p['id']);
    return Piece(id: mask.id, cells: mask.cells, skin: _skin(p['skin'])!);
  }).toList();
  final g = GameState(
    board: Board.fromRows(
      (d['board'] as List).map((row) => (row as List).map(_skin)),
    ),
    tray: tray,
    score: _int(d, 'score'),
    streak: _int(d, 'streak'),
    totalClearedLines: _int(d, 'lines'),
    sugarRushLevel: _int(d, 'sugar', max: 2),
    luckyJellyLevel: _int(d, 'lucky', max: 2),
    rngState: _int(d, 'rng', min: 1),
    eraserAcquired: _int(d, 'eraserAcquired', max: 2),
    eraserUses: _int(d, 'eraserUses', max: 2),
    pendingUpgradeChoices: _int(d, 'pendingChoices'),
    phase: RunPhase.values.byName(d['phase'] as String),
    upgradeChoices: (d['choices'] as List).map(
      (u) => Upgrade.values.byName(u as String),
    ),
  );
  if (g.streak > g.totalClearedLines ||
      g.pendingUpgradeChoices > g.totalClearedLines ~/ 5 ||
      g.upgradeChoices.any(
        (u) => !GameEngine.seeded(seed: 0).availableUpgrades(g).contains(u),
      )) {
    throw const FormatException('Invalid run progress.');
  }
  return g;
}

Map<String, dynamic> _map(Object? value) =>
    (value as Map).cast<String, dynamic>();
int _int(Map<String, dynamic> d, String key, {int min = 0, int? max}) {
  final value = d[key];
  if (value is! int || value < min || (max != null && value > max)) {
    throw FormatException('Invalid $key.');
  }
  return value;
}

bool _bool(Map<String, dynamic> d, String key) {
  final value = d[key];
  if (value is! bool) throw FormatException('Invalid $key.');
  return value;
}
