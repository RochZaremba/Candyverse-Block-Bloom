import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:candyverse/core/theme/app_theme.dart';
import 'package:candyverse/save/application/app_session.dart';
import 'package:candyverse/save/data/save_repository.dart';
import 'package:candyverse/save/domain/app_save.dart';
import 'package:candyverse/settings/settings_model.dart';
import 'package:candyverse/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ResetStorage extends MemoryStorage {
  String? failRemove;
  bool failWrite = false;
  Completer<void>? gate;
  @override
  Future<void> remove(String key) async {
    if (key == failRemove) throw StateError('remove failed');
    await super.remove(key);
  }

  @override
  Future<void> write(String key, String value) async {
    if (gate != null) await gate!.future;
    if (failWrite) throw StateError('write failed');
    await super.write(key, value);
  }
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppTheme theme;
  setUpAll(() async {
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
    theme = await AppTheme.load();
  });
  test('language restores and persists with full snapshot', () async {
    final repository = SaveRepository(MemoryStorage());
    final session = AppSession(
      repository,
      AppSaveV1(wallet: 45, settings: const SavedSettings(language: 'pl')),
    );
    session.settings.setLanguage('en');
    await session.flushSettings();
    expect((await repository.load()).settings.language, 'en');
    expect((await repository.load()).wallet, 45);
    expect(() => session.settings.setLanguage('fr'), throwsArgumentError);
    session.dispose();
  });

  test(
    'failed preference save offers actual retry without losing progress',
    () async {
      final storage = ResetStorage();
      final repository = SaveRepository(storage);
      final session = AppSession(
        repository,
        AppSaveV1(wallet: 45, settings: const SavedSettings(language: 'pl')),
      );
      await repository.save(session.save);
      storage.failWrite = true;
      session.settings.setLanguage('en');
      await session.flushSettings();
      expect(session.error, isNotNull);
      expect((await repository.load()).settings.language, 'pl');
      storage.failWrite = false;
      await session.retrySettingsSave();
      expect(session.error, isNull);
      expect((await repository.load()).settings.language, 'en');
      expect((await repository.load()).wallet, 45);
      session.dispose();
    },
  );

  test('reset waits for writes and clears profile plus diagnostics', () async {
    final storage = ResetStorage();
    final repository = SaveRepository(storage);
    final session = AppSession(
      repository,
      AppSaveV1(wallet: 45, settings: const SavedSettings(language: 'pl')),
    );
    final old = await session.openRun();
    storage.values[SaveRepository.quarantineKey] = '{bad';
    storage.gate = Completer<void>();
    session.settings.setLanguage('en');
    await settle(); // Let the accepted write reach its storage gate.
    final resetting = session.resetData();
    await settle();
    expect(session.busy, isTrue);
    await expectLater(session.openRun(), throwsStateError);
    storage.gate!.complete();
    await resetting;
    expect(storage.values, isEmpty);
    expect(session.save.wallet, 0);
    expect(session.save.activeRun, isNull);
    expect(session.settings.language, 'en');
    // A retained callback from a popped screen cannot resurrect the old profile.
    await expectLater(old.onSnapshot!(old.state), throwsStateError);
    final next = await session.openRun();
    expect(identical(next, old), isFalse);
    expect(session.save.activeRun!.id, 1);
    session.dispose();
  });

  test('reset waits for accepted game checkpoint before deleting it', () async {
    final storage = ResetStorage();
    final repository = SaveRepository(storage);
    final session = AppSession(repository, AppSaveV1(), seedSource: () => 5);
    final controller = await session.openRun();
    storage.gate = Completer<void>();
    final origin = controller.engine
        .getLegalPlacements(
          controller.state.board,
          controller.state.tray.first!,
        )
        .first;
    expect(controller.place(0, origin).accepted, isTrue);
    final resetting = session.resetData();
    await settle();
    expect(session.busy, isTrue);
    storage.gate!.complete();
    await resetting;
    expect(storage.values, isEmpty);
    expect(session.save.activeRun, isNull);
    session.dispose();
  });

  for (final key in [SaveRepository.quarantineKey, SaveRepository.key]) {
    test('reset failure at $key retains profile and live controller', () async {
      final storage = ResetStorage();
      final repository = SaveRepository(storage);
      final session = AppSession(
        repository,
        AppSaveV1(wallet: 45, settings: const SavedSettings(language: 'pl')),
      );
      final old = await session.openRun();
      final raw = session.save.encode();
      storage.values[SaveRepository.quarantineKey] = '{bad';
      storage.failRemove = key;
      await expectLater(session.resetData(), throwsStateError);
      expect(session.save.encode(), raw);
      expect((await repository.load()).encode(), raw);
      expect(identical(await session.openRun(), old), isTrue);
      storage.failRemove = null;
      await session.resetData();
      expect(session.save.wallet, 0);
      session.dispose();
    });
  }

  Future<AppSession> pumpSettings(
    WidgetTester tester,
    double width,
    String language, {
    AppSession? existing,
  }) async {
    tester.view.physicalSize = Size(width, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session =
        existing ??
        AppSession.memory(
          save: AppSaveV1(
            wallet: 40,
            settings: SavedSettings(language: language),
          ),
        );
    addTearDown(session.dispose);
    await tester.pumpWidget(
      SettingsScope(
        settings: session.settings,
        child: MaterialApp(
          theme: theme.material,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: SettingsScreen(theme: theme, session: session),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    return session;
  }

  for (final width in [320.0, 412.0]) {
    for (final language in ['pl', 'en']) {
      testWidgets('settings $width $language text2 privacy and reset confirm', (
        tester,
      ) async {
        final session = await pumpSettings(tester, width, language);
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.byKey(const Key('reset-data')),
          250,
        );
        await tester.tap(find.byKey(const Key('reset-data')));
        await tester.pumpAndSettle();
        expect(session.save.wallet, 40);
        expect(find.byKey(const Key('confirm-reset')), findsOneWidget);
        await tester.tap(find.text(language == 'pl' ? 'Anuluj' : 'Cancel'));
        await tester.pumpAndSettle();
        expect(session.save.wallet, 40);
        await tester.tap(find.byKey(const Key('reset-data')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirm-reset')));
        await tester.pumpAndSettle();
        expect(session.save.wallet, 0);
        expect(session.settings.language, 'en');
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('failed confirmed reset keeps coins and supports retry', (
    tester,
  ) async {
    final storage = ResetStorage();
    final repository = SaveRepository(storage);
    final value = AppSaveV1(
      wallet: 40,
      settings: const SavedSettings(language: 'pl'),
    );
    await repository.save(value);
    final session = AppSession(repository, value);
    storage.failRemove = SaveRepository.key;
    await pumpSettings(tester, 412, 'pl', existing: session);
    await tester.scrollUntilVisible(find.byKey(const Key('reset-data')), 250);
    await tester.tap(find.byKey(const Key('reset-data')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-reset')));
    await tester.pumpAndSettle();
    expect(session.save.wallet, 40);
    expect(
      find.text('Nie udało się usunąć danych. Spróbuj ponownie.'),
      findsOneWidget,
    );
    storage.failRemove = null;
    await tester.tap(find.byTooltip('Zamknij komunikat'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('reset-data')),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('reset-data')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-reset')));
    await tester.pumpAndSettle();
    expect(session.save.wallet, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings visual reference at 412 text2', (tester) async {
    await pumpSettings(tester, 412, 'pl');
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/settings_412.png'),
    );
  });

  testWidgets('privacy opens actual local information and language updates', (
    tester,
  ) async {
    final session = await pumpSettings(tester, 412, 'pl');
    await tester.scrollUntilVisible(find.text('English'), 180);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(session.settings.language, 'en');
    expect(find.text('Settings'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Privacy'), 180);
    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();
    expect(find.textContaining('rochzaremba@gmail.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.textContaining('rochzaremba@gmail.com'), findsNothing);
  });
}
