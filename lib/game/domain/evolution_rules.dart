part of 'game_engine.dart';

class BombPreview {
  BombPreview(Iterable<Cell> cells, this.chargesUsed)
    : cells = Set.unmodifiable(cells);
  final Set<Cell> cells;
  final int chargesUsed;
}

extension EvolutionRules on GameEngine {
  int _milestones(GameState s) =>
      (s.evolution?.moves ?? 0) ~/ 5 + s.totalClearedLines ~/ 5;

  Evolution _markBombs(Evolution e, Board board) {
    final bombs = e.bombs
        .where((i) => board.at((row: i ~/ 8, col: i % 8)) != null)
        .take(e.bombCharges)
        .toList();
    for (var i = 0; i < 64 && bombs.length < e.bombCharges; i++) {
      if (!bombs.contains(i) && board.at((row: i ~/ 8, col: i % 8)) != null) {
        bombs.add(i);
      }
    }
    return e.copyWith(bombs: bombs);
  }

  Evolution _advanceEvolution(GameState state, LineClear clear, int streak) {
    final e = state.evolution!;
    final combo = clear.lineCount >= 2 || (clear.lineCount > 0 && streak >= 2);
    final rows = e.rowProgress + (e.explosive > 0 ? clear.rows.length : 0);
    final charges =
        (e.bombCharges +
                rows ~/ e.rowsPerCharge +
                (combo && e.constellation ? 1 : 0))
            .clamp(0, 3);
    return _markBombs(
      e.copyWith(
        moves: e.moves + 1,
        rainbowCooldown: (e.rainbowCooldown - 1).clamp(0, e.rainbowInterval),
        rowProgress: rows % e.rowsPerCharge,
        bombCharges: charges,
        bonusCoins:
            e.bonusCoins +
            (combo ? 2 * e.paws + (e.paws == 4 ? 2 * clear.lineCount : 0) : 0),
      ),
      clear.board,
    );
  }

  List<Piece> rainbowAlternatives(GameState state, int slot) {
    if (slot < 0 || slot >= 3 || state.tray[slot] == null) return [];
    final alternatives = pieceCatalog
        .where((p) => p.id != state.tray[slot]!.id)
        .toList();
    final fitting = alternatives
        .where((p) => getLegalPlacements(state.board, p).isNotEmpty)
        .toList();
    return fitting.isNotEmpty ? fitting : alternatives;
  }

  bool canRescueWithEvolution(GameState s) {
    final e = s.evolution;
    if (e == null) return false;
    if (e.bombCharges > 0 && s.board.occupiedCount > 0) return true;
    return e.rainbowReady &&
        List.generate(3, (i) => i).any(
          (i) => rainbowAlternatives(
            s,
            i,
          ).any((p) => getLegalPlacements(s.board, p).isNotEmpty),
        );
  }

  /// Preview and execution share exactly the same bounded union of cells.
  BombPreview previewBomb(GameState s, Cell target, {String? color}) {
    final e = s.evolution;
    if (e == null ||
        e.bombCharges == 0 ||
        (s.phase != RunPhase.playing &&
            s.phase != RunPhase.needsEraserDecision) ||
        !Board.contains(target) ||
        s.board.at(target) == null ||
        (e.rainbowPrimed && !TrayGenerator.skinIds.contains(color))) {
      return BombPreview([], 0);
    }
    final cells = <Cell>{};
    void blast(Cell center) {
      for (var dr = -1; dr <= 1; dr++) {
        for (var dc = -1; dc <= 1; dc++) {
          if (e.explosive == 1 && dr.abs() + dc.abs() > 1) continue;
          final c = (row: center.row + dr, col: center.col + dc);
          if (Board.contains(c) && s.board.at(c) != null) cells.add(c);
        }
      }
    }

    blast(target);
    if (e.rainbowPrimed) {
      for (var i = 0; i < 64; i++) {
        final c = (row: i ~/ 8, col: i % 8);
        if (s.board.at(c) == color) cells.add(c);
      }
    }
    final triggered = <int>{};
    if (e.explosive >= 3) {
      bool expanded;
      do {
        expanded = false;
        for (final i in e.bombs) {
          final c = (row: i ~/ 8, col: i % 8);
          if (!triggered.contains(i) && cells.contains(c)) {
            triggered.add(i);
            blast(c);
            expanded = true;
          }
        }
      } while (expanded);
    }
    final targetIndex = target.row * 8 + target.col;
    final chargeCount = 1 + triggered.where((i) => i != targetIndex).length;
    // A manually targeted non-marker uses one of the marked charges.
    return BombPreview(cells, chargeCount.clamp(1, e.bombCharges));
  }

  GameState detonateBomb(GameState s, Cell target, {String? color}) {
    final preview = previewBomb(s, target, color: color);
    if (preview.cells.isEmpty) return s;
    final e = s.evolution!;
    final board = s.board.withCells({for (final c in preview.cells) c: null});
    return resolvePhase(
      s.copyWith(
        board: board,
        evolution: _markBombs(
          e.copyWith(
            bombCharges: e.bombCharges - preview.chargesUsed,
            bombs: const [],
            rainbowPrimed: false,
            bonusCoins:
                e.bonusCoins + (e.goldenExplosion ? preview.cells.length : 0),
          ),
          board,
        ),
        phase: RunPhase.playing,
      ),
    );
  }

  GameState useRainbow(GameState s, int slot, {String? color}) {
    final e = s.evolution;
    if (e == null ||
        !e.rainbowReady ||
        (s.phase != RunPhase.playing &&
            s.phase != RunPhase.needsEraserDecision) ||
        (color != null &&
            (e.rainbow < 3 || !TrayGenerator.skinIds.contains(color)))) {
      return s;
    }
    final alternatives = rainbowAlternatives(s, slot);
    if (alternatives.isEmpty) return s;
    final random = SeededRandom.fromState(s.rngState ?? 1);
    final mask = alternatives[random.nextInt(alternatives.length)];
    final tray = s.tray.toList();
    tray[slot] = Piece(
      id: mask.id,
      cells: mask.cells,
      skin: color ?? s.tray[slot]!.skin,
    );
    return resolvePhase(
      s.copyWith(
        tray: tray,
        rngState: random.state,
        phase: RunPhase.playing,
        evolution: e.copyWith(
          rainbowCooldown: e.rainbowInterval,
          rainbowPrimed: e.rainbowExplosion || e.rainbowPrimed,
          bonusCoins: e.bonusCoins + (e.luckySpectrum ? 2 : 0),
        ),
      ),
    );
  }
}
