import 'package:candyverse/core/presentation/candy_controls.dart';
import 'package:candyverse/core/presentation/candy_message.dart';
import 'package:candyverse/core/theme/app_theme.dart';
import 'package:candyverse/home/home_screen.dart';
import 'package:candyverse/game/presentation/game_screen.dart';
import 'package:candyverse/island/presentation/persistent_island_screen.dart';
import 'package:candyverse/save/application/app_session.dart';
import 'package:candyverse/save/application/app_session_scope.dart';
import 'package:candyverse/save/domain/app_save.dart';
import 'package:candyverse/settings/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppTheme theme;
  setUpAll(() async => theme = await AppTheme.load());

  Future<AppSession> app(
    WidgetTester tester, {
    String language = 'en',
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = AppSession.memory(
      save: AppSaveV1(settings: SavedSettings(language: language)),
    );
    addTearDown(session.dispose);
    await tester.pumpWidget(
      SettingsScope(
        settings: session.settings,
        child: AppSessionScope(
          session: session,
          child: MaterialApp(
            theme: theme.material,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: ListenableBuilder(
              listenable: session,
              builder: (_, _) => HomeScreen(theme: theme, session: session),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return session;
  }

  testWidgets('every island tab can return directly to menu', (tester) async {
    await app(tester);
    for (final tab in [0, 1, 2, 3]) {
      await tester.tap(find.byKey(const Key('home-island')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('island-tab-$tab')));
      await tester.pumpAndSettle();
      final menu = find.byKey(const Key('island-menu'));
      expect(tester.getRect(menu).bottom, lessThanOrEqualTo(740));
      await tester.tap(menu);
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(PersistentIslandScreen), findsNothing);
    }
  });

  testWidgets(
    'island play resumes the same saved board with no route accumulation',
    (tester) async {
      final session = await app(tester);
      await tester.tap(find.byKey(const Key('home-play')));
      await tester.pumpAndSettle();
      final controller = await session.openRun();
      final cell = controller.engine
          .getLegalPlacements(controller.state.board, controller.state.tray[0]!)
          .first;
      await tester.tap(find.byKey(const ValueKey('tray-0')));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey('cell-${cell.row}-${cell.col}')));
      await tester.pumpAndSettle();
      final snapshot = session.save.activeRun!.game;
      expect(snapshot.board.occupiedCount, greaterThan(0));
      await tester.tap(find.byTooltip('Back to menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('home-island')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('island-tab-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('island-play')));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.byType(PersistentIslandScreen), findsNothing);
      expect(
        [
          for (var r = 0; r < 8; r++)
            for (var c = 0; c < 8; c++)
              session.save.activeRun!.game.board.at((row: r, col: c)),
        ],
        [
          for (var r = 0; r < 8; r++)
            for (var c = 0; c < 8; c++) snapshot.board.at((row: r, col: c)),
        ],
      );
      await tester.tap(find.byTooltip('Sound and motion'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsOneWidget);
      expect(
        [
          for (var r = 0; r < 8; r++)
            for (var c = 0; c < 8; c++)
              session.save.activeRun!.game.board.at((row: r, col: c)),
        ],
        [
          for (var r = 0; r < 8; r++)
            for (var c = 0; c < 8; c++) snapshot.board.at((row: r, col: c)),
        ],
      );
    },
  );

  for (final language in ['pl', 'en']) {
    testWidgets('notice is readable and dismissible at320 text200 $language', (
      tester,
    ) async {
      await app(tester, language: language, scale: 2);
      final context = tester.element(find.byType(HomeScreen));
      final message = language == 'pl'
          ? 'Za mało Candy Coins. Zdobywasz je w grze i dzięki rozbudowie wyspy.'
          : 'Not enough Candy Coins. Earn them by playing and growing your island.';
      showCandyMessage(context, message, error: true);
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('goldens/notice_${language}_320.png'),
      );
      await tester.tap(
        find.byTooltip(
          language == 'pl' ? 'Zamknij komunikat' : 'Dismiss message',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CandyNotice), findsNothing);
    });
  }

  testWidgets('island navigation stays visible on every tab at320 PL text200', (
    tester,
  ) async {
    await app(tester, language: 'pl', scale: 2);
    await tester.ensureVisible(find.byKey(const Key('home-island')));
    await tester.tap(find.byKey(const Key('home-island')));
    await tester.pumpAndSettle();
    for (final tab in [0, 1, 2, 3]) {
      await tester.tap(find.byKey(ValueKey('island-tab-$tab')));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const Key('island-menu'))).bottom,
        lessThanOrEqualTo(740),
      );
      expect(
        tester.getRect(find.byKey(const Key('island-play'))).bottom,
        lessThanOrEqualTo(740),
      );
      expect(tester.takeException(), isNull);
    }
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/candy_navigation_pl_320.png'),
    );
    await tester.tap(find.byKey(const Key('island-menu')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets(
    'a new notice replaces the previous one and success can be dismissed',
    (tester) async {
      await app(tester);
      final context = tester.element(find.byType(HomeScreen));
      showCandyMessage(context, 'Saving failed.', error: true);
      await tester.pumpAndSettle();
      showCandyMessage(context, 'Your island is blooming!', success: true);
      await tester.pumpAndSettle();
      expect(find.text('Saving failed.'), findsNothing);
      expect(find.text('Your island is blooming!'), findsOneWidget);
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('goldens/notice_success_320.png'),
      );
      await tester.tap(find.byTooltip('Dismiss message'));
      await tester.pumpAndSettle();
      expect(find.byType(CandyNotice), findsNothing);
    },
  );

  testWidgets(
    'new glyphs have a full touch target and exclude decorative image semantics',
    (tester) async {
      await app(tester);
      final gear = find.byKey(const Key('home-settings'));
      expect(tester.getSize(gear).shortestSide, greaterThanOrEqualTo(48));
      expect(find.byType(CandyGlyph), findsWidgets);
      await tester.tap(gear);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('goldens/candy_settings_320.png'),
      );
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );
}
