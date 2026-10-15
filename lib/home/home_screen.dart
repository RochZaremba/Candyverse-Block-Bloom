import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/localization/app_strings.dart';
import '../core/presentation/candy_message.dart';
import '../core/theme/app_theme.dart';
import '../game/presentation/game_screen.dart';
import '../settings/settings_sheet.dart';
import '../settings/settings_screen.dart';
import '../settings/settings_model.dart';
import '../island/presentation/persistent_island_screen.dart';
import '../core/feedback/feedback_service.dart';
import 'candy_backdrop.dart';
import '../island/domain/island_state.dart';
import '../save/application/app_session.dart';
import '../island/presentation/island_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.theme, this.island, this.session, super.key});
  final AppTheme theme;
  final IslandState? island;
  final AppSession? session;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  bool foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _updateMotion() {
    if (foreground &&
        !SettingsScope.reducedMotionOf(context) &&
        TickerMode.valuesOf(context).enabled) {
      if (!motion.isAnimating) motion.repeat();
    } else {
      motion.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    _updateMotion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final session = widget.session;
    final strings = AppStrings.of(context);
    return Scaffold(
      body: CandyBackdrop(
        theme: theme,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 72, 24, 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: motion,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(
                              0,
                              math.sin(motion.value * math.pi * 2) * 4,
                            ),
                            child: child,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x335c348f),
                                  blurRadius: 24,
                                  offset: Offset(0, 10),
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: const AspectRatio(
                                aspectRatio: 3,
                                child: CandyBrandImage(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          strings.text(
                            'Twoja mała kraina szczęścia',
                            'Your little kingdom of joy',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: theme.color('ink'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .82),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text(
                            session == null
                                ? strings.text(
                                    'Ułóż. Połącz. Rozkwitaj.',
                                    'Place. Connect. Bloom.',
                                  )
                                : strings.text(
                                    'Rekord: ${session.save.bestScore}  •  Candy Coins: ${session.save.wallet}',
                                    'Best: ${session.save.bestScore}  •  Candy Coins: ${session.save.wallet}',
                                  ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 26),
                        _CandyMenuButton(
                          key: const Key('home-play'),
                          label: session?.busy == true
                              ? strings.text('Zapisuję…', 'Saving…')
                              : strings.text('GRAJ', 'PLAY'),
                          icon: Icons.play_arrow_rounded,
                          colors: const [Color(0xffffd964), Color(0xffffa931)],
                          onPressed:
                              session?.busy == true ||
                                  session?.resetNeedsRetry == true
                              ? null
                              : () async {
                                  FeedbackScope.maybeOf(context)
                                      ?.play(CandyCue.place);
                                  try {
                                    final controller = await session?.openRun();
                                    if (!context.mounted) return;
                                    await Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => GameScreen(
                                          theme: theme,
                                          controller: controller,
                                        ),
                                      ),
                                    );
                                  } catch (_) {
                                    if (context.mounted) {
                                      showCandyMessage(
                                        context,
                                        strings.translate(
                                          session?.error ??
                                              'Błąd zapisu. Spróbuj ponownie.',
                                        ),
                                      );
                                    }
                                  }
                                },
                        ),
                        const SizedBox(height: 18),
                        _CandyMenuButton(
                          key: const Key('home-island'),
                          label: strings.text('WYSPA', 'ISLAND'),
                          icon: Icons.landscape_rounded,
                          colors: const [Color(0xff78efd2), Color(0xff32c5bd)],
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => session == null
                                  ? IslandScreen(
                                      theme: theme,
                                      island: widget.island ?? IslandState(),
                                    )
                                  : PersistentIslandScreen(
                                      theme: theme,
                                      session: session,
                                    ),
                            ),
                          ),
                        ),
                        if (session?.error != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            strings.translate(session!.error!),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 22),
                        Text(
                          strings.text(
                            'Twój świat rozkwita bez pośpiechu.',
                            'Let your world bloom at your own pace.',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.color('ink'),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .9),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x225c348f),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    key: const Key('home-settings'),
                    tooltip: strings.text('Ustawienia', 'Settings'),
                    icon: const Icon(Icons.settings_rounded),
                    iconSize: 28,
                    constraints: const BoxConstraints(
                      minWidth: 52,
                      minHeight: 52,
                    ),
                    onPressed: () {
                      if (session == null) {
                        showFeedbackSettings(context, theme: theme);
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              SettingsScreen(theme: theme, session: session),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CandyMenuButton extends StatelessWidget {
  const _CandyMenuButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onPressed,
    super.key,
  });
  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Container(
    width: 320,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
          color: colors.last.withValues(alpha: .48),
          offset: const Offset(0, 7),
          blurRadius: 0,
        ),
        const BoxShadow(
          color: Color(0x225c348f),
          offset: Offset(0, 12),
          blurRadius: 18,
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: Colors.white.withValues(alpha: .85),
            width: 3,
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 34, color: const Color(0xff382453)),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: Color(0xff382453),
                      letterSpacing: 1.5,
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
}
