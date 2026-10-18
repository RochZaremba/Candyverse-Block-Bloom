/// Run-only evolution. No clocks, widgets or global randomness.
class Evolution {
  Evolution({
    this.explosive = 0,
    this.rainbow = 0,
    this.paws = 0,
    this.moves = 0,
    this.bombCharges = 0,
    this.rowProgress = 0,
    this.rainbowCooldown = 0,
    this.rainbowPrimed = false,
    this.bonusCoins = 0,
    Iterable<int> bombs = const [],
  }) : bombs = List.unmodifiable(bombs) {
    if ([explosive, rainbow, paws].any((v) => v < 0 || v > 4) ||
        moves < 0 ||
        bombCharges < 0 ||
        bombCharges > 3 ||
        rowProgress < 0 ||
        rowProgress >= rowsPerCharge ||
        rainbowCooldown < 0 ||
        rainbowCooldown > rainbowInterval ||
        bonusCoins < 0 ||
        this.bombs.length > bombCharges ||
        this.bombs.toSet().length != this.bombs.length ||
        this.bombs.any((i) => i < 0 || i >= 64) ||
        (explosive == 0 && (bombCharges != 0 || rowProgress != 0)) ||
        (rainbow == 0 && rainbowCooldown != 0) ||
        (rainbowPrimed && !rainbowExplosion)) {
      throw ArgumentError('Invalid evolution snapshot.');
    }
  }
  final int explosive, rainbow, paws, moves, bombCharges, rowProgress;
  final int rainbowCooldown, bonusCoins;
  final bool rainbowPrimed;
  final List<int> bombs;
  bool get maxed => explosive == 4 && rainbow == 4 && paws == 4;
  int get rowsPerCharge => explosive == 4 ? 2 : 3;
  int get rainbowInterval => rainbow == 4
      ? 3
      : rainbow >= 2
      ? 4
      : 6;
  bool get rainbowReady => rainbow > 0 && rainbowCooldown == 0;
  bool get rainbowExplosion => explosive >= 2 && rainbow >= 2;
  bool get goldenExplosion => explosive >= 2 && paws >= 2;
  bool get luckySpectrum => rainbow >= 2 && paws >= 2;
  bool get constellation => explosive >= 3 && rainbow >= 3 && paws >= 3;
  List<String> get synergies => [
    if (rainbowExplosion) 'Rainbow Explosion',
    if (goldenExplosion) 'Golden Explosion',
    if (luckySpectrum) 'Lucky Spectrum',
    if (constellation) 'Candy Constellation',
  ];

  /// Preserve earned progress when an upgrade shortens a recharge interval.
  Evolution advancePath(int path) {
    final levels = [explosive, rainbow, paws];
    if (path < 0 || path > 2 || levels[path] >= 4) {
      throw ArgumentError('Evolution path is invalid or maxed.');
    }
    levels[path]++;
    final rowInterval = levels[0] == 4 ? 2 : 3;
    final moveInterval = levels[1] == 4
        ? 3
        : levels[1] >= 2
        ? 4
        : 6;
    return copyWith(
      explosive: levels[0],
      rainbow: levels[1],
      paws: levels[2],
      bombCharges: (bombCharges + rowProgress ~/ rowInterval).clamp(0, 3),
      rowProgress: rowProgress % rowInterval,
      rainbowCooldown: rainbowCooldown.clamp(0, moveInterval),
    );
  }

  Evolution copyWith({
    int? explosive,
    int? rainbow,
    int? paws,
    int? moves,
    int? bombCharges,
    int? rowProgress,
    int? rainbowCooldown,
    bool? rainbowPrimed,
    int? bonusCoins,
    Iterable<int>? bombs,
  }) => Evolution(
    explosive: explosive ?? this.explosive,
    rainbow: rainbow ?? this.rainbow,
    paws: paws ?? this.paws,
    moves: moves ?? this.moves,
    bombCharges: bombCharges ?? this.bombCharges,
    rowProgress: rowProgress ?? this.rowProgress,
    rainbowCooldown: rainbowCooldown ?? this.rainbowCooldown,
    rainbowPrimed: rainbowPrimed ?? this.rainbowPrimed,
    bonusCoins: bonusCoins ?? this.bonusCoins,
    bombs: bombs ?? this.bombs,
  );
  Map<String, Object> toJson() => {
    'explosive': explosive,
    'rainbow': rainbow,
    'paws': paws,
    'moves': moves,
    'bombCharges': bombCharges,
    'rowProgress': rowProgress,
    'rainbowCooldown': rainbowCooldown,
    'rainbowPrimed': rainbowPrimed,
    'bonusCoins': bonusCoins,
    'bombs': bombs,
  };
  factory Evolution.fromJson(Map<String, dynamic> d) {
    int value(String key) {
      if (d[key] is! int) throw FormatException('Invalid evolution $key');
      return d[key] as int;
    }

    if (d['rainbowPrimed'] is! bool ||
        d['bombs'] is! List ||
        (d['bombs'] as List).any((v) => v is! int)) {
      throw const FormatException('Invalid evolution flags or bombs');
    }
    return Evolution(
      explosive: value('explosive'),
      rainbow: value('rainbow'),
      paws: value('paws'),
      moves: value('moves'),
      bombCharges: value('bombCharges'),
      rowProgress: value('rowProgress'),
      rainbowCooldown: value('rainbowCooldown'),
      rainbowPrimed: d['rainbowPrimed'] as bool,
      bonusCoins: value('bonusCoins'),
      bombs: (d['bombs'] as List).cast<int>(),
    );
  }
}
