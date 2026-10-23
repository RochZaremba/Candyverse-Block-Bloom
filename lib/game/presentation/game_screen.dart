import '../../upgrades/presentation/evolution_panel.dart';
import '../domain/game_engine.dart';
import '../domain/tray_generator.dart';
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
import '../../core/presentation/candy_controls.dart';

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
  bool targetingBomb = false;
  String? bombColor;
  bool erasing = false;
  bool confirmingErase = false;
  bool get playing =>
      controller.state.phase == RunPhase.playing &&
      !controller.blocked &&
      !erasing &&
      !targetingBomb &&
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
      targetingBomb = false;
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

  Future<String?> _chooseColor({required bool occupiedOnly}) async {
    final s = AppStrings.of(context);
    final colors = TrayGenerator.skinIds
        .where(
          (color) =>
              !occupiedOnly ||
              List.generate(
                64,
                (i) => controller.state.board.at((row: i ~/ 8, col: i % 8)),
              ).contains(color),
        )
        .toList();
    const names = [
      'Różowy',
      'Fioletowy',
      'Turkusowy',
      'Żółty',
      'Pomarańczowy',
      'Miętowy',
      'Niebieski',
    ];
    const english = [
      'Pink',
      'Purple',
      'Turquoise',
      'Yellow',
      'Orange',
      'Mint',
      'Blue',
    ];
    return showDialog<String>(
      context: context,
      builder: (context) => CandyDialog(
        title: Text(s.text('Wybierz kolor', 'Choose a color')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final color in colors)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: ValueKey('power-color-$color'),
                    onPressed: () => Navigator.pop(context, color),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CandyTile(theme: theme, skin: color),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.text(
                              names[TrayGenerator.skinIds.indexOf(color)],
                              english[TrayGenerator.skinIds.indexOf(color)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: appText(context, 'Anuluj'),
          ),
        ],
      ),
    );
  }

  Future<void> _targetBomb() async {
    if (targetingBomb) {
      setState(() => targetingBomb = false);
      return;
    }
    final before = controller.state;
    String? color;
    if (before.evolution!.rainbowPrimed) {
      color = await _chooseColor(occupiedOnly: true);
      if (!mounted || color == null || !identical(before, controller.state)) {
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      targetingBomb = true;
      erasing = false;
      bombColor = color;
      selected = null;
      preview = null;
      pointer = null;
    });
  }

  Future<void> _bomb(Cell cell) async {
    if (!targetingBomb || confirmingErase || controller.blocked) return;
    final before = controller.state;
    final blast = controller.engine.previewBomb(before, cell, color: bombColor);
    if (blast.cells.isEmpty) return;
    setState(() => confirmingErase = true);
    final s = AppStrings.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => CandyDialog(
        title: Text(s.text('Cukierkowy wybuch?', 'Candy explosion?')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.text(
                  'Usuniesz ${blast.cells.length} klocków. Ładunki: ${blast.chargesUsed}.',
                  'Remove ${blast.cells.length} blocks. Charges: ${blast.chargesUsed}.',
                ),
              ),
              if (before.evolution!.goldenExplosion)
                Text(
                  s.text(
                    '+${blast.cells.length} monet po zakończeniu gry.',
                    '+${blast.cells.length} coins when the run ends.',
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: 216,
                height: 216,
                child: GridView.count(
                  crossAxisCount: 8,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (var i = 0; i < 64; i++)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                blast.cells.contains((row: i ~/ 8, col: i % 8))
                                ? theme.color('danger')
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: CandyTile(
                          theme: theme,
                          skin: before.board.at((row: i ~/ 8, col: i % 8)),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                s.text(
                  'Obramowane pola znikną.',
                  'Outlined cells will disappear.',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: appText(context, 'Anuluj'),
          ),
          TextButton(
            key: const Key('confirm-bomb'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.text('Wybuch!', 'Explode!')),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() {
      confirmingErase = false;
      if (confirm == true) targetingBomb = false;
    });
    if (confirm != true || !identical(before, controller.state)) return;
    controller.detonateBomb(cell, color: bombColor);
    if (!identical(before, controller.state)) {
      setState(
        () => fxEvent = CandyFxEvent(
          id: ++fxId,
          placed: const [],
          cleared: blast.cells,
        ),
      );
      FeedbackScope.maybeOf(context)?.play(CandyCue.clear);
    }
  }

  Future<void> _rainbow() async {
    final before = controller.state;
    final s = AppStrings.of(context);
    final slot = await showDialog<int>(
      context: context,
      builder: (context) => CandyDialog(
        title: Text(s.text('Który kształt wymienić?', 'Which shape to swap?')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                if (before.tray[i] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CandyAction(
                      key: ValueKey('rainbow-slot-$i'),
                      fontSize: 18,
                      label:
                          s.text('Slot ${i + 1}: ', 'Slot ${i + 1}: ') +
                          s.translate(_shapeLabel(before.tray[i]!)),
                      onPressed: () => Navigator.pop(context, i),
                    ),
                  ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: appText(context, 'Anuluj'),
          ),
        ],
      ),
    );
    if (!mounted || slot == null || !identical(before, controller.state)) {
      return;
    }
    String? color;
    if (before.evolution!.rainbow >= 3) {
      color = await _chooseColor(occupiedOnly: false);
      if (!mounted || color == null || !identical(before, controller.state)) {
        return;
      }
    }
    setState(() {
      selected = null;
      preview = null;
      pointer = null;
      targetingBomb = false;
      erasing = false;
    });
    controller.useRainbow(slot, color: color);
    if (!identical(before, controller.state)) {
      FeedbackScope.maybeOf(context)?.play(CandyCue.upgrade);
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
      FeedbackScope.maybeOf(
        context,
      )?.play(result.clear!.lineCount > 0 ? CandyCue.clear : CandyCue.place);
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (controller.isGameOver)
            const CandyArt('result-scene', fit: BoxFit.fill)
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xffdcf5ff),
                    Color(0xfff1e5ff),
                    Color(0xffffe7f3),
                  ],
                ),
              ),
            ),
          SafeArea(child: controller.isGameOver ? _result() : _game()),
        ],
      ),
    ),
  );

  Widget _game() => LayoutBuilder(
    builder: (context, constraints) {
      final width = math.min(constraints.maxWidth - 24, 440.0);
      return Stack(
        key: stackKey,
        children: [
          Center(
            child: SizedBox(
              width: width,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  CandyPanel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 4,
                    ),
                    radius: 22,
                    child: Row(
                      children: [
                        CandyIconButton(
                          symbol: CandySymbol.back,
                          onPressed: _leave,
                          label: AppStrings.of(
                            context,
                          ).translate('Wróć do menu'),
                        ),
                        Expanded(
                          child: _gameMetric(
                            'WYNIK',
                            '${controller.state.score}',
                          ),
                        ),
                        Expanded(
                          child: _gameMetric(
                            'MONETY W GRZE',
                            '${controller.state.pendingCoins}',
                          ),
                        ),
                        CandyIconButton(
                          key: const Key('game-info'),
                          symbol: CandySymbol.info,
                          label: AppStrings.of(
                            context,
                          ).text('Pomoc i moce', 'Help and powers'),
                          onPressed: _showDetails,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, space) => Center(
                        child: SizedBox.square(
                          dimension: math.min(space.maxWidth, space.maxHeight),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xfffff2d8),
                              borderRadius: BorderRadius.circular(
                                theme.panelRadius,
                              ),
                              border: Border.all(
                                color: const Color(0xffe3b9dd),
                                width: 3,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x204b146d),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
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
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (var slot = 0; slot < 3; slot++)
                        Expanded(child: _slot(slot, compact: true)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _gameTools(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (controller.state.phase == RunPhase.upgrade && upgradeReady)
            Positioned.fill(
              child: BlockSemantics(
                child: UpgradeChoices(
                  theme: theme,
                  choices: controller.state.upgradeChoices,
                  evolution: controller.state.evolution,
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
                      : theme.color('ink').withValues(alpha: .55),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (controller.saving) ...[
                            Semantics(
                              liveRegion: true,
                              label: AppStrings.of(
                                context,
                              ).translate('Zapisuję…'),
                              child: const SizedBox.shrink(),
                            ),
                          ] else ...[
                            CandyNotice(
                              kind: CandyNoticeKind.error,
                              message: AppStrings.of(context).translate(
                                'Nie udało się zapisać postępu. Ponów zapis przed kolejnym ruchem.',
                              ),
                              action: CandyAction(
                                onPressed: controller.retrySave,
                                label: AppStrings.of(
                                  context,
                                ).translate('Ponów zapis'),
                                fontSize: 20,
                                height: 58,
                              ),
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

  Widget _gameMetric(String label, String value) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      appText(
        context,
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: candyInk,
        ),
      ),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: candyInk,
          ),
        ),
      ),
    ],
  );

  void _toggleEraser() => setState(() {
    erasing = !erasing;
    targetingBomb = false;
    selected = null;
    preview = null;
    pointer = null;
  });

  Widget _gameTools() {
    final s = AppStrings.of(context);
    final state = controller.state;
    final e = state.evolution;
    final rescue = state.phase == RunPhase.needsEraserDecision;
    final message = targetingBomb
        ? s.text('Wskaż cel bomby', 'Choose a bomb target')
        : erasing
        ? s.translate('Dotknij zajętego pola, aby je wymazać.')
        : rescue
        ? s.text('Brak miejsca', 'No space')
        : feedback == 'Tu klocek się nie mieści. Wybierz inne pole.'
        ? s.text('Tu nie pasuje', 'Does not fit here')
        : selected != null
        ? s.text('Wybierz pole', 'Choose a cell')
        : feedback == 'Przeciągnij klocek lub wybierz go i dotknij pola.'
        ? s.text('Wybierz klocek', 'Choose a piece')
        : s.translate(feedback);
    return CandyPanel(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      radius: 20,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: InkWell(
                key: const Key('game-status'),
                borderRadius: BorderRadius.circular(16),
                onTap: _showDetails,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      Icon(
                        rescue
                            ? Icons.warning_amber_rounded
                            : Icons.info_outline_rounded,
                        color: candyInk,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: candyInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (e != null && e.explosive > 0)
            _powerButton(
              'evolution-bomb',
              Icons.flare_rounded,
              targetingBomb ? '×' : '${e.bombCharges}',
              s.text('Bomba', 'Bomb'),
              _bombButton,
            ),
          if (e != null && e.rainbow > 0)
            _powerButton(
              'evolution-rainbow',
              Icons.cached_rounded,
              e.rainbowReady ? '✓' : '${e.rainbowCooldown}',
              s.text('Wymień kształt', 'Swap shape'),
              _rainbowButton,
            ),
          if (state.eraserUses > 0)
            _powerButton(
              'game-eraser',
              Icons.auto_fix_high_rounded,
              erasing ? '×' : '${state.eraserUses}',
              'Rainbow Eraser',
              _toggleEraser,
            ),
        ],
      ),
    );
  }

  Widget _powerButton(
    String id,
    IconData icon,
    String count,
    String label,
    VoidCallback action,
  ) => Tooltip(
    message: '$label: $count',
    child: Semantics(
      label: '$label: $count',
      button: true,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Material(
          color: const Color(0xfff0dff7),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            key: Key(id),
            borderRadius: BorderRadius.circular(14),
            onTap: confirmingErase || controller.blocked ? null : action,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 26, color: candyInk),
                Positioned(
                  right: 2,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Text(
                        count,
                        style: const TextStyle(
                          fontSize: 11,
                          color: candyInk,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  void _bombButton() {
    if (targetingBomb ||
        (controller.state.evolution!.bombCharges > 0 &&
            controller.state.board.occupiedCount > 0)) {
      _targetBomb();
    } else {
      _explainPower(
        AppStrings.of(context).text('Bomba niedostępna', 'Bomb unavailable'),
        AppStrings.of(context).text(
          'Usuwaj pełne wiersze, aby zdobyć ładunek bomby. Do wybuchu potrzebne jest zajęte pole.',
          'Clear full rows to earn a bomb charge. An explosion needs an occupied cell.',
        ),
      );
    }
  }

  bool get _rainbowCanRescue => List.generate(3, (i) => i).any(
    (slot) => controller.engine
        .rainbowAlternatives(controller.state, slot)
        .any(
          (piece) => controller.engine
              .getLegalPlacements(controller.state.board, piece)
              .isNotEmpty,
        ),
  );

  void _rainbowButton() {
    if (controller.state.phase == RunPhase.needsEraserDecision &&
        controller.state.evolution!.rainbowReady &&
        !_rainbowCanRescue) {
      _explainPower(
        AppStrings.of(
          context,
        ).text('Brak miejsca na nowy kształt', 'No room for a new shape'),
        AppStrings.of(context).text(
          'Żaden inny kształt nie pasuje. Najpierw zrób miejsce bombą lub gumką.',
          'No alternative shape fits. Make room with a bomb or eraser first.',
        ),
      );
    } else if (controller.state.evolution!.rainbowReady) {
      _rainbow();
    } else {
      _explainPower(
        AppStrings.of(context).text('Tęcza ładuje się', 'Rainbow recharging'),
        AppStrings.of(context).text(
          'Ułóż jeszcze ${controller.state.evolution!.rainbowCooldown} klocków, aby wymienić kształt.',
          'Place ${controller.state.evolution!.rainbowCooldown} more pieces to swap a shape.',
        ),
      );
    }
  }

  Future<void> _explainPower(String title, String message) => showDialog<void>(
    context: context,
    builder: (dialogContext) => CandyDialog(
      showFriends: false,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(AppStrings.of(context).text('Rozumiem', 'Got it')),
        ),
      ],
    ),
  );

  Future<void> _showDetails() async {
    final state = controller.state;
    final rescue = state.phase == RunPhase.needsEraserDecision;
    final s = AppStrings.of(context);
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => CandyDialog(
        showFriends: false,
        title: Text(
          rescue
              ? s.text('Brak miejsca na klocek', 'No room for a piece')
              : s.text('Pomoc i moce', 'Help and powers'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rescue
                  ? s.text(
                      'Żaden klocek nie pasuje. Użyj dostępnej mocy, aby zrobić miejsce, albo zakończ podejście.',
                      'None of the pieces fit. Use an available power to make room, or finish this run.',
                    )
                  : s.translate(
                      'Przeciągnij klocek lub wybierz go i dotknij pola.',
                    ),
            ),
            if (!rescue) ...[
              Text(
                s.text(
                  'Zapełniaj wiersze i kolumny, aby je usuwać.',
                  'Fill rows and columns to clear them.',
                ),
              ),
              Text(
                s.text(
                  'Monety trafią na wyspę po zakończeniu podejścia.',
                  'Coins reach your island when the run ends.',
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(s.translate(feedback)),
            const SizedBox(height: 12),
            if (state.evolution == null)
              Text(
                s.text(
                  controller.engine.availableUpgrades(state).isEmpty
                      ? 'Wszystkie ścieżki rozwinięte'
                      : 'Następna karta za ${state.movesUntilUpgrade} ruchów.',
                  controller.engine.availableUpgrades(state).isEmpty
                      ? 'All paths evolved'
                      : 'Next card in ${state.movesUntilUpgrade} moves.',
                ),
              ),
            if (state.evolution != null)
              EvolutionPanel(
                evolution: state.evolution!,
                onBomb: null,
                onRainbow: null,
                showActions: false,
              ),
          ],
        ),
        actions: [
          if (rescue &&
              state.evolution != null &&
              state.evolution!.bombCharges > 0)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'bomb'),
              child: Text(s.text('Użyj bomby', 'Use bomb')),
            ),
          if (rescue &&
              state.evolution != null &&
              state.evolution!.rainbowReady &&
              _rainbowCanRescue)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'rainbow'),
              child: Text(s.text('Wymień kształt', 'Swap shape')),
            ),
          if (rescue && state.eraserUses > 0)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'eraser'),
              child: const Text('Rainbow Eraser'),
            ),
          if (rescue)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'finish'),
              child: appText(context, 'Zakończ podejście'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.text('Zamknij', 'Close')),
          ),
          if (!rescue)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'settings'),
              child: appText(context, 'Dźwięk i ruch'),
            ),
        ],
      ),
    );
    if (!mounted || controller.blocked || !identical(state, controller.state))
      return;
    switch (action) {
      case 'bomb':
        _targetBomb();
      case 'rainbow':
        _rainbow();
      case 'eraser':
        _toggleEraser();
      case 'finish':
        controller.declineEraser();
      case 'settings':
        final session = AppSessionScope.maybeOf(context);
        if (session == null) {
          showFeedbackSettings(context, theme: theme);
        } else {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SettingsScreen(theme: theme, session: session),
            ),
          );
        }
    }
  }

  Widget _metric(String label, String value, {bool compact = false}) =>
      CandyMetric(
        label: AppStrings.of(context).translate(label),
        value: value,
        compact: compact,
        trophy: label.contains('WYNIK'),
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
                : targetingBomb && skin != null
                ? () => _bomb(cell)
                : erasing && skin != null
                ? () => _erase(cell)
                : !playing || selected == null || activeDragSlot != null
                ? null
                : () => _place(cell),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CandyTile(
                  theme: theme,
                  skin: ghost ? piece!.skin : skin,
                  ghost: ghost,
                  invalid: ghost && !legal,
                ),
                if (controller.state.evolution?.bombs.contains(index) ?? false)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Semantics(
                      label: AppStrings.of(context).text('Bomba', 'Bomb'),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xff54206b),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.flare_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
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
            activeDragSlot = null;
            setState(() {
              pointer = null;
              preview = null;
            });
          },
          child: GestureDetector(
            key: ValueKey('tray-$slot'),
            onTap: !playing || piece == null
                ? null
                : () {
                    setState(() {
                      if (activeDragSlot == null) {
                        selected = selected == slot ? null : slot;
                      }
                    });
                  },
            onVerticalDragStart: !playing || piece == null
                ? null
                : (details) {
                    if (activeDragSlot != null) return;
                    activeDragSlot = slot;
                    selected = slot;
                    _drag(details.globalPosition);
                  },
            onVerticalDragUpdate: !playing || piece == null
                ? null
                : (details) {
                    if (activeDragSlot == slot) _drag(details.globalPosition);
                  },
            onVerticalDragEnd: !playing || piece == null
                ? null
                : (_) {
                    if (activeDragSlot != slot) return;
                    activeDragSlot = null;
                    if (!dragCanceled) _place(preview);
                  },
            onHorizontalDragStart: !playing || piece == null
                ? null
                : (details) {
                    if (activeDragSlot != null) return;
                    activeDragSlot = slot;
                    selected = slot;
                    _drag(details.globalPosition);
                  },
            onHorizontalDragUpdate: !playing || piece == null
                ? null
                : (details) {
                    if (activeDragSlot == slot) _drag(details.globalPosition);
                  },
            onHorizontalDragEnd: !playing || piece == null
                ? null
                : (_) {
                    if (activeDragSlot != slot) return;
                    activeDragSlot = null;
                    if (!dragCanceled) _place(preview);
                  },
            child: Container(
              height: compact ? 72 : 96,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xfffff9e9), Color(0xffffefd9)],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  width: 2,
                  color: selected == slot
                      ? const Color(0xffff24c3)
                      : const Color(0xffffd7ee),
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

  Widget _result() => LayoutBuilder(
    builder: (context, constraints) {
      final strings = AppStrings.of(context);
      final width = math.min(constraints.maxWidth, 480.0);
      final height = math.max(constraints.maxHeight, width * 16 / 9);
      return SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                SizedBox(height: height * .18),
                SizedBox(
                  height: height * .12,
                  child: Center(
                    child: Text(
                      'Przyszła\nreklama',
                      textScaler: TextScaler.noScaling,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'LilitaOne',
                        fontSize: width * .065,
                        color: const Color(0xff913493),
                        height: 1,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: height * .06),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CandyLettering(
                    strings.translate('Piękna układanka!'),
                    size: width * .10,
                    color: const Color(0xffff8add),
                  ),
                ),
                SizedBox(height: height * .20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * .10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _metric(
                          'TWÓJ WYNIK',
                          '${controller.state.score}',
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _metric(
                          'MONETY Z PODEJŚCIA',
                          '${controller.state.pendingCoins}',
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * .11),
                  child: CandyAction(
                    label: strings.translate('Zagraj ponownie'),
                    icon: Icons.play_arrow_rounded,
                    fontSize: width * .075,
                    height: 58,
                    onPressed: () {
                      setState(() {
                        selected = null;
                        preview = null;
                        fxEvent = null;
                        feedback =
                            'Przeciągnij klocek lub wybierz go i dotknij pola.';
                      });
                      controller.restart();
                    },
                  ),
                ),
                if (AppSessionScope.maybeOf(context) != null)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * .11),
                    child: CandyAction(
                      label: strings.translate('Odwiedź wyspę'),
                      tone: CandyButtonTone.aqua,
                      icon: Icons.landscape_rounded,
                      fontSize: width * .065,
                      height: 54,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PersistentIslandScreen(
                            theme: theme,
                            session: AppSessionScope.maybeOf(context)!,
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * .22),
                  child: CandyAction(
                    label: strings.translate('Wróć do menu'),
                    tone: CandyButtonTone.cream,
                    fontSize: 16,
                    height: 48,
                    icon: Icons.home_rounded,
                    onPressed: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
    },
  );
}
