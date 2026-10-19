enum Upgrade {
  sugarRush,
  luckyJelly,
  rainbowEraser,
  explosiveCandy,
  blastRadius,
  chainReaction,
  sugarNova,
  rainbowMagic,
  quickMagic,
  colorMastery,
  rainbowReserve,
  luckyPaws,
  comboTreats,
  goldenPaws,
  luckyCascade,
}

enum RunPhase { playing, upgrade, needsEraserDecision, gameOver }

extension UpgradeDescription on Upgrade {
  bool get isEvolution => index >= 3;
  int get path => (index - 3) ~/ 4;
  int get rank => (index - 3) % 4 + 1;
  String get title => switch (this) {
    Upgrade.explosiveCandy => 'Explosive Candy',
    Upgrade.blastRadius => 'Blast Radius',
    Upgrade.chainReaction => 'Chain Reaction',
    Upgrade.sugarNova => 'Sugar Nova',
    Upgrade.rainbowMagic => 'Rainbow Magic',
    Upgrade.quickMagic => 'Quick Magic',
    Upgrade.colorMastery => 'Color Mastery',
    Upgrade.rainbowReserve => 'Rainbow Reserve',
    Upgrade.luckyPaws => 'Lucky Paws',
    Upgrade.comboTreats => 'Combo Treats',
    Upgrade.goldenPaws => 'Golden Paws',
    Upgrade.luckyCascade => 'Lucky Cascade',
    Upgrade.sugarRush => 'Sugar Rush',
    Upgrade.luckyJelly => 'Lucky Jelly',
    Upgrade.rainbowEraser => 'Rainbow Eraser',
  };

  String get description => switch (this) {
    Upgrade.explosiveCandy =>
      'Co 3 usunięte wiersze: bomba w kształcie krzyża. Maks. 3 ładunki.',
    Upgrade.blastRadius => 'Bomba usuwa obszar 3×3.',
    Upgrade.chainReaction => 'Trafione bomby uruchamiają reakcję łańcuchową.',
    Upgrade.sugarNova => 'Ładuj bombę co 2 usunięte wiersze.',
    Upgrade.rainbowMagic =>
      'Wymień kształt w wybranym slocie. Odnawia się po 6 ruchach.',
    Upgrade.quickMagic => 'Tęczowa wymiana odnawia się po 4 ruchach.',
    Upgrade.colorMastery => 'Wybierz też kolor nowego klocka.',
    Upgrade.rainbowReserve => 'Tęczowa wymiana odnawia się po 3 ruchach.',
    Upgrade.luckyPaws => 'Combo: co najmniej 2 linie naraz lub kolejne czyszczenie. +40 punktów i +2 monety.',
    Upgrade.comboTreats => 'Combo: +80 punktów i +4 monety.',
    Upgrade.goldenPaws => 'Combo: +120 punktów i +6 monet.',
    Upgrade.luckyCascade =>
      'Combo: +160 punktów, +8 monet i +2 monety za linię.',
    Upgrade.sugarRush =>
      '+25% punktów za usuwanie linii. Maksymalnie 2 poziomy.',
    Upgrade.luckyJelly =>
      '+25% bazowych monet z całego podejścia. Maksymalnie 2 poziomy.',
    Upgrade.rainbowEraser => 'Wymaż jedno zajęte pole po potwierdzeniu. Bez punktów i monet. Maksymalnie 2 użycia w podejściu.',
  };
}
