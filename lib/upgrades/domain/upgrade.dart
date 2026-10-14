enum Upgrade { sugarRush, luckyJelly, rainbowEraser }

enum RunPhase { playing, upgrade, needsEraserDecision, gameOver }

extension UpgradeDescription on Upgrade {
  String get title => switch (this) {
    Upgrade.sugarRush => 'Sugar Rush',
    Upgrade.luckyJelly => 'Lucky Jelly',
    Upgrade.rainbowEraser => 'Rainbow Eraser',
  };

  String get description => switch (this) {
    Upgrade.sugarRush =>
      '+25% punktów za usuwanie linii. Maksymalnie 2 poziomy.',
    Upgrade.luckyJelly =>
      '+25% bazowych monet z całego podejścia. Maksymalnie 2 poziomy.',
    Upgrade.rainbowEraser => 'Wymaż jedno zajęte pole po potwierdzeniu. Bez punktów i monet. Maksymalnie 2 użycia w podejściu.',
  };
}
