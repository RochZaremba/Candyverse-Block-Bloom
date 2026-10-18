import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/presentation/candy_controls.dart';
import '../domain/evolution.dart';

class EvolutionPanel extends StatelessWidget {
  const EvolutionPanel({
    required this.evolution,
    required this.onBomb,
    required this.onRainbow,
    this.targeting = false,
    super.key,
  });
  final Evolution evolution;
  final VoidCallback? onBomb, onRainbow;
  final bool targeting;

  @override
  Widget build(BuildContext context) {
    final e = evolution;
    final s = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: CandyPanel(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              s.text('Ewolucja rozgrywki', 'Run evolution'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            Text(
              e.maxed
                  ? s.text('Wszystkie ścieżki rozwinięte', 'All paths evolved')
                  : s.text(
                      'Następna karta za ${5 - e.moves % 5} ruchów lub próg linii.',
                      'Next card in ${5 - e.moves % 5} moves or a line milestone.',
                    ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                Text('Explosive Candy ${e.explosive}/4'),
                Text('Rainbow Magic ${e.rainbow}/4'),
                Text('Lucky Paws ${e.paws}/4'),
              ],
            ),
            if (e.explosive > 0) ...[
              Text(
                s.text(
                  'Ładowanie: ${e.rowProgress}/${e.rowsPerCharge} wierszy • ${e.bombCharges}/3 bomb',
                  'Charge: ${e.rowProgress}/${e.rowsPerCharge} rows • ${e.bombCharges}/3 bombs',
                ),
              ),
              const SizedBox(height: 6),
              CandyAction(
                key: const Key('evolution-bomb'),
                height: 54,
                fontSize: 18,
                label: targeting
                    ? s.text('Anuluj celowanie', 'Cancel targeting')
                    : s.text('Użyj bomby', 'Use bomb'),
                onPressed: onBomb,
              ),
            ],
            if (e.rainbow > 0) ...[
              const SizedBox(height: 6),
              Text(
                e.rainbowReady
                    ? s.text('Tęcza gotowa', 'Rainbow ready')
                    : s.text(
                        'Tęcza za ${e.rainbowCooldown} ruchów',
                        'Rainbow in ${e.rainbowCooldown} moves',
                      ),
              ),
              CandyAction(
                key: const Key('evolution-rainbow'),
                height: 54,
                fontSize: 18,
                label: s.text('Wymień kształt', 'Swap shape'),
                onPressed: onRainbow,
              ),
            ],
            if (e.paws > 0)
              Text(
                s.text(
                  'Combo: +${40 * e.paws} pkt • +${2 * e.paws} monet${e.paws == 4 ? ' +2 za linię' : ''}',
                  'Combo: +${40 * e.paws} points • +${2 * e.paws} coins${e.paws == 4 ? ' +2 per line' : ''}',
                ),
                textAlign: TextAlign.center,
              ),
            for (final name in e.synergies)
              Text(
                '${s.text('Synergia', 'Synergy')}: $name',
                style: const TextStyle(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
            if (e.synergies.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  s.text('Jak działają synergie?', 'How do synergies work?'),
                ),
                children: [
                  if (e.rainbowExplosion)
                    Text(
                      s.text(
                        'Rainbow Explosion: wymiana ładuje następną bombę; wybierz kolor do usunięcia.',
                        'Rainbow Explosion: a swap primes the next bomb; choose a color to clear.',
                      ),
                    ),
                  if (e.goldenExplosion)
                    Text(
                      s.text(
                        'Golden Explosion: każda zniszczona komórka daje 1 monetę.',
                        'Golden Explosion: each destroyed cell earns 1 coin.',
                      ),
                    ),
                  if (e.luckySpectrum)
                    Text(
                      s.text(
                        'Lucky Spectrum: wymiana daje 2 monety.',
                        'Lucky Spectrum: a swap earns 2 coins.',
                      ),
                    ),
                  if (e.constellation)
                    Text(
                      s.text(
                        'Candy Constellation: combo dodaje 1 bombę, maks. 3.',
                        'Candy Constellation: a combo adds 1 bomb, up to 3.',
                      ),
                    ),
                  Text(
                    s.text(
                      'Combo to co najmniej 2 linie naraz lub kolejne czyszczenie. Bonusy wypłacamy na końcu podejścia.',
                      'A combo is at least 2 lines at once or consecutive clearing moves. Bonuses are paid when the run ends.',
                    ),
                  ),
                ],
              ),
            if (e.rainbowPrimed)
              Text(
                s.text(
                  'Rainbow Explosion gotowa — wybierz kolor przy bombie.',
                  'Rainbow Explosion primed — choose a color when bombing.',
                ),
                textAlign: TextAlign.center,
              ),
            if (targeting)
              Text(
                s.text(
                  'Dotknij zajętego pola. Zobaczysz podgląd przed potwierdzeniem.',
                  'Tap an occupied cell. Preview before confirming.',
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
