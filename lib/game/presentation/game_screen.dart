import '../../core/presentation/candy_message.dart';
import '../../core/localization/app_strings.dart';

import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../upgrades/domain/upgrade.dart';
import '../../upgrades/presentation/upgrade_choices.dart';
import '../../core/feedback/feedback_service.dart';
import '../../settings/settings_sheet.dart';
import '../../settings/settings_screen.dart';
import '../../save/application/app_session_scope.dart';
import '../../island/presentation/persistent_island_screen.dart';
import '../../settings/settings_model.dart';
import 'fx_layer.dart';
import '../application/game_controller.dart';
import '../domain/board.dart';
import '../domain/cell.dart';
import '../domain/piece.dart';
import 'candy_tile.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({required this.theme, this.controller, super.key});
  final AppTheme theme;

  /// Tests and future save/resume can inject an already restored snapshot.
  final GameController? controller;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController controller;
  final boardKey = GlobalKey();
  final stackKey = GlobalKey();
  CandyFxEvent? fxEvent;
  int fxId = 0;
  int? selected;
  Cell? preview;
  Offset? pointer;
  bool dragCanceled = false;
  int? activeDragSlot;
  String feedback = 'Przeciągnij klocek lub wybierz go i dotknij pola.';
  Timer? upgradeTimer;
  bool upgradeReady = false;
  bool erasing = false;
  bool confirmingErase = false;
  bool get playing =>
      controller.state.phase == RunPhase.playing &&
      !controller.blocked &&
      !erasing &&
      !confirmingErase;
  AppTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? GameController.fresh();
    controller.addListener(_refresh);
    upgradeReady = controller.state.phase == RunPhase.upgrade;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (controller.state.phase == RunPhase.upgrade &&
        SettingsScope.reducedMotionOf(context)) {
      upgradeTimer?.cancel();
      upgradeTimer = null;
      upgradeReady = true;
    }
  }

  void _refresh() {
    if (controller.state.phase != RunPhase.playing &&
        controller.state.phase != RunPhase.needsEraserDecision) {
      erasing = false;
    }
    if (controller.state.phase == RunPhase.upgrade &&
        !upgradeReady &&
        upgradeTimer == null) {
      final reduced = SettingsScope.reducedMotionOf(context);
      if (reduced) {
        upgradeReady = true;
      } else {
        upgradeTimer = Timer(Duration(milliseconds: theme.lineClearMs), () {
          upgradeTimer = null;
          if (mounted) setState(() => upgradeReady = true);
        });
      }
    }
    if (controller.state.phase != RunPhase.upgrade) {
      upgradeTimer?.cancel();
      upgradeTimer = null;
      upgradeReady = false;
    }
    setState(() {});
  }

  Future<void> _erase(Cell cell) async {
    if (!erasing ||
        confirmingErase ||
        controller.state.board.at(cell) == null) {
      return;
    }
    setState(() => confirmingErase = true);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => CandyDialog(
        title: appText(context, 'Wymazać to pole?'),
        content: appText(
          context,
          'Wiersz ${cell.row + 1}, kolumna ${cell.col + 1}. Zużyjesz jedno użycie Rainbow Eraser. Bez punktów i monet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: appText(context, 'Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: appText(context, 'Wymaż pole'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() {
      confirmingErase = false;
      if (confirm == true) erasing = false;
    });
    if (confirm == true) {
      final before = controller.state;
      controller.useEraser(cell);
      if (!identical(before, controller.state)) {
        FeedbackScope.maybeOf(context)?.play(CandyCue.place);
      }
    }
  }

  @override
  void dispose() {
    upgradeTimer?.cancel();
    controller.removeListener(_refresh);
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  void _drag(Offset global) {
    if (!playing) return;
    final box = boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    // First cell is lifted above the finger so its destination stays visible.
    final local = box.globalToLocal(global + const Offset(0, -64));
    final cellSize = box.size.width / Board.size;
    setState(() {
      pointer = global;
      preview = (
        row: (local.dy / cellSize).floor(),
        col: (local.dx / cellSize).floor(),
      );
    });
  }

  void _place(Cell? origin) {
    if (!playing || selected == null || origin == null) {
      setState(() {
        pointer = null;
        preview = null;
      });
      return;
    }
    final result = controller.place(selected!, origin);
    if (result.accepted) {
      FeedbackScope.maybeOf(context)
          ?.play(result.clear!.lineCount > 0 ? CandyCue.clear : CandyCue.place);
      fxEvent = CandyFxEvent(
        id: ++fxId,
        placed: result.placedCells,
        cleared: result.clear!.cells,
      );
    }
    setState(() {
      feedback = result.accepted
          ? result.clear!.lineCount > 0
                ? 'Usunięte linie: ${result.clear!.lineCount}. Pięknie!'
                : 'Klocek na miejscu.'
          : 'Tu klocek się nie mieści. Wybierz inne pole.';
      if (result.accepted) selected = null;
      pointer = null;
      preview = null;
    });
  }

  Future<void> _leave() async {
    if (controller.blocked) return;
    if (controller.isGameOver) {
      Navigator.of(context).pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => CandyDialog(
        title: appText(context, 'Wrócić do menu?'),
        content: appText(
          context,
          controller.persistent
              ? 'Podejście pozostanie zapisane. Wznowisz je z menu.'
              : 'To podejście zostanie zakończone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: appText(context, 'Graj dalej'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: appText(context, 'Wróć do menu'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: controller.isGameOver,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _leave();
    },
    child: Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.color('electricPurple'), theme.color('creamWhite')],
          ),
        ),
        child: SafeArea(child: controller.isGameOver ? _result() : _game()),
      ),
    ),
  );

  Widget _game() => LayoutBuilder(
    builder: (context, constraints) {
      final width = math.min(constraints.maxWidth - 24, 440.0);
      final compact =
          constraints.maxHeight < 760 &&
          MediaQuery.textScalerOf(context).scale(16) <= 20;
      final hasEraser =
          controller.state.eraserUses > 0 &&
          controller.state.board.occupiedCount > 0;
      final boardWidth = compact
          ? math.min(
              width,
              math.max(
                256.0,
                constraints.maxHeight - 310 - (hasEraser ? 48 : 0),
              ),
            )
          : width;
      return Stack(
        key: stackKey,
        children: [
          SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: width,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _leave,
                          tooltip: AppStrings.of(context)
                              .translate('Wróć do menu'),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: appText(
                            context,
                            'Cukierkowa układanka',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: theme.color('ink'),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: AppStrings.of(context)
                              .translate('Dźwięk i ruch'),
                          onPressed: () {
                            final session = AppSessionScope.maybeOf(context);
                            if (session == null) {
                              showFeedbackSettings(context, theme: theme);
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SettingsScreen(
                                  theme: theme,
                                  session: session,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.tune_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _metric(
                            'WYNIK',
                            '${controller.state.score}',
                            compact: compact,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _metric(
                            'MONETY W GRZE',
                            '${controller.state.pendingCoins}',
                            compact: compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    appText(
                      context,
                      'Następne ulepszenie: ${controller.state.totalClearedLines}/${controller.state.nextUpgradeMilestone} linii',
                      textAlign: TextAlign.center,
                    ),
                    if (controller.state.eraserUses > 0 &&
                        controller.state.board.occupiedCount > 0 &&
                        controller.state.phase != RunPhase.upgrade)
                      FilledButton.icon(
                        onPressed: confirmingErase
                            ? null
                            : () => setState(() {
                                erasing = !erasing;
                                selected = null;
                                preview = null;
                                pointer = null;
                              }),
                        icon: const Icon(Icons.auto_fix_high_rounded),
                        label: appText(
                          context,
                          erasing
                              ? 'Anuluj wybór pola'
                              : 'Rainbow Eraser (${controller.state.eraserUses})',
                        ),
                      ),
                    if (erasing)
                      appText(
                        context,
                        'Dotknij zajętego pola, aby je wymazać.',
                        textAlign: TextAlign.center,
                      ),
                    if (controller.state.phase ==
                        RunPhase.needsEraserDecision) ...[
                      appText(
                        context,
                        'Klocki nie pasują. Możesz spróbować wymazać jedno pole.',
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: confirmingErase
                            ? null
                            : controller.declineEraser,
                        child: appText(context, 'Zakończ podejście'),
                      ),
                    ],
                    SizedBox(height: compact ? 8 : 18),
                    Center(
                      child: SizedBox(
                        width: boardWidth,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.color('creamWhite'),
                            borderRadius: BorderRadius.circular(
                              theme.panelRadius,
                            ),
                            border: Border.all(
                              color: theme.color('creamWhite'),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme
                                    .color('ink')
                                    .withValues(alpha: .18),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _board(),
                                Positioned.fill(
                                  child: FxLayer(theme: theme, event: fxEvent),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 20),
                    Row(
                      children: [
                        for (var slot = 0; slot < 3; slot++)
                          Expanded(child: _slot(slot, compact: compact)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: appText(
                        context,
                        feedback,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 24),
                  ],
                ),
              ),
            ),
          ),
          if (controller.state.phase == RunPhase.upgrade && upgradeReady)
            Positioned.fill(
              child: BlockSemantics(
                child: UpgradeChoices(
                  theme: theme,
                  choices: controller.state.upgradeChoices,
                  pending: controller.state.pendingUpgradeChoices,
                  onChoose: (upgrade) {
                    final before = controller.state;
                    controller.chooseUpgrade(upgrade);
                    if (!identical(before, controller.state)) {
                      FeedbackScope.maybeOf(context)?.play(CandyCue.upgrade);
                    }
                  },
                ),
              ),
            ),
          if (controller.blocked)
            Positioned.fill(
              child: BlockSemantics(
                child: ColoredBox(
                  // Checkpoint I/O must not repaint the game with a white veil.
                  // The transparent barrier still blocks touch/semantics until
                  // the same durable-write gate acknowledges the move.
                  color: controller.saving
                      ? Colors.transparent
                      : theme.color('creamWhite').withValues(alpha: .95),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (controller.saving) ...[
                            Semantics(
                              liveRegion: true,
                              label: AppStrings.of(context)
                                  .translate('Zapisuję…'),
                              child: const SizedBox.shrink(),
                            ),
                          ] else ...[
                            appText(
                              context,
                              'Nie udało się zapisać postępu. Ponów zapis przed kolejnym ruchem.',
                              textAlign: TextAlign.center,
                            ),
                            FilledButton(
                              onPressed: controller.retrySave,
                              child: appText(context, 'Ponów zapis'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (pointer != null &&
              selected != null &&
              controller.state.tray[selected!] != null)
            _liftedPiece(),
        ],
      );
    },
  );

  Widget _metric(String label, String value, {bool compact = false}) =>
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: compact ? 6 : 12,
        ),
        decoration: BoxDecoration(
          color: theme.color('creamWhite').withValues(alpha: .9),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            appText(
              context,
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            appText(
              context,
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );

  Widget _board() {
    final piece = selected == null ? null : controller.state.tray[selected!];
    final cells = piece != null && preview != null
        ? piece.at(preview!).toSet()
        : <Cell>{};
    final legal =
        piece != null &&
        preview != null &&
        controller.engine.canPlace(controller.state.board, piece, preview!);
    return GridView.builder(
      key: boardKey,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
      ),
      itemCount: 64,
      itemBuilder: (context, index) {
        final cell = (row: index ~/ 8, col: index % 8);
        final skin = controller.state.board.at(cell);
        final ghost = cells.contains(cell);
        return Semantics(
          label: AppStrings.of(context).translate(
            'Wiersz ${cell.row + 1}, kolumna ${cell.col + 1}, ${skin == null ? 'puste' : 'zajęte'}',
          ),
          button: true,
          child: GestureDetector(
            key: ValueKey('cell-${cell.row}-${cell.col}'),
            onTap: confirmingErase
                ? null
                : erasing && skin != null
                ? () => _erase(cell)
                : !playing || selected == null || activeDragSlot != null
                ? null
                : () => _place(cell),
            child: CandyTile(
              theme: theme,
              skin: ghost ? piece!.skin : skin,
              ghost: ghost,
              invalid: ghost && !legal,
            ),
          ),
        );
      },
    );
  }

  String _shapeLabel(Piece piece) {
    if (piece.id.startsWith('horizontal_')) {
      return 'pozioma linia, ${piece.cells.length} pól';
    }
    if (piece.id.startsWith('vertical_')) {
      return 'pionowa linia, ${piece.cells.length} pól';
    }
    return switch (piece.id) {
      'square_2' => 'kwadrat dwa na dwa',
      'square_3' => 'kwadrat trzy na trzy',
      'l_down' => 'litera L, dwa pola w dół i jedno w prawo na dole',
      'l_up' => 'odwrócona litera L, dwa pola w prawo i jedno w dół po prawej',
      't' => 'litera T, trzy pola w prawo i jedno poniżej środka',
      's' => 'litera S, dwa pola na górze przesunięte w prawo',
      'z' => 'litera Z, dwa pola na dole przesunięte w prawo',
      _ => '${piece.cells.length} pól',
    };
  }

  Widget _slot(int slot, {bool compact = false}) {
    final piece = controller.state.tray[slot];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        label: AppStrings.of(context).translate(
          piece == null
              ? 'Klocek ${slot + 1} zużyty'
              : 'Klocek ${slot + 1}, ${_shapeLabel(piece)}. Wybierz, następnie pole planszy.',
        ),
        button: piece != null,
        selected: selected == slot,
        child: Listener(
          onPointerDown: (_) {
            if (activeDragSlot == null) dragCanceled = false;
          },
          onPointerCancel: (_) {
            if (activeDragSlot != slot) return;
            dragCanceled = true;
            setState(() {
              pointer = null;
              preview = null;
            });
          },
          child: GestureDetector(
            key: ValueKey('tray-$slot'),
            onTap: !playing || piece == null
                ? null
                : () => setState(() {
                    if (activeDragSlot == null) {
                      selected = selected == slot ? null : slot;
                    }
                  }),
            onPanStart: !playing || piece == null
                ? null
                : (details) {
                    if (activeDragSlot != null) return;
                    activeDragSlot = slot;
                    selected = slot;
                    _drag(details.globalPosition);
                  },
            onPanUpdate: !playing || piece == null
                ? null
                : (details) {
                    if (activeDragSlot == slot) _drag(details.globalPosition);
                  },
            onPanEnd: !playing || piece == null
                ? null
                : (_) {
                    if (activeDragSlot != slot) return;
                    activeDragSlot = null;
                    if (!dragCanceled) _place(preview);
                  },
            onPanCancel: () => setState(() {
              if (activeDragSlot != slot) return;
              activeDragSlot = null;
              pointer = null;
              preview = null;
            }),
            child: Container(
              height: compact ? 88 : 108,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.color('creamWhite').withValues(alpha: .6),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  width: 2,
                  color: selected == slot
                      ? theme.color('ink')
                      : theme.color('creamWhite'),
                ),
              ),
              child: piece == null
                  ? Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: theme.color('ink').withValues(alpha: .4),
                      ),
                    )
                  : Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _piece(piece, 20),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _piece(Piece piece, double cellSize) {
    final rows = piece.cells.map((c) => c.row).reduce(math.max) + 1;
    final cols = piece.cells.map((c) => c.col).reduce(math.max) + 1;
    return SizedBox(
      width: cols * cellSize,
      height: rows * cellSize,
      child: Stack(
        children: [
          for (final cell in piece.cells)
            Positioned(
              top: cell.row * cellSize,
              left: cell.col * cellSize,
              width: cellSize,
              height: cellSize,
              child: CandyTile(theme: theme, skin: piece.skin),
            ),
        ],
      ),
    );
  }

  Widget _liftedPiece() {
    final box = stackKey.currentContext!.findRenderObject() as RenderBox;
    final local = box.globalToLocal(pointer!);
    final boardBox = boardKey.currentContext!.findRenderObject() as RenderBox;
    final cellSize = boardBox.size.width / 8;
    return Positioned(
      left: local.dx - cellSize / 2,
      top: local.dy - 64 - cellSize / 2,
      child: IgnorePointer(
        child: Opacity(
          opacity: .85,
          child: _piece(controller.state.tray[selected!]!, cellSize),
        ),
      ),
    );
  }

  Widget _result() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 64, color: theme.color('ink')),
          const SizedBox(height: 20),
          appText(
            context,
            'Piękna układanka!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          appText(
            context,
            'Żaden z pozostałych klocków nie pasuje.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _metric('TWÓJ WYNIK', '${controller.state.score}'),
          const SizedBox(height: 12),
          _metric('MONETY Z PODEJŚCIA', '${controller.state.pendingCoins}'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              setState(() {
                selected = null;
                preview = null;
                fxEvent = null;
                feedback = 'Przeciągnij klocek lub wybierz go i dotknij pola.';
              });
              controller.restart();
            },
            child: appText(context, 'Zagraj ponownie'),
          ),
          if (AppSessionScope.maybeOf(context) != null)
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PersistentIslandScreen(
                    theme: theme,
                    session: AppSessionScope.maybeOf(context)!,
                  ),
                ),
              ),
              icon: const Icon(Icons.landscape_rounded),
              label: appText(context, 'Odwiedź wyspę'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: appText(context, 'Wróć do menu'),
          ),
        ],
      ),
    ),
  );
}
