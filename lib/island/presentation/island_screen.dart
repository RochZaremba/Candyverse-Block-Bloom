import '../../core/localization/app_strings.dart';

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
    super.key,
  });
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
                    subtitle: appText(
                      context,
                      'Poziom ${island.level(kind)}/3',
                    ),
                    onTap: () => _details(context, kind),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  void _details(BuildContext context, BuildingKind kind) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: appText(context, buildingName(kind)),
        content: appText(
          context,
          'Poziom ${island.level(kind)} z 3.\n${switch (kind) {
            BuildingKind.candyTree => 'Miękkie korony pełne kolorowych cukierków.',
            BuildingKind.jellyHouse => 'Przytulny galaretkowy domek dla mieszkańców.',
            BuildingKind.rainbowFountain => 'Tęczowe łuki nad błękitną wodą.',
          }}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: appText(context, 'Wróć na wyspę'),
          ),
          if (onPurchase != null && island.level(kind) < 3)
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
}
