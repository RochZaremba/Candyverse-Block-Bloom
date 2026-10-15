import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/feedback/feedback_service.dart';
import '../../save/application/app_session.dart';
import 'island_screen.dart';

class PersistentIslandScreen extends StatelessWidget {
  const PersistentIslandScreen({
    required this.theme,
    required this.session,
    super.key,
  });
  final AppTheme theme;
  final AppSession session;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) => IslandScreen(
      theme: theme,
      island: session.save.island,
      wallet: session.save.wallet,
      price: session.save.price,
      onPurchase: session.busy || session.resetNeedsRetry
          ? null
          : (kind) async {
              try {
                final bought = await session.purchase(kind);
                if (!context.mounted) return;
                if (bought) {
                  FeedbackScope.maybeOf(context)?.play(CandyCue.upgrade);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: appText(
                      context,
                      bought ? 'Wyspa rozkwita!' : 'Za mało Candy Coins. Zdobywasz je po zakończeniu podejścia.',
                    ),
                  ),
                );
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: appText(
                        context,
                        session.error ?? 'Błąd zapisu.',
                      ),
                    ),
                  );
                }
              }
            },
    ),
  );
}
