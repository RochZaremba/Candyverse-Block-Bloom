import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/presentation/candy_message.dart';
import '../../core/theme/app_theme.dart';
import '../../core/feedback/feedback_service.dart';
import '../../save/application/app_session.dart';
import 'island_screen.dart';

class PersistentIslandScreen extends StatefulWidget {
  const PersistentIslandScreen({
    required this.theme,
    required this.session,
    super.key,
  });
  final AppTheme theme;
  final AppSession session;
  @override
  State<PersistentIslandScreen> createState() => _PersistentIslandScreenState();
}

class _PersistentIslandScreenState extends State<PersistentIslandScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || widget.session.incomeNeedsRetry) return;
      try {
        await widget.session.collectIncome();
      } catch (_) {
        if (mounted) showCandyMessage(context, widget.session.error!);
      }
    });
  }

  Future<void> _collect() async {
    try {
      final session = widget.session;
      if (session.incomeNeedsRetry) {
        await session.retryIncomeSave();
        if (!mounted) return;
        showCandyMessage(
          context,
          AppStrings.of(context).text('Wyspa zapisana!', 'Island saved!'),
          success: true,
        );
      } else {
        final coins = await session.collectIncome();
        if (!mounted) return;
        showCandyMessage(
          context,
          AppStrings.of(context).text(
            coins > 0
                ? 'Odebrano $coins Candy Coins!'
                : 'Dochód jest aktualny. Wyspa zarabia także podczas przerwy.',
            coins > 0
                ? 'Collected $coins Candy Coins!'
                : 'Income is up to date. Your island earns while you are away.',
          ),
          success: coins > 0,
        );
      }
    } catch (_) {
      if (mounted) {
        showCandyMessage(
          context,
          widget.session.error ??
              AppStrings.of(context).text('Błąd zapisu.', 'Save failed.'),
        );
      }
    }
  }

  Future<void> _prestige() async {
    try {
      if (await widget.session.prestige() && mounted) {
        FeedbackScope.maybeOf(context)?.play(CandyCue.fanfare);
        showCandyMessage(
          context,
          AppStrings.of(
            context,
          ).text('Nowa wyspa i nowa gwiazdka!', 'A new island and a new star!'),
          success: true,
        );
      }
    } catch (_) {
      if (mounted) {
        showCandyMessage(
          context,
          widget.session.error ??
              AppStrings.of(context).text('Błąd zapisu.', 'Save failed.'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.session,
    builder: (context, _) {
      final session = widget.session;
      final canAct = !session.busy && !session.resetNeedsRetry;
      return IslandScreen(
        theme: widget.theme,
        island: session.save.island,
        wallet: session.save.wallet,
        price: session.save.price,
        incomeNeedsRetry: session.incomeNeedsRetry,
        onCollectIncome: canAct ? _collect : null,
        onPrestige: canAct && !session.incomeNeedsRetry ? _prestige : null,
        onPurchase: !canAct || session.incomeNeedsRetry
            ? null
            : (kind) async {
                try {
                  final bought = await session.purchase(kind);
                  if (!context.mounted) return;
                  if (bought) {
                    FeedbackScope.maybeOf(context)?.play(CandyCue.fanfare);
                  }
                  showCandyMessage(
                    context,
                    AppStrings.of(context).text(
                      bought ? 'Wyspa rozkwita!' : 'Za mało Candy Coins. Zdobywasz je w grze i dzięki rozbudowie wyspy.',
                      bought ? 'Your island is blooming!' : 'Not enough Candy Coins. Earn them by playing and growing your island.',
                    ),
                    success: bought,
                  );
                } catch (_) {
                  if (context.mounted) {
                    showCandyMessage(
                      context,
                      session.error ??
                          AppStrings.of(context)
                              .text('Błąd zapisu.', 'Save failed.'),
                    );
                  }
                }
              },
      );
    },
  );
}
