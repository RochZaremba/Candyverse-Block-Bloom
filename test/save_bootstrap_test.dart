import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  Future<void> show(WidgetTester tester, SaveRepository repository) async {
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
    expect(find.text('Nie można otworzyć zapisu'), findsOneWidget);
    await tester.tap(find.text('Rozpocznij od nowa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anuluj'));
    await tester.pumpAndSettle();
    expect(storage.values[SaveRepository.key], 'broken');
    await tester.tap(find.text('Rozpocznij od nowa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rozpocznij od nowa').last);
    await tester.pumpAndSettle();
    expect(find.text('GRAJ'), findsOneWidget);
    expect(storage.values[SaveRepository.quarantineKey], 'broken');
    expect(storage.values[SaveRepository.key], isNull);
  });
  testWidgets('temporary read error exposes retry and no destructive reset', (
    tester,
  ) async {
    final storage = UnreadableStorage();
    await show(tester, SaveRepository(storage));
    expect(find.text('Rozpocznij od nowa'), findsNothing);
    storage.fail = false;
    await tester.tap(find.text('Spróbuj ponownie'));
    await tester.pumpAndSettle();
    expect(find.text('GRAJ'), findsOneWidget);
  });
}
