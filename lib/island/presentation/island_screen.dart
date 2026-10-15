import '../../core/localization/app_strings.dart';
import '../../core/presentation/candy_message.dart';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../home/candy_backdrop.dart';
import '../domain/island_state.dart';
import 'island_scene.dart';

class IslandScreen extends StatelessWidget {
  const IslandScreen({
    required this.theme,
    required this.island,
    this.wallet,
    this.onPurchase,
    this.price,
    this.onCollectIncome,
    this.onPrestige,
    this.incomeNeedsRetry = false,
    super.key,
  });
  final VoidCallback? onCollectIncome, onPrestige;
  final bool incomeNeedsRetry;
  final AppTheme theme;
  final IslandState island;
  final int? wallet;
  final ValueChanged<BuildingKind>? onPurchase;
  final int? Function(BuildingKind)? price;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: CandyBackdrop(
      theme: theme,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: AppStrings.of(context).translate('Wróć do menu'),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: appText(
                      context,
                      'Twoja cukierkowa wyspa',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 12),
              if (wallet != null)
                appText(
                  context,
                  'Candy Coins: $wallet',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (wallet != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.color('creamWhite'),
                    borderRadius: BorderRadius.circular(theme.cardRadius),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFE09B00),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              AppStrings.of(context).text(
                                '${island.stars} gwiazdek • +${island.stars * 10}% dochodu',
                                '${island.stars} stars • +${island.stars * 10}% income',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.of(context).text(
                          'Dochód: ${_incomeRate()} Candy Coins / min',
                          'Income: ${_incomeRate()} Candy Coins / min',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.of(context).text(
                          'Twoja wyspa zarabia także podczas przerwy. Bez limitu odbioru.',
                          'Your island earns while you are away. No collection limit.',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      if (onCollectIncome != null)
                        OutlinedButton.icon(
                          onPressed: onCollectIncome,
                          icon: Icon(
                            incomeNeedsRetry
                                ? Icons.refresh_rounded
                                : Icons.savings_rounded,
                          ),
                          label: Text(
                            AppStrings.of(context).text(
                              incomeNeedsRetry
                                  ? 'Ponów zapis wyspy'
                                  : 'Odbierz dochód',
                              incomeNeedsRetry
                                  ? 'Retry island save'
                                  : 'Collect income',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: IslandScene(
                  theme: theme,
                  island: island,
                  onBuildingTap: (kind) => _details(context, kind),
                ),
              ),
              appText(
                context,
                'Dotknij mieszkańca, aby się przywitać.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              for (final kind in BuildingKind.values)
                Card(
                  elevation: 3,
                  shadowColor: theme.color('ink').withValues(alpha: .12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(theme.cardRadius),
                  ),
                  color: theme.color('creamWhite'),
                  child: ListTile(
                    title: appText(context, buildingName(kind)),
                    subtitle: Text(
                      AppStrings.of(context).text(
                        'Poziom ${island.level(kind)}/30',
                        'Level ${island.level(kind)}/30',
                      ),
                    ),
                    onTap: () => _details(context, kind),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              if (wallet != null) ...[
                const SizedBox(height: 16),
                Text(
                  AppStrings.of(context).text(
                    'Rozbuduj wszystkie 3 obiekty do poziomu 30, aby odkryć nową wyspę i zdobyć gwiazdkę.',
                    'Grow all 3 buildings to level 30 to discover a new island and earn a star.',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (island.canPrestige && onPrestige != null)
                  FilledButton.icon(
                    key: const ValueKey('island-prestige'),
                    onPressed: () => _confirmPrestige(context),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(
                      AppStrings.of(context).text(
                        'Nowa wyspa • +1 gwiazdka',
                        'New island • +1 star',
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
  void _details(BuildContext context, BuildingKind kind) {
    showDialog<void>(
      context: context,
      builder: (context) => CandyDialog(
        title: appText(context, buildingName(kind)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.of(context).text(
                'Poziom ${island.level(kind)} z 30',
                'Level ${island.level(kind)} of 30',
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: island.level(kind) / IslandState.maxLevel,
            ),
            const SizedBox(height: 12),
            appText(context, switch (kind) {
              BuildingKind.candyTree =>
                'Miękkie korony pełne kolorowych cukierków.',
              BuildingKind.jellyHouse =>
                'Przytulny galaretkowy domek dla mieszkańców.',
              BuildingKind.rainbowFountain => 'Tęczowe łuki nad błękitną wodą.',
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: appText(context, 'Wróć na wyspę'),
          ),
          if (onPurchase != null && island.level(kind) < IslandState.maxLevel)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                onPurchase!(kind);
              },
              child: appText(
                context,
                price == null
                    ? 'Rozbuduj'
                    : 'Rozbuduj • ${price!(kind)} Candy Coins',
              ),
            ),
        ],
      ),
    );
  }

  String _incomeRate() {
    final rate = island.incomeTenthsPerMinute;
    return rate % 10 == 0 ? '${rate ~/ 10}' : '${rate ~/ 10}.${rate % 10}';
  }

  Future<void> _confirmPrestige(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => CandyDialog(
        title: Text(
          AppStrings.of(context)
              .text('Odkryć nową wyspę?', 'Discover a new island?'),
        ),
        content: Text(
          AppStrings.of(context).text(
            'Trzy budynki wrócą do poziomu 0. Zyskasz 1 trwałą gwiazdkę i +10% dochodu. Zachowasz monety, rekord, grę i ustawienia.',
            'Your three buildings return to level 0. Earn 1 permanent star and +10% income. Keep your coins, best score, game and settings.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: appText(context, 'Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppStrings.of(context).text('Odkryj wyspę', 'Discover island'),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) onPrestige?.call();
  }
}
