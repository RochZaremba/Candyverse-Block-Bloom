import 'package:candyverse/save/application/app_session.dart';
import 'package:candyverse/app/app.dart';
import 'package:candyverse/core/feedback/feedback_service.dart';
import 'package:candyverse/core/theme/app_theme.dart';
import 'package:candyverse/game/presentation/fx_layer.dart';
import 'package:candyverse/game/presentation/game_screen.dart';
import 'package:candyverse/game/application/game_controller.dart';
import 'package:candyverse/game/domain/board.dart';
import 'package:candyverse/game/domain/game_engine.dart';
import 'package:candyverse/game/domain/game_state.dart';
import 'package:candyverse/game/domain/piece.dart';
import 'package:candyverse/settings/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/candy-feedback');
  late List<MethodCall> audio;
  late List<MethodCall> haptics;
  late AppTheme theme;
  setUpAll(() async => theme = await AppTheme.load());
  setUp(() {
    audio = [];
    haptics = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          audio.add(call);
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          haptics.add(call);
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
  test(
    'mute and haptics switches gate independent outputs and stop audio',
    () async {
      final settings = SettingsModel();
      final feedback = FeedbackService(settings, channel: channel);
      await feedback.play(CandyCue.clear);
      expect(audio.single.arguments, 'clear');
      expect(haptics.single.method, 'HapticFeedback.vibrate');
      settings.setSound(false);
      await Future<void>.delayed(Duration.zero);
      expect(audio.last.method, 'stop');
      audio.clear();
      haptics.clear();
      await feedback.play(CandyCue.place);
      expect(audio, isEmpty);
      expect(haptics, hasLength(1));
      settings.setHaptics(false);
      haptics.clear();
      await feedback.play(CandyCue.upgrade);
      expect(audio, isEmpty);
      expect(haptics, isEmpty);
      settings.setSound(true);
      await feedback.play(CandyCue.upgrade);
      expect(audio.single.arguments, 'upgrade');
      feedback.dispose();
      settings.dispose();
    },
  );
  testWidgets(
    'real moves emit clear/place FX; invalid and muted moves stay quiet',
    (tester) async {
      tester.view.physicalSize = const Size(412, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = SettingsModel();
      final feedback = FeedbackService(settings, channel: channel);
      final engine = GameEngine(
        traySource: (_) => List.filled(3, pieceCatalog.first),
      );
      final controller = GameController(
        engine: engine,
        initialState: GameState(
          board: Board.empty().withCells({
            for (var col = 0; col < 7; col++) (row: 0, col: col): 'turquoise',
          }),
          tray: List.filled(3, pieceCatalog.first),
        ),
      );
      addTearDown(() {
        feedback.dispose();
        settings.dispose();
        controller.dispose();
      });
      await tester.pumpWidget(
        SettingsScope(
          settings: settings,
          child: FeedbackScope(
            service: feedback,
            child: MaterialApp(
              theme: theme.material,
              home: GameScreen(theme: theme, controller: controller),
            ),
          ),
        ),
      );
      Future<void> place(int slot, int row, int col) async {
        await tester.tap(find.byKey(ValueKey('tray-$slot')));
        await tester.pump();
        await tester.tap(find.byKey(ValueKey('cell-$row-$col')));
        await tester.pump();
      }

      await place(0, 0, 7);
      expect(audio.single.arguments, 'clear');
      expect(
        tester.widget<FxLayer>(find.byType(FxLayer)).event!.cleared,
        hasLength(8),
      );
      await place(1, 1, 1); // No animation input delay.
      expect(audio.last.arguments, 'place');
      final snapshot = controller.state;
      await place(2, 1, 1);
      expect(controller.state, same(snapshot));
      expect(audio, hasLength(2));
      await tester.tap(find.byTooltip('Dźwięk i ruch'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile).at(0));
      await tester.pump();
      await tester.tap(find.byType(SwitchListTile).at(1));
      await tester.pump();
      expect(settings.sound, isFalse);
      expect(settings.haptics, isFalse);
      await tester.tap(find.text('Gotowe'));
      await tester.pumpAndSettle();
      audio.clear();
      haptics.clear();
      // The rejected move keeps slot 2 selected across the settings sheet.
      await tester.tap(find.byKey(const ValueKey('cell-2-2')));
      await tester.pump();
      expect(controller.state.board.at((row: 2, col: 2)), 'candyPink');
      expect(audio, isEmpty);
      expect(haptics, isEmpty);
    },
  );

  test('background stops playback and never resumes stale effects', () async {
    final settings = SettingsModel();
    final feedback = FeedbackService(settings, channel: channel);
    feedback.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(audio.single.method, 'stop');
    audio.clear();
    await feedback.play(CandyCue.place);
    expect(audio, isEmpty);
    expect(haptics, isEmpty);
    feedback.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await feedback.play(CandyCue.place);
    expect(audio.single.arguments, 'place');
    feedback.dispose();
    settings.dispose();
  });
  testWidgets('Home switches change real settings and stay accessible at 2x', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      CandyverseApp(theme: theme, session: AppSession.memory()),
    );
    await tester.ensureVisible(find.text('Dźwięk i ruch'));
    await tester.tap(find.text('Dźwięk i ruch'));
    await tester.pumpAndSettle();
    final switches = find.byType(SwitchListTile);
    expect(switches, findsNWidgets(3));
    final context = tester.element(switches.first);
    final settings = SettingsScope.maybeOf(context)!;
    await tester.tap(switches.first);
    await tester.pumpAndSettle();
    expect(settings.sound, false);
    await tester.ensureVisible(switches.at(2));
    await tester.tap(switches.at(2));
    await tester.pumpAndSettle();
    expect(settings.reduceMotion, true);
    expect(tester.takeException(), isNull);
  });
  testWidgets('FX never captures input and OS reduction prevents ticker work', (
    tester,
  ) async {
    final settings = SettingsModel();
    int tapped = 0;
    CandyFxEvent? event;
    Widget app() => SettingsScope(
      settings: settings,
      child: MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: SizedBox.square(
            dimension: 320,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => tapped++,
                    child: const ColoredBox(color: Colors.white),
                  ),
                ),
                Positioned.fill(
                  child: FxLayer(theme: theme, event: event),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(app());
    event = CandyFxEvent(
      id: 1,
      placed: [(row: 0, col: 0)],
      cleared: [(row: 0, col: 0)],
    );
    await tester.pumpWidget(app());
    await tester.tapAt(const Offset(30, 30));
    await tester.pumpAndSettle();
    expect(tapped, 1);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    settings.dispose();
  });

  testWidgets('FX animates briefly and preference or pause stops its ticker', (
    tester,
  ) async {
    final settings = SettingsModel();
    CandyFxEvent? event;
    Widget app() => SettingsScope(
      settings: settings,
      child: MaterialApp(
        home: SizedBox.square(
          dimension: 320,
          child: FxLayer(theme: theme, event: event),
        ),
      ),
    );
    await tester.pumpWidget(app());
    event = CandyFxEvent(id: 1, placed: [(row: 3, col: 4)], cleared: []);
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    event = CandyFxEvent(
      id: 2,
      placed: [(row: 3, col: 4)],
      cleared: [for (var col = 0; col < 8; col++) (row: 3, col: col)],
    );
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 80));
    settings.setReduceMotion(true);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    settings.setReduceMotion(false);
    await tester.pump();
    event = CandyFxEvent(id: 3, placed: [(row: 0, col: 0)], cleared: []);
    await tester.pumpWidget(app());
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(const SizedBox());
    settings.dispose();
  });
}
