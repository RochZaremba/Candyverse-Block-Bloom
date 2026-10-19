import 'dart:async';
import 'dart:io';

import 'package:candyverse/core/presentation/candy_controls.dart';
import 'package:candyverse/core/theme/app_theme.dart';
import 'package:candyverse/game/application/game_controller.dart';
import 'package:candyverse/game/domain/board.dart';
import 'package:candyverse/game/domain/game_engine.dart';
import 'package:candyverse/game/domain/game_state.dart';
import 'package:candyverse/game/domain/piece.dart';
import 'package:candyverse/game/presentation/game_screen.dart';
import 'package:candyverse/save/domain/app_save.dart';
import 'package:candyverse/settings/settings_model.dart';
import 'package:candyverse/upgrades/domain/evolution.dart';
import 'package:candyverse/upgrades/domain/upgrade.dart';
import 'package:candyverse/upgrades/presentation/evolution_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppTheme theme;
  setUpAll(() async {
    theme = await AppTheme.load();
    final fonts = FontLoader('Roboto');
    for (final weight in ['Regular', 'Bold', 'Black']) {
      fonts.addFont(
        Future.value(
          ByteData.sublistView(
            File('test/fonts/Roboto-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  GameController controller({
    Evolution? evolution,
    bool choices = false,
    Future<void> Function(GameState)? checkpoint,
  }) {
    final engine = GameEngine.seeded(seed: 59);
    final state = GameState(
      board: Board.empty().withCells({
        (row: 2, col: 2): 'candyPink',
        (row: 2, col: 3): 'candyPink',
        (row: 3, col: 3): 'lemonYellow',
        (row: 7, col: 7): 'blueberry',
      }),
      tray: [pieceCatalog.first, null, pieceCatalog.last],
      rngState: 1234,
      evolution:
          evolution ??
          Evolution(
            explosive: 3,
            rainbow: 3,
            paws: 3,
            bombCharges: 2,
            bombs: [18, 27],
          ),
      pendingUpgradeChoices: choices ? 1 : 0,
    );
    final c = GameController(
      engine: engine,
      initialState: state,
      onSnapshot: checkpoint,
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> show(
    WidgetTester tester,
    GameController controller, {
    String language = 'en',
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = SettingsModel(
      initial: SavedSettings(language: language, reduceMotion: true),
    );
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      SettingsScope(
        settings: settings,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme.material,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: GameScreen(theme: theme, controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'bomb previews exact affected cells; cancel preserves charge, confirm awards once',
    (tester) async {
      final c = controller();
      await show(tester, c);
      final original = c.state;
      await tap(tester, find.byKey(const Key('evolution-bomb')));
      await tap(tester, find.byKey(const Key('cell-2-2')));
      expect(find.text('Candy explosion?'), findsOneWidget);
      expect(find.text('Remove 3 blocks. Charges: 2.'), findsOneWidget);
      await tap(tester, find.text('Cancel'));
      expect(c.state, same(original));
      await tap(tester, find.byKey(const Key('cell-2-2')));
      await tap(tester, find.byKey(const Key('confirm-bomb')));
      expect(c.state.board.occupiedCount, 1);
      expect(c.state.evolution!.bombCharges, 0);
      expect(c.state.pendingCoins, 3);
      expect(c.state.evolution!.moves, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'rainbow chooses real slot and seventh color, preserves other slots and blocks cooldown',
    (tester) async {
      final c = controller();
      await show(tester, c);
      final first = c.state.tray.first;
      await tap(tester, find.byKey(const Key('evolution-rainbow')));
      expect(find.byKey(const Key('rainbow-slot-1')), findsNothing);
      await tap(tester, find.byKey(const Key('rainbow-slot-2')));
      await tap(tester, find.byKey(const Key('power-color-blueberry')));
      expect(c.state.tray[2]!.id, isNot(pieceCatalog.last.id));
      expect(c.state.tray[2]!.skin, 'blueberry');
      expect(c.state.tray.first, same(first));
      expect(c.state.evolution!.rainbowCooldown, 4);
      expect(c.state.evolution!.rainbowPrimed, isTrue);
      expect(c.state.pendingCoins, 2);
      final button = tester.widget<CandyAction>(
        find.byKey(const Key('evolution-rainbow')),
      );
      expect(button.onPressed, isNull);
      await tap(tester, find.byKey(const Key('evolution-bomb')));
      await tap(tester, find.byKey(const Key('power-color-blueberry')));
      await tap(tester, find.byKey(const Key('cell-2-2')));
      expect(find.text('Remove 4 blocks. Charges: 2.'), findsOneWidget);
      await expectLater(
        find.byType(Overlay).first,
        matchesGoldenFile('goldens/evolution_bomb_preview_320.png'),
      );
      await tap(tester, find.byKey(const Key('confirm-bomb')));
      expect(c.state.board.occupiedCount, 0);
      expect(c.state.pendingCoins, 6);
    },
  );
  testWidgets(
    'power checkpoint failure blocks repeat input; retry commits identical snapshot',
    (tester) async {
      var calls = 0;
      final snapshots = <GameState>[];
      final gate = Completer<void>();
      final c = controller(
        checkpoint: (s) async {
          snapshots.add(s);
          calls++;
          if (calls == 1) {
            await gate.future;
            throw StateError('disk');
          }
        },
      );
      await show(tester, c);
      await tap(tester, find.byKey(const Key('evolution-rainbow')));
      await tap(tester, find.byKey(const Key('rainbow-slot-0')));
      await tap(tester, find.byKey(const Key('power-color-candyPink')));
      expect(c.saving, isTrue);
      final snapshot = c.state;
      c.useRainbow(2);
      expect(c.state, same(snapshot));
      gate.complete();
      await tester.pumpAndSettle();
      expect(c.saveError, isNotNull);
      await tap(tester, find.text('Retry save'));
      expect(c.saveError, isNull);
      expect(calls, 2);
      expect(snapshots.last, same(snapshot));
      expect(c.state.pendingCoins, 2);
    },
  );
  for (final language in ['pl', 'en']) {
    testWidgets(
      'cards show real ranks and synergy unlock at320 ${language}200%',
      (tester) async {
        final c = controller(
          evolution: Evolution(
            explosive: 2,
            rainbow: 1,
            paws: 2,
            rainbowCooldown: 5,
          ),
          choices: true,
        );
        await show(tester, c, language: language, scale: 2);
        final choice = find.byKey(const Key('upgrade-quickMagic'));
        await tester.ensureVisible(choice);
        await tester.pumpAndSettle();
        expect(
          find.text(
            '${language == 'pl' ? 'Odblokujesz' : 'Unlock'}: Rainbow Explosion',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            '${language == 'pl' ? 'Odblokujesz' : 'Unlock'}: Lucky Spectrum',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(GameScreen),
          matchesGoldenFile('goldens/evolution_cards_${language}_320.png'),
        );
        await tap(tester, choice);
        expect(c.state.phase, RunPhase.playing);
        expect(c.state.evolution!.synergies.length, 3);
      },
    );
    testWidgets(
      'powers remain scrollable with full text at320 ${language}200%',
      (tester) async {
        final c = controller();
        await show(tester, c, language: language, scale: 2);
        await tester.ensureVisible(find.byType(EvolutionPanel));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(GameScreen),
          matchesGoldenFile('goldens/evolution_powers_${language}_320.png'),
        );
        await tap(tester, find.byKey(const Key('evolution-bomb')));
        await tap(tester, find.byKey(const Key('cell-2-2')));
        expect(find.byKey(const Key('confirm-bomb')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
