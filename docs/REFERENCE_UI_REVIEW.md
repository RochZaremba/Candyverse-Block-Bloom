# T-019 — wygląd według referencji właściciela

Wersja rozwojowa: **1.2.0+4**, branch `feat/reference-candy-ui`.
To nowa oprawa menu, gry, wyniku, okna powrotu i wyspy według pięciu zdjęć
przekazanych 2026-10-16. Publiczne wydanie 1.1.0+3 zachowuje poprzedni wygląd.

## Rzeczywiste rendery Fluttera

Poniższe PNG powstają z widgetów aplikacji przy 360×640 dp, czyli proporcjach
9:16 źródłowych kompozycji. Profil i plansza są deterministycznymi fixture testów;
aplikacja pobiera te same pola z rzeczywistego zapisu. Statystyki, plansza,
figury, przyciski i karty nie są fragmentami zrzutów z naniesionymi hitboxami.

| Referencja właściciela | Nowy render |
| --- | --- |
| 1000016960.jpg — menu | [Menu](../test/goldens/reference_menu_360.png) |
| 1000016962.jpg — plansza | [Gra](../test/goldens/reference_game_360.png) |
| 1000016958.jpg — okno powrotu | [Powrót](../test/goldens/reference_return_360.png) |
| 1000016961.jpg — wynik | [Koniec gry](../test/goldens/reference_result_360.png) |
| 1000016959.jpg — wyspa | [Wyspa](../test/goldens/reference_island_360.png) |

## Zachowanie

PLAY wznawia istniejącą grę, a wynik pozwala rozpocząć następną lub odwiedzić
wyspę. Powrót wymaga potwierdzenia i zachowuje run. Dolna nawigacja wyspy
pozostaje dostępna podczas przewijania. Karty kupują kolejne prawdziwe poziomy,
COLLECT rozlicza dotychczasowy dochód, a mapa przedstawia trzy światy i warunek
prestiżu. Licznik obok logo to istniejące gwiazdki prestiżu.

Zachowano ceny, zasady gry, RNG, format zapisu, potwierdzenia operacji i ustawienia.
Przy tekście 200% karty układają się pionowo, długie okna przewijają zawartość,
a przyciski zachowują minimalny obszar dotyku. Polski napis rezerwacji banera
jest zgodny z dostarczonym wzorem także w angielskiej kompozycji.

## Odtworzenie

W przygotowanym środowisku wczytaj `/workspace/.candyverse-tools/env.sh`.
Następnie z katalogu repozytorium:

```sh
flutter pub get --enforce-lockfile
flutter test --no-pub --concurrency=2
flutter build apk --debug --no-pub
python3 scripts/audit_android_artifact.py --debug build/app/outputs/flutter-apk/app-debug.apk
```

APK debug jest artefaktem deweloperskim. Podpisane wydanie, pomiary na urządzeniu
i publikacja pozostają oddzielnymi etapami. Raport końcowych kontroli jest w
[STATUS](STATUS.md); [ADR-0018](adr/0018-reference-screen-presentation.md) opisuje
decyzję, a [provenance](../assets/kingdom/REFERENCE_ART.md) źródła grafik i fontu.
