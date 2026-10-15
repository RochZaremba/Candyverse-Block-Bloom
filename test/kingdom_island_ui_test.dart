import 'package:candyverse/core/localization/app_strings.dart';
import 'package:candyverse/core/theme/app_theme.dart';
import 'package:candyverse/island/domain/island_state.dart';
import 'package:candyverse/island/presentation/persistent_island_screen.dart';
import 'package:candyverse/island/presentation/island_screen.dart';
import 'package:candyverse/save/application/app_session.dart';
import 'package:candyverse/save/domain/app_save.dart';
import 'package:candyverse/settings/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppTheme theme;
  setUpAll(() async => theme = await AppTheme.load());

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
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    addTearDown(session.dispose);
    await tester.pumpWidget(
      SettingsScope(
        settings: session.settings,
        child: MaterialApp(
          theme: theme.material,
          home: PersistentIslandScreen(theme: theme, session: session),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'prestige requires confirmation; cancellation preserves all buildings',
    (tester) async {
      final session = AppSession.memory(
        save: AppSaveV1(
          wallet: 125,
          island: IslandState(
            levels: {for (final kind in BuildingKind.values) kind: 30},
          ),
        ),
        clock: () => DateTime.fromMillisecondsSinceEpoch(1000),
      );
      await show(tester, session);
      final button = find.byKey(const ValueKey('island-prestige'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Discover a new island?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(session.save.island.totalLevels, 90);
      expect(session.save.island.stars, 0);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discover island'));
      await tester.pumpAndSettle();
      expect(session.save.island.stars, 1);
      expect(session.save.island.totalLevels, 0);
      expect(session.save.wallet, 125);
      expect(find.byKey(const ValueKey('island-prestige')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('building continues from three to four with exact price', (
    tester,
  ) async {
    final session = AppSession.memory(
      save: AppSaveV1(
        wallet: 100,
        island: IslandState(
          levels: {for (final kind in BuildingKind.values) kind: 3},
        ),
      ),
      clock: () => DateTime.fromMillisecondsSinceEpoch(1000),
    );
    await show(tester, session);
    await tester.tap(find.byKey(const ValueKey('building-candyTree')));
    await tester.pumpAndSettle();
    expect(find.text('Level 3 of 30'), findsOneWidget);
    await tester.tap(find.text('Upgrade • 65 Candy Coins'));
    await tester.pumpAndSettle();
    expect(session.save.island.level(BuildingKind.candyTree), 4);
    expect(session.save.wallet, 35);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['pl', 'en']) {
    testWidgets('island economy fits320 text200% in $language', (tester) async {
      final session = AppSession.memory(
        save: AppSaveV1(
          wallet: 100,
          settings: SavedSettings(language: language),
          island: IslandState(
            stars: 3,
            levels: {for (final kind in BuildingKind.values) kind: 30},
          ),
        ),
        clock: () => DateTime.fromMillisecondsSinceEpoch(1000),
      );
      await show(tester, session, width: 320, scale: 2);
      expect(find.byType(IslandScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const ValueKey('island-prestige')));
      await tester.tap(find.byKey(const ValueKey('island-prestige')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          AppStrings.forLanguage(language)
              .text('Odkryć nową wyspę?', 'Discover a new island?'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
