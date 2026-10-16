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

## Integracja i podpisany kandydat — 2026-10-16

PR [#16](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/16),
branch `feat/reference-candy-ui`. Review obejmuje nowe kontrolki, semantykę
planszy, nawigację, operacje AppSession, zapis, dochód/prestiż oraz wszystkie
pięć renderów powyżej. Nie znaleziono problemu blokującego w analizie kodu.
To przegląd agenta integrującego, nie niezależna aprobata innego konta GitHub.

Lokalnie: Flutter 3.47.2 / Dart 3.13.2; format 68 plików bez zmian, analyze bez
problemów, testy silnika 71/71, widget/unit 199/199, narzędzia wydania 19/19,
kontrola dokumentacji i `git diff --check` PASS. Testy golden wykonano bez
aktualizowania wzorców. Build release APK i AAB PASS. Brak nowego testu telefonu
(właściciel wcześniej polecił go pominąć); host nie jest dowodem GPU60FPS.

Podpisane pliki 1.2.0/code4: źródło `18fcf7b`, kod aplikacji `6293730`.
Kolejne zmiany integracji dotyczą dokumentacji i CI, nie kodu/assetów aplikacji.
Identyfikator `com.renvo.candyverse`, SDK24/36, brak INTERNET i nowych SDK,
backup wyłączony. APK i universal: 6 bibliotek ELF64 oraz ZIP16KB PASS.
AAB: bundletool validate i PAGE_ALIGNMENT_16K PASS; jarsigner potwierdza podpis.
Ostrzeżenia self-signed, braku timestampu i kolejności wpisów ZIP są analogiczne
do poprzedniego wydania i nie dowodzą przyjęcia przez Play.

Certyfikat SHA256 pozostaje
`2064a303250785a1ef85029a03a543dc759ab6d715f1fb2f05dccdca04e70506`.

| Plik | SHA256 |
| --- | --- |
| candyverse-1.2.0-4.apk | `51ab72e985c0ec5d4f3a8a0f309efd4325a340778c217751d84a140e422913bd` |
| candyverse-1.2.0-4.aab | `bbc766e9ad2aeb04b5b25ccd7d5b0ccd0635cad56337cef79a8da5927aac485f` |
| candyverse-1.2.0-4-from-aab.apk | `e509a92a1e14e6f65e0be3f1b817cb18dee435f0f2ff7692d2dd04e2103d6fc6` |

Pełne pliki i lokalne dowody:
`/home/roch/.cache/candyverse/artifacts/reference-1.2.0-4/`.
Pierwsza próba macierzy [CI38951197945](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/38951197945)
zakończyła się przed uruchomieniem Androida: token contents:read nie widział
szkicu wydania. Retry korzysta z krótkotrwałych adresów odczytu pojedynczych
assetów, przekazanych jako sekrety; SHA256 pozostaje przypięte w workflow.
Sekrety są usuwane po publikacji; przyszłe przebiegi pobierają publiczny release.
Klucze podpisu i token konta nie trafiają do CI. Wyniki Androida oraz status
publikacji zapisuje [STATUS](STATUS.md); nie przypisujemy PASS trwającym jobom.
