import 'dart:io';

import 'package:candyverse/home/home_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:candyverse/app/app.dart';
import 'package:candyverse/core/theme/app_theme.dart';
import 'package:candyverse/core/localization/app_strings.dart';
import 'package:candyverse/save/application/app_session.dart';
import 'package:candyverse/save/domain/app_save.dart';
import 'package:candyverse/settings/settings_model.dart';
import 'package:candyverse/game/domain/game_state.dart';
import 'package:candyverse/game/domain/game_engine.dart';
import 'package:candyverse/game/domain/board.dart';
import 'package:candyverse/game/domain/piece.dart';
import 'package:candyverse/game/presentation/game_screen.dart';
import 'package:candyverse/upgrades/domain/upgrade.dart';
import 'package:candyverse/island/presentation/island_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
  Future<void> show(
    WidgetTester tester,
    AppSession session, {
    double width = 412,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
    });
    await tester.pumpWidget(CandyverseApp(theme: theme, session: session));
    await tester.runAsync(() async {
      for (final asset in ['brand-sheet.png', 'mascots.png']) {
        await precacheImage(
          AssetImage('assets/kingdom/$asset'),
          tester.element(find.byType(Scaffold).first),
        );
      }
    });
    await tester.pumpAndSettle();
  }

  test(
    'dynamic feedback, dialogs and semantic shapes have English translation',
    () {
      const s = AppStrings.forLanguage('en');
      expect(
        s.translate('Wiersz 1, kolumna 8, puste'),
        'Row 1, column 8, empty',
      );
      expect(
        s.translate(
          'Klocek 2, pozioma linia, 4 pól. Wybierz, następnie pole planszy.',
        ),
        'Piece 2, horizontal line, 4 cells. Select, then choose a board cell.',
      );
      expect(
        s.translate(
          'Poziom 2 z 3.\nMiękkie korony pełne kolorowych cukierków.',
        ),
        'Level 2 of 3.\nSoft treetops full of colourful candy.',
      );
    },
  );
  testWidgets(
    'Home settings EN change persists and island/game translate live',
    (tester) async {
      final session = AppSession.memory(
        save: AppSaveV1(settings: const SavedSettings(language: 'pl')),
        seedSource: () => 8,
      );
      final repo = session.repository;
      await show(tester, session);
      await tester.tap(find.byKey(const Key('home-settings')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('English'));
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Sound'), findsOneWidget);
      await session.flushSettings();
      expect((await repo.load()).settings.language, 'en');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('PLAY'), findsOneWidget);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/home_en_412.png'),
      );
      await tester.tap(find.text('ISLAND'));
      await tester.pumpAndSettle();
      expect(find.byType(IslandScreen), findsOneWidget);
      expect(find.text('Candy Tree'), findsOneWidget);
      await tester.tap(find.text('Candy Tree'));
      await tester.pumpAndSettle();
      expect(find.text('Upgrade • 10 Candy Coins'), findsOneWidget);
      await tester.tap(find.text('Back to island'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back to menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PLAY'));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('Card: 5 moves / 5 lines'), findsOneWidget);
      final controller = tester
          .widget<GameScreen>(find.byType(GameScreen))
          .controller!;
      final piece = controller.state.tray.first!;
      final cell = controller.engine
          .getLegalPlacements(controller.state.board, piece)
          .first;
      await tester.tap(find.byKey(const ValueKey('tray-0')));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey('cell-${cell.row}-${cell.col}')));
      await tester.pumpAndSettle();
      expect(find.text('Piece placed.'), findsOneWidget);
      await tester.tap(find.byTooltip('Back to menu'));
      await tester.pumpAndSettle();
      expect(
        find.text('Your run stays saved. Resume it from the menu.'),
        findsOneWidget,
      );
    },
  );
  testWidgets('English upgrade and result lead to real island and replay', (
    tester,
  ) async {
    final engine = GameEngine.seeded(seed: 8);
    final choice = engine.resolvePhase(
      engine.start().copyWith(totalClearedLines: 5, pendingUpgradeChoices: 1),
    );
    final session = AppSession.memory(
      save: AppSaveV1(
        nextRunId: 2,
        settings: const SavedSettings(language: 'en'),
        activeRun: SavedRun(1, 8, choice),
      ),
    );
    await show(tester, session);
    await tester.tap(find.text('PLAY'));
    await tester.pumpAndSettle();
    expect(find.text('Choose an upgrade'), findsOneWidget);
    expect(
      find.text('Swap a shape in your chosen slot. Recharges after 6 moves.'),
      findsOneWidget,
    );
    await expectLater(
      find.byType(GameScreen),
      matchesGoldenFile('goldens/upgrades_en_412.png'),
    );
    await tester.pumpWidget(const SizedBox());
    final full = GameState(
      board: Board.fromRows([
        for (var r = 0; r < 8; r++) List.filled(8, 'candyPink'),
      ]),
      tray: List.filled(3, pieceCatalog.first),
      rngState: 2,
      totalClearedLines: 5,
      eraserAcquired: 1,
      eraserUses: 1,
      phase: RunPhase.needsEraserDecision,
    );
    final next = AppSession.memory(
      save: AppSaveV1(
        nextRunId: 2,
        settings: const SavedSettings(language: 'en'),
        activeRun: SavedRun(1, 2, full),
      ),
    );
    await tester.pumpWidget(CandyverseApp(theme: theme, session: next));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PLAY'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish run'));
    await tester.pumpAndSettle();
    expect(find.text('Lovely puzzle!'), findsOneWidget);
    expect(next.save.wallet, 25);
    await tester.tap(find.text('Visit island'));
    await tester.pumpAndSettle();
    expect(find.text('25'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to menu'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-play')));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
    expect(next.save.activeRun!.id, 2);
  });
  for (final width in [320.0, 412.0]) {
    testWidgets('English Home and Game fit ${width}dp text2', (tester) async {
      final s = AppSession.memory(
        save: AppSaveV1(settings: const SavedSettings(language: 'en')),
        seedSource: () => 8,
      );
      await show(tester, s, width: width, scale: 2);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('PLAY'));
      await tester.tap(find.text('PLAY'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final context = tester.element(find.byType(GameScreen));
      expect(SettingsScope.maybeOf(context)!.language, 'en');
    });
  }
}
