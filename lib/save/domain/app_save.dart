import '../../upgrades/domain/evolution.dart';

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
  const RunResult(
    this.id,
    this.score,
    this.lines,
    this.coins,
    this.luckyLevel, [
    this.bonusCoins = 0,
  ]);
  final int id, score, lines, coins, luckyLevel, bonusCoins;
}

class SavedSettings {
  const SavedSettings({
    this.sound = true,
    this.haptics = true,
    this.reduceMotion = false,
    this.language = 'en',
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
    this.incomeTimestampMs,
    this.incomeRemainder = 0,
  }) : island = island ?? IslandState() {
    if ((incomeTimestampMs != null && incomeTimestampMs! < 0) ||
        incomeRemainder < 0 ||
        incomeRemainder >= incomeDenominator ||
        nextRunId < 1 ||
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
  static const incomeDenominator = 600000;
  final int? incomeTimestampMs;
  final int incomeRemainder;
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
    int? incomeTimestampMs,
    int? incomeRemainder,
  }) => AppSaveV1(
    nextRunId: nextRunId ?? this.nextRunId,
    lastAwardedRunId: lastAwardedRunId ?? this.lastAwardedRunId,
    wallet: wallet ?? this.wallet,
    bestScore: bestScore ?? this.bestScore,
    island: island ?? this.island,
    settings: settings ?? this.settings,
    activeRun: clearRun ? null : activeRun ?? this.activeRun,
    lastResult: lastResult ?? this.lastResult,
    incomeTimestampMs: incomeTimestampMs ?? this.incomeTimestampMs,
    incomeRemainder: incomeRemainder ?? this.incomeRemainder,
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
      wallet: _checkedBalance(
        BigInt.from(wallet) + BigInt.from(game.pendingCoins),
      ),
      bestScore: game.score > bestScore ? game.score : bestScore,
      lastAwardedRunId: id,
      clearRun: true,
      lastResult: RunResult(
        id,
        game.score,
        game.totalClearedLines,
        game.pendingCoins,
        game.luckyJellyLevel,
        game.evolution?.bonusCoins ?? 0,
      ),
    );
  }

  /// Whole coins with a carried fractional numerator; never rewinds the clock.
  AppSaveV1 accrueIncome(int nowMs) {
    if (nowMs < 0) throw ArgumentError.value(nowMs, 'nowMs');
    final previous = incomeTimestampMs;
    if (previous == null) return copyWith(incomeTimestampMs: nowMs);
    if (nowMs <= previous) return this;
    // Multiplication can overflow even when the final quotient fits in the
    // snapshot's native integer representation. Keep intermediates exact.
    final amount =
        BigInt.from(incomeRemainder) +
        BigInt.from(nowMs - previous) *
            BigInt.from(island.incomeTenthsPerMinute);
    final denominator = BigInt.from(incomeDenominator);
    return copyWith(
      wallet: _checkedBalance(BigInt.from(wallet) + amount ~/ denominator),
      incomeRemainder: (amount % denominator).toInt(),
      incomeTimestampMs: nowMs,
    );
  }

  AppSaveV1 prestige() =>
      island.canPrestige ? copyWith(island: island.prestige()) : this;

  int? price(BuildingKind kind) {
    final level = island.level(kind);
    if (level == IslandState.maxLevel) return null;
    final initial = switch (kind) {
      BuildingKind.candyTree => [10, 25, 45],
      BuildingKind.jellyHouse => [15, 30, 50],
      BuildingKind.rainbowFountain => [20, 35, 55],
    };
    if (level < 3) return initial[level];
    final growth = level - 2;
    return initial.last + (20 + kind.index * 5) * growth * growth;
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
    'schemaVersion': 3,
    'incomeTimestampMs': incomeTimestampMs,
    'incomeRemainder': incomeRemainder,
    'stars': island.stars,
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
            'bonusCoins': lastResult!.bonusCoins,
          },
  });

  static AppSaveV1 decode(String raw) {
    try {
      final data = _map(jsonDecode(raw));
      final version = data['schemaVersion'];
      if (version != 1 && version != 2 && version != 3) {
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
        final bonus = version == 3 ? _int(result, 'bonusCoins') : 0;
        if (coins != 5 * lines * (4 + lucky) ~/ 4 + bonus) {
          throw const FormatException('Invalid reward.');
        }
        parsedResult = RunResult(
          _int(result, 'id', min: 1),
          _int(result, 'score'),
          lines,
          coins,
          lucky,
          bonus,
        );
      }
      return AppSaveV1(
        incomeTimestampMs: version == 1 || data['incomeTimestampMs'] == null
            ? null
            : _int(data, 'incomeTimestampMs'),
        incomeRemainder: version == 1
            ? 0
            : _int(data, 'incomeRemainder', max: incomeDenominator - 1),
        nextRunId: _int(data, 'nextRunId', min: 1),
        lastAwardedRunId: _int(data, 'lastAwardedRunId'),
        wallet: _int(data, 'wallet'),
        bestScore: _int(data, 'bestScore'),
        island: IslandState(
          stars: version == 1 ? 0 : _int(data, 'stars'),
          levels: {
            for (final k in BuildingKind.values)
              k: _int(
                island,
                k.name,
                max: version == 1 ? 3 : IslandState.maxLevel,
              ),
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
                _decodeGame(_map(run['game']), evolutionVersion: version == 3),
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
    for (final p in g.tray)
      p == null
          ? null
          : {
              'id': p.id,
              'skin': p.skin,
              'cells': [
                for (final cell in p.cells) [cell.row, cell.col],
              ],
            },
  ],
  'evolution': g.evolution?.toJson(),
  'pendingCoins': g.pendingCoins,
  'score': g.score,
  'streak': g.streak,
  'lines': g.totalClearedLines,
  'legacyMoves': g.legacyMoves,
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

GameState _decodeGame(
  Map<String, dynamic> d, {
  required bool evolutionVersion,
}) {
  final tray = (d['tray'] as List).map((value) {
    if (value == null) return null;
    final p = _map(value);
    final mask = pieceCatalog.singleWhere((entry) => entry.id == p['id']);
    final cells = (p['cells'] as List).map((value) {
      final pair = value as List;
      if (pair.length != 2 || pair[0] is! int || pair[1] is! int) {
        throw const FormatException('Invalid mask coordinate.');
      }
      return (row: pair[0] as int, col: pair[1] as int);
    }).toList();
    if (cells.length != mask.cells.length ||
        cells.toSet().length != cells.length ||
        mask.cells.toSet().difference(cells.toSet()).isNotEmpty) {
      throw const FormatException('Mask does not match its catalog ID.');
    }
    return Piece(id: mask.id, cells: cells, skin: _skin(p['skin'])!);
  }).toList();
  if (evolutionVersion && !d.containsKey('evolution')) {
    throw const FormatException('Missing evolution discriminator');
  }
  final g = GameState(
    evolution: !evolutionVersion || d['evolution'] == null
        ? null
        : Evolution.fromJson(_map(d['evolution'])),
    board: Board.fromRows(
      (d['board'] as List).map((row) => (row as List).map(_skin)),
    ),
    tray: tray,
    score: _int(d, 'score'),
    streak: _int(d, 'streak'),
    totalClearedLines: _int(d, 'lines'),
    legacyMoves: d.containsKey('legacyMoves') ? _int(d, 'legacyMoves') : 0,
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
  final engine = GameEngine.seeded(seed: 0);
  if (_int(d, 'pendingCoins') != g.pendingCoins ||
      (g.phase != RunPhase.upgrade && g.pendingUpgradeChoices != 0) ||
      (g.phase == RunPhase.playing &&
          (g.pendingUpgradeChoices != 0 || engine.isGameOver(g))) ||
      (g.phase == RunPhase.needsEraserDecision &&
          ((g.eraserUses == 0 && !engine.canRescueWithEvolution(g)) ||
              !engine.isGameOver(g))) ||
      (g.phase == RunPhase.gameOver && !engine.isGameOver(g))) {
    throw const FormatException('Invalid run phase or pending reward.');
  }
  if (g.streak > g.totalClearedLines ||
      g.pendingUpgradeChoices >
          // Accept already-earned queues from pre-cadence saves as well.
          (g.evolution?.moves ?? 0) ~/ 5 +
              g.totalClearedLines ~/ 5 +
              g.legacyMoves ~/ GameState.upgradeMoveInterval ||
      g.upgradeChoices.any(
        (u) => !GameEngine.seeded(seed: 0).availableUpgrades(g).contains(u),
      )) {
    throw const FormatException('Invalid run progress.');
  }
  if (g.evolution != null &&
      g.evolution!.bombs.any(
        (i) => g.board.at((row: i ~/ 8, col: i % 8)) == null,
      )) {
    throw const FormatException('Bomb marker must occupy a cell');
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

/// Reject an unrepresentable balance explicitly; never clamp or wrap currency.
int _checkedBalance(BigInt value) {
  final result = value.toInt();
  if (result < 0 || BigInt.from(result) != value) {
    throw StateError('Balance exceeds the save format integer representation.');
  }
  return result;
}
