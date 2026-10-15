import 'package:flutter/material.dart';

import '../../settings/settings_model.dart';

/// Exactly the two V1 languages. Named candy characters/upgrades retain names.
class AppStrings {
  const AppStrings.forLanguage(this.language);
  final String language;
  static AppStrings of(BuildContext context) =>
      AppStrings.forLanguage(SettingsScope.maybeOf(context)?.language ?? 'en');
  String text(String pl, String en) => language == 'en' ? en : pl;
  String translate(String value) {
    if (language != 'en') return value;
    final exact = _english[value];
    if (exact != null) return exact;
    for (final entry in _patterns) {
      final match = entry.$1.firstMatch(value);
      if (match != null) return entry.$2(match, this);
    }
    return value;
  }
}

Text appText(
  BuildContext context,
  String data, {
  TextStyle? style,
  TextAlign? textAlign,
  int? maxLines,
  TextOverflow? overflow,
}) => Text(
  AppStrings.of(context).translate(data),
  style: style,
  textAlign: textAlign,
  maxLines: maxLines,
  overflow: overflow,
);

final _patterns = <(RegExp, String Function(Match, AppStrings))>[
  (
    RegExp(r'^Rekord: (\d+)  •  Candy Coins: (\d+)$'),
    (m, _) => 'Best: ${m[1]}  •  Candy Coins: ${m[2]}',
  ),
  (
    RegExp(r'^Następne ulepszenie: (\d+)/(\d+) linii$'),
    (m, _) => 'Next upgrade: ${m[1]}/${m[2]} lines',
  ),
  (
    RegExp(r'^Usunięte linie: (\d+)\. Pięknie!$'),
    (m, _) => 'Lines cleared: ${m[1]}. Lovely!',
  ),
  (
    RegExp(r'^Pozostałe wybory: (\d+)$'),
    (m, _) => 'Choices remaining: ${m[1]}',
  ),
  (RegExp(r'^Poziom (\d+)/3$'), (m, _) => 'Level ${m[1]}/3'),
  (
    RegExp(r'^Poziom (\d+) z 3\.\n([\s\S]+)$'),
    (m, s) => 'Level ${m[1]} of 3.\n${s.translate(m[2]!)}',
  ),
  (
    RegExp(r'^Rozbuduj • (\d+) Candy Coins$'),
    (m, _) => 'Upgrade • ${m[1]} Candy Coins',
  ),
  (
    RegExp(r'^(.+), poziom (\d+)$'),
    (m, s) => '${s.translate(m[1]!)}, level ${m[2]}',
  ),
  (RegExp(r'^(.+) wita Cię$'), (m, _) => '${m[1]} greets you'),
  (
    RegExp(r'^Wiersz (\d+), kolumna (\d+), (puste|zajęte)$'),
    (m, s) => 'Row ${m[1]}, column ${m[2]}, ${s.translate(m[3]!)}',
  ),
  (
    RegExp(
      r'^Wiersz (\d+), kolumna (\d+)\. Zużyjesz jedno użycie Rainbow Eraser\. Bez punktów i monet\.$',
    ),
    (m, _) =>
        'Row ${m[1]}, column ${m[2]}. This uses one Rainbow Eraser charge. No points or coins.',
  ),
  (
    RegExp(r'^pozioma linia, (\d+) pól$'),
    (m, _) => 'horizontal line, ${m[1]} cells',
  ),
  (
    RegExp(r'^pionowa linia, (\d+) pól$'),
    (m, _) => 'vertical line, ${m[1]} cells',
  ),
  (RegExp(r'^(\d+) pól$'), (m, _) => '${m[1]} cells'),
  (RegExp(r'^Klocek (\d+) zużyty$'), (m, _) => 'Piece ${m[1]} used'),
  (
    RegExp(r'^Klocek (\d+), (.+)\. Wybierz, następnie pole planszy\.$'),
    (m, s) =>
        'Piece ${m[1]}, ${s.translate(m[2]!)}. Select, then choose a board cell.',
  ),
];
const _english = <String, String>{
  'Ułóż. Połącz. Rozkwitaj.': 'Place. Connect. Bloom.',
  'GRAJ': 'PLAY',
  'WZNÓW': 'RESUME',
  'Zapisuję…': 'Saving…',
  'Odwiedź wyspę': 'Visit island',
  'Dźwięk i ruch': 'Sound and motion',
  'Ustawienia': 'Settings',
  'Małe klocki, wielkie możliwości.\nTwój cukierkowy świat rozkwita bez pośpiechu.': 'Little blocks, big possibilities.\nYour candy world blooms at your own pace.',
  'Błąd zapisu. Spróbuj ponownie.': 'Save failed. Please try again.',
  'Błąd zapisu.': 'Save failed.',
  'Nie można potwierdzić usunięcia danych. Ponów reset przed kontynuowaniem.':
      'Could not confirm data deletion. Retry reset before continuing.',
  'Nie udało się usunąć danych. Spróbuj ponownie.':
      'Could not delete data. Try again.',
  'Nie udało się zapisać podejścia. Spróbuj ponownie.':
      'Could not save this run. Please try again.',
  'Zakup nie został zapisany. Monety pozostają na koncie.':
      'The upgrade was not saved. Your coins are still in your wallet.',
  'Nie udało się zapisać ustawień.': 'Could not save settings.',
  'Wyspa rozkwita!': 'Your island is blooming!',
  'Za mało Candy Coins. Zdobywasz je po zakończeniu podejścia.':
      'Not enough Candy Coins. Earn them by finishing a run.',
  'Wróć do menu': 'Back to menu',
  'Wrócić do menu?': 'Return to menu?',
  'Graj dalej': 'Keep playing',
  'Podejście pozostanie zapisane. Wznowisz je z menu.':
      'Your run stays saved. Resume it from the menu.',
  'To podejście zostanie zakończone.': 'This run will end.',
  'Cukierkowa układanka': 'Candy puzzle',
  'WYNIK': 'SCORE',
  'MONETY W GRZE': 'PENDING COINS',
  'TWÓJ WYNIK': 'YOUR SCORE',
  'MONETY Z PODEJŚCIA': 'COINS FROM THIS RUN',
  'Przeciągnij klocek lub wybierz go i dotknij pola.':
      'Drag a piece, or select it and tap a cell.',
  'Klocek na miejscu.': 'Piece placed.',
  'Tu klocek się nie mieści. Wybierz inne pole.':
      'That piece does not fit here. Choose another cell.',
  'Wymazać to pole?': 'Erase this cell?',
  'Anuluj': 'Cancel',
  'Wymaż pole': 'Erase cell',
  'Anuluj wybór pola': 'Cancel cell selection',
  'Dotknij zajętego pola, aby je wymazać.': 'Tap an occupied cell to erase it.',
  'Klocki nie pasują. Możesz spróbować wymazać jedno pole.':
      'No piece fits. You can try erasing one cell.',
  'Zakończ podejście': 'Finish run',
  'Ponów zapis': 'Retry save',
  'Nie udało się zapisać postępu. Ponów zapis przed kolejnym ruchem.':
      'Progress could not be saved. Retry before your next move.',
  'Piękna układanka!': 'Lovely puzzle!',
  'Żaden z pozostałych klocków nie pasuje.':
      'None of the remaining pieces fit.',
  'Zagraj ponownie': 'Play again',
  'puste': 'empty',
  'zajęte': 'occupied',
  'kwadrat dwa na dwa': 'two by two square',
  'kwadrat trzy na trzy': 'three by three square',
  'litera L, dwa pola w dół i jedno w prawo na dole':
      'L shape, two cells down and one to the right at the bottom',
  'odwrócona litera L, dwa pola w prawo i jedno w dół po prawej':
      'reversed L, two cells right and one down on the right',
  'litera T, trzy pola w prawo i jedno poniżej środka':
      'T shape, three cells right and one below the middle',
  'litera S, dwa pola na górze przesunięte w prawo':
      'S shape, top two cells shifted right',
  'litera Z, dwa pola na dole przesunięte w prawo':
      'Z shape, bottom two cells shifted right',
  'Wybierz ulepszenie': 'Choose an upgrade',
  '+25% punktów za usuwanie linii. Maksymalnie 2 poziomy.':
      '+25% points for clearing lines. Maximum 2 levels.',
  '+25% bazowych monet z całego podejścia. Maksymalnie 2 poziomy.':
      '+25% base coins for the whole run. Maximum 2 levels.',
  'Wymaż jedno zajęte pole po potwierdzeniu. Bez punktów i monet. Maksymalnie 2 użycia w podejściu.': 'Erase one occupied cell after confirmation. No points or coins. Maximum 2 charges per run.',
  'Twoja cukierkowa wyspa': 'Your candy island',
  'Cukierkowe drzewo': 'Candy Tree',
  'Galaretkowy domek': 'Jelly House',
  'Tęczowa fontanna': 'Rainbow Fountain',
  'Dotknij mieszkańca, aby się przywitać.': 'Tap a resident to say hello.',
  'Miękkie korony pełne kolorowych cukierków.':
      'Soft treetops full of colourful candy.',
  'Przytulny galaretkowy domek dla mieszkańców.':
      'A cosy jelly home for the residents.',
  'Tęczowe łuki nad błękitną wodą.': 'Rainbow arches above blue water.',
  'Wróć na wyspę': 'Back to island',
  'Rozbuduj': 'Upgrade',
  'Nie można otworzyć zapisu': 'Could not open your save',
  'Twój zapis nie został zastąpiony. Możesz ponowić próbę.':
      'Your save has not been replaced. You can try again.',
  'Spróbuj ponownie': 'Try again',
  'Rozpocznij od nowa': 'Start fresh',
  'Zastąpić uszkodzony zapis?': 'Replace the damaged save?',
  'Postęp z tego zapisu zostanie utracony. Kopia pozostanie lokalnie do diagnostyki.': 'Progress in this save will be lost. A local copy will remain for diagnostics.',
};
