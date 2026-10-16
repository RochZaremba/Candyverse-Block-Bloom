import '../../core/localization/app_strings.dart';
import '../../core/presentation/candy_message.dart';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../domain/island_state.dart';
import 'island_scene.dart';
import 'kingdom_sprite.dart';
import '../../core/presentation/candy_controls.dart';
import '../../save/application/app_session_scope.dart';
import '../../settings/settings_sheet.dart';
import '../../settings/settings_screen.dart';

class IslandScreen extends StatefulWidget {
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
  State<IslandScreen> createState() => _IslandScreenState();
}

class _IslandScreenState extends State<IslandScreen> {
  int selectedTab = 0;
  AppTheme get theme => widget.theme;
  IslandState get island => widget.island;
  int? get wallet => widget.wallet;
  ValueChanged<BuildingKind>? get onPurchase => widget.onPurchase;
  int? Function(BuildingKind)? get price => widget.price;
  VoidCallback? get onCollectIncome => widget.onCollectIncome;
  VoidCallback? get onPrestige => widget.onPrestige;
  bool get incomeNeedsRetry => widget.incomeNeedsRetry;
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      bottomNavigationBar: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Row(
              children: [
                for (var i = 0; i < 4; i++) Expanded(child: _tab(context, i)),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const KingdomSprite(
            asset: 'assets/kingdom/game-scene.png',
            row: 0,
            column: 0,
            rows: 1,
            columns: 1,
            sourceRect: Rect.fromLTRB(0, 650, 941, 1672),
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => Center(
                child: SizedBox(
                  width: constraints.maxWidth.clamp(0, 540),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: SizedBox(
                            height: 48,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                FractionallySizedBox(
                                  widthFactor: .43,
                                  child: const CandyLogo(),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Semantics(
                                    label: 'Candy Coins: ${wallet ?? 0}',
                                    child: CandyPanel(
                                      radius: 24,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 5,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CandyBadge(size: 25),
                                          const SizedBox(width: 5),
                                          Text(
                                            '${wallet ?? 0}',
                                            style: const TextStyle(
                                              fontFamily: 'LilitaOne',
                                              fontSize: 17,
                                              color: candyInk,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Semantics(
                                        label: strings.text(
                                          '${island.stars} gwiazdek',
                                          '${island.stars} stars',
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              color: Color(0xffffca25),
                                              size: 25,
                                            ),
                                            Text(
                                              '${island.stars}',
                                              style: const TextStyle(
                                                fontFamily: 'LilitaOne',
                                                fontSize: 17,
                                                color: candyInk,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: strings.text(
                                          'Ustawienia',
                                          'Settings',
                                        ),
                                        onPressed: () {
                                          final session =
                                              AppSessionScope.maybeOf(context);
                                          if (session == null) {
                                            showFeedbackSettings(
                                              context,
                                              theme: theme,
                                            );
                                            return;
                                          }
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) => SettingsScreen(
                                                theme: theme,
                                                session: session,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.settings_rounded,
                                          color: candyInk,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: CandyBanner(),
                        ),
                        if (selectedTab == 0) ...[
                          Stack(
                            children: [
                              IslandScene(
                                theme: theme,
                                island: island,
                                worldIndex: island.stars % 3,
                                onBuildingTap: (kind) =>
                                    _details(context, kind),
                              ),
                              Positioned(
                                left: 8,
                                bottom: 5,
                                child: IconButton.filledTonal(
                                  tooltip: strings.translate('Wróć do menu'),
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.home_rounded),
                                ),
                              ),
                            ],
                          ),
                          if (wallet != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: CandyPanel(
                                padding: const EdgeInsets.all(2),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 7),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              strings.text(
                                                'Dochód wyspy',
                                                'Island Income',
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              '${island.incomeTenthsPerMinute * 6} / ${strings.text('godz.', 'hour')}',
                                              style: const TextStyle(
                                                fontFamily: 'LilitaOne',
                                                color: candyInk,
                                                fontSize: 21,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: CandyAction(
                                        label: strings.text(
                                          incomeNeedsRetry
                                              ? 'PONÓW'
                                              : 'ODBIERZ',
                                          incomeNeedsRetry
                                              ? 'RETRY'
                                              : 'COLLECT',
                                        ),
                                        fontSize: 21,
                                        height: 48,
                                        onPressed: onCollectIncome,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                            child: LayoutBuilder(
                              builder: (context, box) {
                                final cards = [
                                  for (final kind in BuildingKind.values)
                                    _buildingCard(context, kind),
                                ];
                                if (MediaQuery.textScalerOf(context).scale(16) >
                                    22) {
                                  return Column(
                                    children: [
                                      for (final card in cards)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: card,
                                        ),
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var i = 0; i < cards.length; i++) ...[
                                      if (i > 0) const SizedBox(width: 5),
                                      Expanded(child: cards[i]),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ),
                          if (island.canPrestige && onPrestige != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: CandyAction(
                                key: const ValueKey('island-prestige'),
                                label: strings.text(
                                  'Nowa wyspa • +1 gwiazdka',
                                  'New island • +1 star',
                                ),
                                fontSize: 22,
                                onPressed: () => _confirmPrestige(context),
                              ),
                            ),
                        ] else if (selectedTab == 1)
                          _residents(context)
                        else if (selectedTab == 2) ...[
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: CandyLettering(
                              strings.text(
                                'Twoje dekoracje',
                                'Your decorations',
                              ),
                              size: 27,
                            ),
                          ),
                          for (final kind in BuildingKind.values)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              child: _buildingCard(context, kind),
                            ),
                        ] else
                          _worldMap(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(BuildContext context, int index) {
    final s = AppStrings.of(context);
    final labels = [
      s.text('Wyspa', 'Island'),
      s.text('Mieszkańcy', 'Residents'),
      s.text('Dekoracje', 'Decorations'),
      s.text('Mapa', 'Map'),
    ];
    const icons = [
      Icons.home_rounded,
      Icons.pets_rounded,
      Icons.local_florist_rounded,
      Icons.map_rounded,
    ];
    return Semantics(
      selected: selectedTab == index,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: selectedTab == index
              ? const Color(0xffff59b7)
              : const Color(0xfffff7eb),
          borderRadius: BorderRadius.circular(25),
          child: InkWell(
            key: ValueKey('island-tab-$index'),
            borderRadius: BorderRadius.circular(25),
            onTap: () => setState(() => selectedTab = index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icons[index],
                    color: selectedTab == index
                        ? Colors.white
                        : const Color(0xff9851b6),
                    size: 28,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'LilitaOne',
                      fontSize: 12,
                      color: selectedTab == index
                          ? Colors.white
                          : const Color(0xff8741a4),
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

  Widget _buildingCard(BuildContext context, BuildingKind kind) {
    final s = AppStrings.of(context);
    final level = island.level(kind);
    final cost = price?.call(kind);
    return InkWell(
      onTap: () => _details(context, kind),
      borderRadius: BorderRadius.circular(16),
      child: CandyPanel(
        radius: 16,
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            if (MediaQuery.textScalerOf(context).scale(16) <= 22)
              SizedBox(
                height: 16,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    s.translate(buildingName(kind)),
                    style: const TextStyle(
                      fontFamily: 'LilitaOne',
                      color: candyInk,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else
              Text(
                s.translate(buildingName(kind)),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'LilitaOne',
                  color: candyInk,
                  fontSize: 16,
                ),
              ),
            Text(
              s.text('Poz. $level / 30', 'Lv. $level / 30'),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
            ),
            SizedBox(
              height: 40,
              child: BuildingArtwork(kind: kind, level: level),
            ),
            if (onPurchase != null && level < IslandState.maxLevel)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: ValueKey('upgrade-card-${kind.name}'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xff48d721),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 6,
                    ),
                    minimumSize: const Size(48, 48),
                    textStyle: const TextStyle(
                      fontFamily: 'LilitaOne',
                      fontSize: 12,
                    ),
                  ),
                  onPressed: () => onPurchase!(kind),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.translate('Rozbuduj')),
                      if (cost != null)
                        Text('$cost', style: const TextStyle(fontSize: 17)),
                    ],
                  ),
                ),
              )
            else
              TextButton(
                onPressed: () => _details(context, kind),
                child: Text(s.text('Szczegóły', 'Details')),
              ),
          ],
        ),
      ),
    );
  }

  Widget _residents(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        CandyLettering(
          AppStrings.of(context).text('Nasi mieszkańcy', 'Our residents'),
          size: 28,
        ),
        const SizedBox(height: 12),
        for (final kind in CandyCharacter.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CandyPanel(
              child: ListTile(
                leading: SizedBox(
                  width: 58,
                  height: 58,
                  child: KingdomSprite(
                    asset: 'assets/kingdom/reference-mascots.png',
                    row: kind.index ~/ 2,
                    column: kind.index % 2,
                    rows: 3,
                    columns: 2,
                  ),
                ),
                title: Text(
                  characterName(kind),
                  style: const TextStyle(
                    fontFamily: 'LilitaOne',
                    color: candyInk,
                  ),
                ),
                onTap: () => showCandyMessage(
                  context,
                  AppStrings.of(context)
                      .translate('${characterName(kind)} wita Cię'),
                  success: true,
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _worldMap(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        CandyLettering(
          AppStrings.of(context)
              .text('Twoje cukierkowe światy', 'Your candy worlds'),
          size: 27,
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CandyPanel(
              child: Column(
                children: [
                  SizedBox(
                    height: 110,
                    child: KingdomSprite(
                      asset: 'assets/kingdom/worlds.png',
                      row: i,
                      column: 0,
                      rows: 3,
                      columns: 1,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Text(
                    AppStrings.of(context).text(
                      'Świat ${i + 1}${i == island.stars % 3 ? ' • obecny' : ''}',
                      'World ${i + 1}${i == island.stars % 3 ? ' • current' : ''}',
                    ),
                    style: const TextStyle(
                      fontFamily: 'LilitaOne',
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Text(
          AppStrings.of(context).text(
            'Rozbuduj wszystkie 3 obiekty do poziomu 30, aby odkryć nową wyspę i zdobyć gwiazdkę.',
            'Grow all 3 buildings to level 30 to discover a new island and earn a star.',
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
