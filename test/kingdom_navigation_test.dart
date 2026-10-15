import 'package:candyverse/core/localization/app_strings.dart';
import 'package:candyverse/core/presentation/candy_message.dart';
import 'package:candyverse/core/presentation/candy_transition.dart';
import 'package:candyverse/core/theme/app_theme.dart';
import 'package:candyverse/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppTheme theme;
  setUpAll(() async {
    theme = await AppTheme.load();
  });
  testWidgets(
    'new standalone Home has exactly two candy actions and accessible gear',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme.material,
          home: HomeScreen(theme: theme),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/kingdom/brand-sheet.png'),
          tester.element(find.byType(Scaffold).first),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<RawImage>(find.byType(RawImage).first).image,
        isNotNull,
      );
      expect(find.text('PLAY'), findsOneWidget);
      expect(find.text('ISLAND'), findsOneWidget);
      expect(
        find.byType(InkWell),
        findsNWidgets(3),
      ); // Two candy actions and the gear.
      final gear = find.byKey(const Key('home-settings'));
      final bounds = tester.getRect(gear);
      expect(bounds.width, greaterThanOrEqualTo(48));
      expect(bounds.height, greaterThanOrEqualTo(48));
      expect(bounds.left, lessThan(32));
      expect(bounds.top, lessThan(32));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('English fallback is independent of device language', (
    tester,
  ) async {
    late String language;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            language = AppStrings.of(context).language;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(language, 'en');
  });
  testWidgets(
    'candy dialog keeps actions accessible and messages use rendered mascot',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme.material,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => CandyDialog(
                    title: const Text('A little celebration'),
                    content: const Text('Your island is growing.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Lovely'),
                      ),
                    ],
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(CandyBrandImage), findsOneWidget);
      await tester.tap(find.text('Lovely'));
      await tester.pumpAndSettle();
      expect(find.byType(CandyDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('opaque scene transitions skip motion when the OS requests it', (
    tester,
  ) async {
    const scene = SizedBox(key: Key('scene'));
    final route = MaterialPageRoute<void>(builder: (_) => scene);
    Widget? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            result = const CandyPageTransitionsBuilder().buildTransitions(
              route,
              context,
              const AlwaysStoppedAnimation(.5),
              const AlwaysStoppedAnimation(0),
              scene,
            );
            return result!;
          },
        ),
      ),
    );
    expect(result, isA<ColoredBox>());
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    expect(identical(result, scene), isTrue);
    route.dispose();
  });
}
