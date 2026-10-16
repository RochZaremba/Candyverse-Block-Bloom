import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:candyverse/save/domain/app_save.dart';
import 'package:candyverse/core/theme/app_theme.dart';
import 'package:candyverse/save/application/save_bootstrap.dart';
import 'package:candyverse/save/data/save_repository.dart';

class UnreadableStorage extends MemoryStorage {
  bool fail = true;
  @override
  Future<String?> read(String key) async {
    if (fail) throw StateError('temporarily unavailable');
    return super.read(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppTheme theme;
  setUpAll(() async {
    theme = await AppTheme.load();
  });
  Future<void> show(
    WidgetTester tester,
    SaveRepository repository, {
    Locale locale = const Locale('pl'),
  }) async {
    tester.platformDispatcher.localeTestValue = locale;
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      SaveBootstrap(theme: theme, repository: repository),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('corrupt profile requires confirmation and keeps quarantine', (
    tester,
  ) async {
    final storage = MemoryStorage()..values[SaveRepository.key] = 'broken';
    await show(tester, SaveRepository(storage));
    expect(find.text('Could not open your save'), findsOneWidget);
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/candy_recovery.png'),
    );
    await tester.tap(find.text('Start fresh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(storage.values[SaveRepository.key], 'broken');
    await tester.tap(find.text('Start fresh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start fresh').last);
    await tester.pumpAndSettle();
    expect(find.text('PLAY'), findsOneWidget);
    expect(storage.values[SaveRepository.quarantineKey], 'broken');
    expect(
      AppSaveV1.decode(storage.values[SaveRepository.key]!).settings.language,
      'en',
    );
  });
  testWidgets('temporary read error exposes retry and no destructive reset', (
    tester,
  ) async {
    final storage = UnreadableStorage();
    await show(tester, SaveRepository(storage));
    expect(find.text('Start fresh'), findsNothing);
    storage.fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('PLAY'), findsOneWidget);
  });
  testWidgets('English device localizes unreadable save and recovery dialog', (
    tester,
  ) async {
    final storage = MemoryStorage()..values[SaveRepository.key] = 'broken';
    await show(
      tester,
      SaveRepository(storage),
      locale: const Locale('en', 'US'),
    );
    expect(find.text('Could not open your save'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Nie można otworzyć zapisu'), findsNothing);
    await tester.tap(find.text('Start fresh'));
    await tester.pumpAndSettle();
    expect(find.text('Replace the damaged save?'), findsOneWidget);
    expect(
      find.text(
        'Progress in this save will be lost. A local copy will remain for diagnostics.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(storage.values[SaveRepository.key], 'broken');
    expect(storage.values[SaveRepository.quarantineKey], 'broken');
    expect(find.text('Could not open your save'), findsOneWidget);
  });

  testWidgets('unsupported device language falls back to English recovery', (
    tester,
  ) async {
    final storage = MemoryStorage()..values[SaveRepository.key] = 'broken';
    await show(tester, SaveRepository(storage), locale: const Locale('de'));
    expect(find.text('Could not open your save'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  for (final savedLanguage in ['pl', 'en']) {
    testWidgets(
      'valid profile preserves saved $savedLanguage on opposite device locale',
      (tester) async {
        final storage = MemoryStorage();
        final repository = SaveRepository(storage);
        await repository.save(
          AppSaveV1(settings: SavedSettings(language: savedLanguage)),
        );
        await show(
          tester,
          repository,
          locale: Locale(savedLanguage == 'pl' ? 'en' : 'pl'),
        );
        expect(
          find.text(savedLanguage == 'pl' ? 'GRAJ' : 'PLAY'),
          findsOneWidget,
        );
        expect(storage.values[SaveRepository.quarantineKey], isNull);
      },
    );
  }
}
