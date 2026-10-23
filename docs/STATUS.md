# STATUS — rzeczywisty stan i przekazanie prac

## 2026-10-23 — sieć odblokowana, T-022 sprawdzone, APK Preview gotowe

Źródła `5a5392b`, UI/regresje `e0659d3`, branch `fix/readable-game`.
Po komunikacie właściciela ponowiono operacje: Flutter i API GitHub działają,
setup JDK/SDK/Flutter/pub ukończony. Historyczne blokery sieci poniżej są rozwiązane.
Brak dotychczasowego klucza produkcyjnego pozostaje rzeczywistą blokadą release.
`gh secret list` odmawia dostępu integracji; nie żądano nowego tokena/nie próbowano
odczytywać wartości sekretów.

- **236/236 Flutter PASS** bez update-goldens po finalnej zmianie;93/93 domena,
  19/19 Python; analyze0, format/docs/diff PASS.
- Zaktualizowano i obejrzano goldeny gry/popupów PL/EN/200%. Poprawiono brakujący
  glif znacznika tęczy oraz sprzeczną instrukcję w oknie braku miejsca.
- Host smoke z MemoryStorage PASS,19 ruchów/20 reakcji; to nie native DataStore
  ani20min QA. Brak lokalnego urządzenia/KVM; nie ponawiamy telefonu właściciela.
- Zbudowano i statycznie audytowano **Candyverse Preview1.3.1+7 ARM64**:
  `build/artifacts/candyverse-1.3.1-7-preview-arm64.apk`.
  Pakiet `.preview`, osobny zapis, SDK24/36, debug, ELF/ZIP16KB i podpis PASS.
  SHA256 `e3b4af6a949ae571adea4f229ebc3c6db91cd0768ee6ae5e484e282e16c80f59`.
  To podgląd instalowany obok produkcyjnej gry, nie podpisana aktualizacja.

[Obrazy i pełne ograniczenia kontroli](READABILITY_REVIEW.md).
Podpisany release/Play nieopublikowane; istniejący1.3.0+6 bez zmian.
**Następny krok:** udostępnić istniejący klucz przez bezpieczny mechanizm poza
Git/chatem i wskazać CANDYVERSE_KEY_PROPERTIES; po zielonych kontrolach PR
zbudować/audytować/przetestować podpisany APK/AAB oraz opublikować autoryzowany release.


## 2026-10-23 — właściciel zlecił kolejny release: 1.3.1+7, ZABLOKOWANY

Przygotowano wersję źródłową **1.3.1+7** i [opis wydania](RELEASE_1_3_1_NOTES.md)
na `fix/readable-game`. Planowany tag `v1.3.1-rc.1` zgodnie z dotychczasową
publiczną dystrybucją prerelease GitHub. Nie utworzono tagu ani GitHub Release,
nie scalono do main, nie opublikowano w Play i nie wygenerowano APK/AAB.
Poprzednie publiczne wydanie1.3.0+6 pozostaje bez zmian.

Sprawdzono ponownie rzeczywiste operacje:

- `git ls-remote origin HEAD`: PASS, main=`647425a`.
- `flutter --version`: bootstrap Dart SDK nadal CONNECT403 do storage.googleapis.com.
  Wszystkie wymagane testy Flutter, aktualizacja/ocena goldenów i build nadal nieuruchomione.
- `gh api repos/RochZaremba/Candyverse-Block-Bloom` i `gh release list`:
  Forbidden do api.github.com. GH_TOKEN jest obecny, nie żądano nowego tokena.
  Działający Git nie ustanawia dostępu do API publikacji.
- Brak CANDYVERSE_KEY_PROPERTIES i wcześniejszego zewnętrznego klucza
  w tym środowisku. Nie generowano innego certyfikatu/debugowego zamiennika.

W szkicu konfiguracji zachowano storage.googleapis.com i dodano
api.github.com oraz uploads.github.com. Zapis szkicu potwierdzony;
nie zmienia on aktywnej polityki bez zapisania/publikacji środowiska.
Po aktywacji trzeba ponowić rzeczywiste operacje, nie zakładać uprawnień do API.

**Do odblokowania:** zapisać/publikować konfigurację środowiska z tymi hostami
oraz udostępnić dotychczasowy klucz bezpiecznym mechanizmem poza Git/chatem,
ze wskazaniem CANDYVERSE_KEY_PROPERTIES. Oczekiwany certyfikat SHA256:
`2064a303250785a1ef85029a03a543dc759ab6d715f1fb2f05dccdca04e70506`.
Następnie dokończyć testy i goldeny opisane niżej, build/audyty/podpisany smoke,
PR i zielone kontrole przed scaleniem oraz publikacją release z artefaktami.
Właściciel już autoryzował publikację; nie prosić ponownie o jej zgodę.


## 2026-10-23 — T-022: kod przygotowany, walidacja Flutter ZABLOKOWANA

Branch `fix/readable-game`, baza aktualnego `origin/main`=`647425a`.
Logika `e073ef7`, UI `03dc203`. PR nieutworzony: wymagane testy i nowe goldeny
pozostają zablokowane. To gałąź robocza, nie kandydat do scalenia.
Jawne zamówienie właściciela: czytelność, brak scrolla w grze, informacje i
niedostępność w popupie, karty co 30–40 ruchów. [ADR-0021](adr/0021-readable-game-and-upgrade-cadence.md)
wybiera 30 zaakceptowanych placementów zamiast dwóch progów co5 ruchów/linii.

- Stały ekran: kompaktowy pasek wyniku/monet, spokojne tło, elastyczna plansza,
  3 sloty i krótki pasek komunikatu/mocy. Pełne opisy i ustawienia pod ikoną.
- Niedostępna moc wyjaśnia przyczynę. „Brak miejsca” otwiera ratunek albo
  zakończenie; zamknięcie zachowuje stan. Nie usunięto mocy/synergii.
- Evolution zachowuje istniejące moves/RNG/karty. Legacy zapisuje opcjonalne
  legacyMoves; stary brak pola →0. Istniejące kolejki zachowane, monety bez zmian.
- Dodane testy 60 placementów→2 karty, multiclear bez dodatkowych wyborów,
  resume29→30/RNG, legacy i stare kolejki. Dostosowane testy popupów,
  niedostępnej tęczy, ratunku i layoutu bez scrolla PL/EN/200% oraz native smoke.

Wykonane: parser składni wszystkich Dartów PASS (tree-sitter), format zmienionych
plików portem WASM dart_style 0.4.0 (nie zastępuje wymaganego pinu SDK),
`git diff --check` PASS, `python3 scripts/check_docs.py` PASS,
Python release tools **19/19 PASS**. Nie przypisywać tych wyników domenie/UI.

Środowisko początkowo nie miało Flutter/Dart ani Android SDK/JDK compiler.
Doinstalowano i sprawdzono lokalny pełny OpenJDK21.0.12.1 (javac), Android
platform36/build-tools36/NDK28.2 oraz ADB37.0.1; licencje zaakceptowane.
Pobrano źródło Flutter3.47.2 z GitHub (d3b14c8), ale bootstrap Dart SDK
`storage.googleapis.com` zwraca CONNECT403. Bieżąca polityka ma package_managers
bez tego hosta. Zapisano dodanie hosta w szkicu konfiguracji środowiska;
nie jest jeszcze aktywne. Zapisano także `install_script` i `start_skill`
w szkicu konfiguracji; wymagają zapisania/publikacji środowiska. Skrypt `/workspace/.candyverse-tools/install.sh`
przetestowano do tej blokady; aktywacja narzędzi: `source /workspace/.candyverse-tools/env.sh`.
Nie obchodzono proxy ani weryfikacji TLS.

**Nie uruchomiono:** bazowych/nowych testów Flutter i Dart, flutter analyze,
pinowanego dart format, buildu Android i natywnego smoke. Nie wygenerowano
nowego APK ani nowych screenshotów. Istniejące goldeny gry pozostają stare:
po odblokowaniu trzeba wygenerować i obejrzeć zmienione obrazy, następnie
uruchomić całą zamrożoną suite bez update-goldens. Zadanie NIE jest QA DONE.
Wersja źródłowa1.3.0+6 bez podbicia do niezweryfikowanego wydania. Brak publikacji.

**Następny krok:** zapisać storage.googleapis.com w ustawieniach środowiska i
opublikować środowisko; dokończyć Flutter/Android setup, format/analyze/testy,
obejrzeć goldeny i zbudować debug APK przed PR. Nie ponawiać testu telefonu
właściciela wbrew jego wcześniejszej decyzji.


## 2026-10-19 — Evolution1.3.0+6: scalone i opublikowane

PR#17 scalony jako `b24a039`, PR#18 jako `ebb9c2a` po zielonych kontrolach.
Publiczny [v1.3.0-rc.1](https://github.com/RochZaremba/Candyverse-Block-Bloom/releases/tag/v1.3.0-rc.1),
opublikowany2026-10-19T09:25:41Z; tag=`ebb9c2a`. Google Play nieopublikowane.
Review agenta integrującego, bez wykrytych blockerów; nie niezależna aprobata.

- Flutter230/230, domena88/88, release tools19/19 i kontrole statyczne PASS.
  Flutter39114081585 SUCCESS, native39114081625 source `d4b5832` SUCCESS:
  1202s,610 ruchów,760 reakcji,38 cykli, DataStore, moce/restore, JUnit1/0/0.
- Poprawka `d4b5832` dotyczy tylko scenariusza: modalny wybór karty na końcu
  serii blokował menu. Pełne20min ponowiono; aplikacja bez zmiany.
- Podpisana macierz39229177997 source `c463647`: **4/4 PASS**. APK API24/36/35
  z16KB i universal z finalnego AAB/API36. Input Androida, tło, force-stop,
  identyczne64 pola po restore; obejrzano produkcyjne PNG. CPU nie dowodzi GPU60FPS.
- APK/AAB/universal1.3.0+6 z `d4b5832`, kod identyczny z merge `ebb9c2a`.
  Certyfikat jak poprzednio, audyty/podpisy/bundletool/16KB PASS. Klucze poza Git/CI.
- Publiczny APK pobrano bez logowania: SHA256 zgodny,81732793B.
  Tymczasowe adresy draftu usunięto z secrets; workflow pobiera publiczne pliki.

[Raport, hashe, surowe JSON/JUnit i zrzuty](EVOLUTION_RELEASE_REPORT.md).
Handoff: branch `chore/evolution-release`; PR dokumentacji/nowego pinu CI#19.
Bieżące kontrole handoffu sprawdzaj w PR; nie zmienia on kodu produkcyjnego.
Nie powtarzamy telefonu zgodnie z decyzją właściciela. Poprzednie wydania bez zmian.

**Jedno następne zadanie:** po weryfikacji konta właściciela przygotować test
wewnętrzny Play dla aktualnego AAB1.3.0+6 i odświeżyć materiały sklepu.

## 2026-10-18 — T-021 Roguelite Evolution zaimplementowane

Branch `feat/roguelite-evolution` oparty na `bcb24b6` z otwartego PR#17.
Implementacja `a351df1`, Android smoke `4022750`, dokumentacja `d2e021c`.
PR [#18](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/18), baza
`feat/candy-flow-polish` (PR#17 nadal otwarty). Kontrakt `5dc3aa7` i [ADR-0020](adr/0020-roguelite-evolution.md); jawne
zamówienie właściciela. Wersja rozwojowa **1.3.0+6**, publiczne wydanie bez zmian.

- 12 kart:4 poziomy Explosive Candy, Rainbow Magic i Lucky Paws. Progi co5
  ruchów i co5 linii są niezależne, kolejkują każdy zdobyty wybór.
- Bomba: wiersze ładują, krzyż→3×3→łańcuchy→szybsze ładowanie; znaczniki,
  podgląd rzeczywistych pól/kosztu, anulowanie i potwierdzenie.
- Tęcza: wybrany slot, inny ID z seedowanego RNG, cooldown liczony placementami,
  od L3 wybór koloru. Paws: punkty i pending coins za combo.
- 4 synergie: Rainbow Explosion, Golden Explosion, Lucky Spectrum,
  Candy Constellation; nazwy i objaśnienia w panelu, zapowiedź na karcie.
- Schema3 zachowuje ładunki, cooldown, priming, RNG i bonusCoins. Decoder1/2
  zachowuje dotychczasowe runy/karty/bonusy i profil. Nowe runy używają Evolution.
  Portfel rośnie dopiero przy idempotentnej finalizacji. Brak nowych SDK/sieci.
- Panel pod tacką jest przewijany; poprawione gesty pion/poziom zachowują drag
  mimo dłuższej zawartości. Tap-select odsłania planszę, gdy jest poza widokiem.

Sprawdzone lokalnie (baseline206/206):
- `flutter test --no-pub --concurrency=2`: **230/230 PASS**, bez update-goldens.
- `dart test test/game`: **88/88 PASS**, w tym17 nowych przypadków Evolution.
- Analyze bez uwag, format74 plików bez zmian, docs/diff i shell syntax PASS;
  Python release tools19/19 PASS; rozszerzony host smoke PASS.
- Obejrzano realne rendery kart PL/EN/200%, panelu mocy i podglądu bomby,
  planszę320/412 i kompaktową tackę. Goldeny w `test/goldens/evolution_*.png`.

`flutter build apk --debug --no-pub` PASS. Audyt debug: SDK24/36,
backup exclusions,5 ELF64/ZIP16KB i podpis debug PASS. INTERNET dotyczy tylko
developerskiego APK. Brak nowego wyniku natywnego DataStore i podpisanego release
1.3.0+6; rozszerzono scenariusz Androida o moce i odtworzenie sesji. Poprzednie
QA1.2.1+5 nie zalicza nowego silnika. Nie prosimy o powtórkę telefonu.

**Następny krok:** sprawdzić CI z natywnym scenariuszem Evolution przed integracją;
PR#18 bazuje na gałęzi PR#17, aby nie mieszać wcześniejszej oprawy z T-021.
Po scaleniu#17 przestaw bazę#18 na main. CI#18 uruchomiono; brak jeszcze wyniku.

## 2026-10-16 — natywne QA T-020: aktywny scenariusz PASS

Branch `feat/candy-flow-polish`, PR [#17](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/17),
wersja1.2.1+5. [Native CI38963761707 SUCCESS](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/38963761707),
źródło `8e68c2e`, kod aplikacji `f65e01d`. Rozszerzenie scenariusza `dbdbf57`;
`8e68c2e` wymaga zajętego pola przed porównaniem planszy po powrocie.

- API35, profile AOT, prawdziwy DataStore; **1202s aktywnej gry,691 ruchów,
  740 reakcji,37 cykli**. JUnit:1 test,0 failures,0 errors.
- Menu/play na wszystkich4 zakładkach, settings/back, identyczne64 pola/RNG,
  komunikaty i zamknięcie PASS. Dochód, poziom30, prestiż i reset PASS.
- [Surowy raport](qa/candy-flow-api35-profile-cpu.json):7427 FrameTiming,
  build p95=6286µs, raster p95=72783µs. Software rendering na emulatorze;
  te liczby nie potwierdzają GPU60FPS telefonu.
- [Flutter CI38963761701 SUCCESS](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/38963761701).
  Lokalny rozszerzony host smoke, analyze, docs, shell syntax i diff PASS.
- Pierwsze PNG z pełnego przebiegu pokazują częściowo poprzednią klatkę;
  nie zaliczamy ich jako dowodu wyglądu komunikatów. `56ab19f` pompuje przejście
  przed zrzutem. Osobny [diagnostyczny przebieg UI38968393258 SUCCESS](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/38968393258),
  source `56ab19f`:100s scenariusza,0 minut dwell, nie zastępuje pełnego testu.
  Obejrzano prawidłowe, nieedytowane PNG: [ustawienia](qa/candy-flow-candy-settings-return.png),
  [mapa](qa/candy-flow-candy-island-map.png), [informacja](qa/candy-flow-candy-notice-info.png),
  [sukces](qa/candy-flow-candy-notice-success.png). [Raport diagnostyczny](qa/candy-flow-api35-ui-diagnostic.json),
  [źródła i SHA256](qa/candy-flow-provenance.json), [JUnit pełnego QA](qa/candy-flow-api35-junit.xml).

Artefakty: `/home/roch/.cache/candyverse/artifacts/candy-flow-1.2.1-5/`.
Zmiany QA nie modyfikują `lib/`, assetów, Androida ani wersji/zależności aplikacji.
Publiczne1.2.0+4 pozostaje bez zmian. Signed compatibility nadal testuje1.2.0+4,
więc jego PASS nie jest testem podpisanego1.2.1+5. Nie powtarzamy testu telefonu
zgodnie z decyzją właściciela.

**Następny krok:** przygotować podpisany kandydat1.2.1+5 i jego macierz
kompatybilności APK/AAB. PR#17 pozostaje otwarty. Ponowiony pełny smoke PR dla
`56ab19f` jest w toku; zaliczony20-minutowy wynik powyżej dotyczy `8e68c2e`.
[Flutter CI38968384949 SUCCESS](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/38968384949)
dla `56ab19f`: pierwsza próba zatrzymana przez uszkodzony ZIP NDK przy pobieraniu
przez sdkmanager; ponowienie na świeżym runnerze PASS.

## 2026-10-16 — T-020: spójny candy UI i nawigacja

**DONE w branchu `feat/candy-flow-polish`, wersja rozwojowa1.2.1+5.**
Baza `199e79f` (merge PR#16), grafiki/kontrakt `0c430d3`, implementacja `f65e01d`.
PR [#17](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/17) otwarty;
handoff `343fcd9`. Lokalne wyniki poniżej są potwierdzone; bieżące CI sprawdzaj w PR.
Publiczne wydanie pozostaje1.2.0+4; T-020 nie jest jeszcze scalone ani opublikowane.

- Wspólne CandyNotice dla informacji/sukcesów/błędów: generowane ikony,
  candy panel, zamknięcie, semantyki, przewijanie i układ pionowy przy dużym
  tekście. Przy nawigacji do gry nie zostają stare komunikaty wyspy.
- Ustawienia, sheet dźwięku/ruchu, recovery i wybór ulepszeń używają wspólnych
  paneli/przycisków; retry błędu zapisu pozostaje rzeczywisty. Przezroczysta
  blokada w trakcie checkpointu zachowana, bez powrotu białego flash.
- Menu i gra dostępne stale na każdej zakładce wyspy; menu czyści pośrednie
  trasy, gra otwiera istniejący AppSession. Back w ustawieniach wraca do gry.
  Zakładki przy200% tekstu przechodzą w2 rzędy. Dotyk>=48dp.
- Nowy lokalny [atlas8 kontrolek](../assets/kingdom/navigation-atlas.png),
  wbudowany imagegen, nieedytowany PNG z alpha. [Prompt i provenance](../assets/kingdom/REFERENCE_ART.md#t-020--navigation-atlaspng).
  Poprawione wyłącznie paint-time kadry starych postaci usuwają sąsiednie łapki.
  Silnik, ekonomia, save schema, zależności i zasady offline/prywatności bez zmian.

Weryfikacja lokalna:
- Baseline199/199; końcowo `flutter test --no-pub --concurrency=2` **206/206 PASS**
  bez aktualizacji goldenów, `dart test test/game` **71/71 PASS**.
- Format69 plików bez zmian, analyze bez problemów, docs/diff PASS,
  Python release tools **19/19 PASS**.
- `flutter build apk --debug --no-pub` PASS; audyt debug: SDK24/36,
  backup exclusions,5 ELF64/ZIP16KB i podpis debug PASS. INTERNET dotyczy
  developerskiego APK; nie jest to podpisane wydanie produkcyjne.
- Nowe testy obejmują wszystkie zakładki, wznowienie tej samej64-polowej planszy,
  brak zaległych tras, settings/back, zamknięcie i zastąpienie komunikatu,
  PL/EN/320dp/200%. Obejrzano realne rendery Fluttera:
  [sukces](../test/goldens/notice_success_320.png),
  [komunikat PL200%](../test/goldens/notice_pl_320.png),
  [komunikat EN200%](../test/goldens/notice_en_320.png),
  [ustawienia](../test/goldens/candy_settings_320.png),
  [nawigacja PL200%](../test/goldens/candy_navigation_pl_320.png),
  [recovery](../test/goldens/candy_recovery.png).

Stan po implementacji (przed QA opisanym wyżej): brak nowego testu natywnego
i podpisanego release dla1.2.1+5.
Workflow signed compatibility nadal pobiera publiczne1.2.0+4; jego wynik nie
zalicza natywnego QA T-020. Nie prosimy o powtórkę telefonu (decyzja właściciela).

**Jedno następne zadanie:** integracja T-020 przez PR, następnie przygotowanie
podpisanego kandydata1.2.1+5 z natywnym QA nowego UI.

## 2026-10-16 — T-019: integracja i kandydat 1.2.0+4

**T-019 DONE.** Integracja przez [PR#16](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/16),
branch `feat/reference-candy-ui`; kod/testy `6293730`, grafiki `f0cf84e`,
head integracji przed końcową dokumentacją `a42bdaa`.
Autor i committer wszystkich nowych commitów: Roch Zaremba <rochzaremba@gmail.com>.

Kandydat GitHub: [v1.2.0-rc.1](https://github.com/RochZaremba/Candyverse-Block-Bloom/releases/tag/v1.2.0-rc.1),
wersja aplikacji **1.2.0/code4**. Google Play nadal **nieopublikowane**.
Historyczne wydanie 1.1.0+3 pozostaje bez zmian.

- Review kodu i pięciu renderów: bez wykrytych usterek blokujących; dodatkowo
  obejrzano rzeczywiste PNG produkcyjnego APK z AAB na API36. To review agenta
  integrującego, nie niezależna aprobata innego konta GitHub.
- Lokalnie format/analyze/docs/diff PASS, silnik **71/71**, Flutter **199/199**,
  narzędzia wydania **19/19**. [Flutter CI38952217114 SUCCESS](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/38952217114).
- [Signed CI38952217155 SUCCESS](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/38952217155):
  APK API24/API36/API35 z rzeczywistym16KB oraz universal z finalnego AAB na API36.
  Rzeczywisty input, PNG, tło/powrót, force-stop i identyczne64 pola po restore.
  Pierwsza próba nie widziała draftu; druga napotkała404 dla jednego assetu.
  Ponownie przesłano identyczny APK, sprawdzono adresy i powtórzono tylko
  nieudane joby. Hashe/binaria nie zmieniły się; wszystkie cztery warianty PASS.
- [Native CI38950626989 SUCCESS](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/38950626989):
  20-minutowy aktywny scenariusz Androida, prawdziwy DataStore, dochód,
  poziom30/prestiż, ustawienia/reset i kontynuacja gry. To emulator/CPU,
  nie ocena wydajności GPU telefonu. Kod/assety/testy są identyczne z `8554b51`.
- Podpisane APK/AAB/universal zbudowano ze źródeł `18fcf7b` (kod `6293730`).
  Manifest1.2.0/code4, SDK24/36, backup/permissions, ELF/ZIP16KB, bundletool
  validate/config16KB i podpisy PASS. Certyfikat pozostaje taki jak poprzednio.
  [Raport, hashe i ograniczenia](REFERENCE_UI_REVIEW.md#integracja-i-podpisany-kandydat--2026-10-16).

Lokalne pliki i dowody: `/home/roch/.cache/candyverse/artifacts/reference-1.2.0-4/`.
Żadnych kluczy podpisu ani tokena konta w CI; workflow ma contents:read.
Do testu draftu użyto krótkotrwałych adresów odczytu assetów, usuwanych po publikacji.
Brak nowego testu telefonu zgodnie z wcześniejszą decyzją właściciela — nie prosić
ponownie. Brak submission Play, przyjęcia przez sklep ani nowej oceny GPU60FPS.

**Jedno konkretne następne zadanie:** po zakończeniu weryfikacji konta właściciela
przygotować test wewnętrzny Play aktualnego AAB1.2.0+4 i odświeżyć materiały sklepu.

Poniżej zachowano historyczny raport gałęzi sprzed integracji i wydania 1.1.0+3.

## 2026-10-16 — T-019: pięć ekranów według zdjęć właściciela

**DONE w gałęzi `feat/reference-candy-ui`, wersja rozwojowa 1.2.0+4.**
Commit aplikacji i testów: `6293730`; pierwsza partia grafik: `f0cf84e`.
Nowa oprawa nie została scalona do main ani opublikowana jako wydanie.

- Menu, plansza, wynik, okno powrotu i wyspa otrzymały kompozycje, lokalne tła,
  postacie, logo, błyszczące przyciski i ramki według pięciu referencji.
  Osobny atlas zawiera sześć etapów trzech budynków, w tym niebieską fontannę
  z gwiazdką. [Pięć rzeczywistych renderów i procedura](REFERENCE_UI_REVIEW.md).
- Wyniki, pieniądze, poziomy, plansza i klocki są żywymi widgetami. Istniejąca
  domena, ceny i schema2 pozostały zachowane. COLLECT i karty korzystają z
  AppSession; zakładki wyspy pokazują mieszkańców, dekoracje i mapę. Nawigacja
  jest przypięta na dole, a duży tekst otrzymuje przewijanie/pionowe karty.
- Dialogi zachowują klucze i callbacki akcji, czytelną przewijaną treść i
  potwierdzenia. Jawny fallback Roboto uzupełnia brakujące polskie litery fontu
  Lilita One. [Decyzja](adr/0018-reference-screen-presentation.md),
  [grafiki i licencje](../assets/kingdom/REFERENCE_ART.md).

### Weryfikacja bieżących źródeł w środowisku chmurowym

- `flutter test --no-pub --concurrency=2`: **199/199 PASS**, końcowy przebieg bez
  `--update-goldens`; pięć nowych przypadków obejmuje także prawdziwy ruch,
  anulowanie powrotu, restart, zapis zakupu, odbiór dochodu i zakładki.
- `dart test test/game`: **71/71 PASS**; `flutter analyze --no-pub` i format PASS.
- Python release tools **19/19 PASS** oraz kontrola dokumentacji/tokenów PASS.
- `flutter build apk --debug --no-pub`: PASS; manifest ma wersję **1.2.0/code4**,
  identyfikator `com.renvo.candyverse`, SDK24/36. Audyt debug: dozwolone uprawnienia,
  backup exclusions, pięć 64-bit ELF, ZIP16KB i podpis APK PASS.
- Host smoke: prawdziwe akcje UI, dochód, poziom30, prestiż, settings/reset i
  kontynuacja gry PASS. Storage scenariusza to `memory-host-validation`.
  To nie jest nowy test natywnego DataStore ani pomiar GPU.

Artefakt lokalny: `build/artifacts/candyverse-1.2.0-4-debug.apk` (debug, nie release).
SHA256: `c48e9a0e4ac75802a1154832cc6d7e0d7c714ac713a55bd755f1dc4fb61500b7`.
Logi są w `/workspace/.candyverse-tools/logs/reference-*`.
Nie wykonywano nowego testu na telefonie/emulatorze ani publikacji Play/GitHub
release. Wyniki GitHub Actions tej gałęzi nie były weryfikowane; API GitHub
odmówiło dostępu podczas próby odczytu repozytorium.

**Jedno następne zadanie:** przejrzeć T-019 na podstawie pięciu renderów i
zintegrować gałąź przez PR; utworzenie PR przez API nie było dostępne w tej sesji.

Poniżej zachowano historyczny handoff i dowody wydania 1.1.0+3.

Aktualizacja2026-10-15. **Candy Kingdom1.1.0+3: publiczny prerelease GitHub. Google Play: nieopublikowane.**

Implementacja na main: `7b5db1a`, merge [PR#14](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/14), head `231258a`.
Plan: PR#13/head4add259/merge85c7a91. Źródło podpisanych binariów: `61c34a4`;
między nim a merge nie ma zmian kodu produkcyjnego. Poprawka flash: `30fa7b0`.
Handoff: branch `docs/kingdom-release-handoff`, worktree `.../candyverse-workers/kingdom-handoff`.
Repo `RochZaremba/Candyverse-Block-Bloom`, fetch HTTPS / push SSH.

## Zadania

| Zadanie | Stan | Potwierdzenie |
| --- | --- | --- |
| T-001–T-011 V1 | DONE | PR#1–#11, historyczne wydanie1.0.0+1; [raport](RELEASE_REPORT.md) |
| T-012 Contract | DONE | PR#13, ADR-0016, CI38727224494 SUCCESS |
| T-01330 levels / income | DONE | PR#14; migracja schema1→2, ceny, czas/rollback, atomowe ACK/retry, native DataStore |
| T-014 Prestige | DONE | PR#14;3×30→gwiazdka, reset poziomów i nowy motyw, zachowany portfel/run/ustawienia |
| T-015 Rendered artwork | DONE | PR#14; marka właściciela,4 zwierzaki,18 renderów budynków,3 krajobrazy, provenance/prompty/goldeny |
| T-016 Menu / EN | DONE | PR#14;2 przyciski, gear lewy górny róg; nowe profile EN, PL selectable, stary język zachowany |
| T-017 Transitions / notices | DONE | PR#14; opaque przejścia, candy komunikaty, brak białej warstwy checkpointu, dostępność/reduced-motion |
| T-018 Celebrations / QA | DONE | PR#14; fanfara/confetti,194 testy,4 przypadki podpisanego APK/AAB i native20min CI PASS, nowy publiczny kandydat |

## Potwierdzone testy bieżącego code3

- `flutter test --concurrency=2`:194/194 PASS, `dart test test/game`:71/71,
  Python release tools19/19, format/analyze/docs PASS. [Flutter CI38734971516 SUCCESS](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/38734971516).
- Regresja migania: RED przed30fa7b0, GREEN po. Wszystkie piksele podczas
  opóźnionego checkpointu16ms/100ms odpowiadają obrazowi po ACK; kolejny ruch
  jest blokowany, błąd i rzeczywisty retry pozostają dostępne.
- [Signed CI38734971548 SUCCESS](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/38734971548): APK API24/API36/API35 z rzeczywistym16KB, universal z finalnego AAB na API36.
  Prawdziwy input Androida, PNG, tło i force-stop, identyczne64pola po restore.
  API24 pierwszej próby zasłoniło okno awarii systemowego Messengera; dowody
  zachowane. Ponowiony job na świeżym emulatorze PASS, bez zmian APK.
- [Native CI38734971558 SUCCESS](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/38734971558):1202s aktywnej gry,691 ruchów,740 reakcji,37 cykli;
  DataStore i flagi income/level30/prestige PASS; JUnit1/0/0.7292 FrameTiming,
  build p95=5693µs/raster p95=52847µs. To CPU, nie dowód GPU60FPS.
- APK/universal: SDK24/36, manifest/permissions/backup, sześć ELF64 i ZIP16KB,
  certyfikat apksigner PASS. AAB: bundletool validate/config16KB/universal,
  jarsigner i certyfikat keytool PASS. Self-signed/timestamp/ZIP-order warnings
  opisano w raporcie; nie oznaczają akceptacji AAB przez Play.
- Goldeny: Home320/412, obiekty0/1/5/6/15/30, różne światy, PL/EN/200%/reduced-motion.
  Nowe nieedytowane PNG1080×1920 pochodzą z podpisanego code3/API24.

[Pełny raport i surowe JSON](KINGDOM_RELEASE_REPORT.md).

## Publiczne pliki

[Wydaniev1.1.0-rc.2](https://github.com/RochZaremba/Candyverse-Block-Bloom/releases/tag/v1.1.0-rc.2),
opublikowane2026-10-15T13:36:14Z; tag wskazuje7b5db1a.
Identyfikator `com.renvo.candyverse`, Renvo, rochzaremba@gmail.com, wersja1.1.0/code3.

- APK SHA256 `3af487f4105810001d293af7e460ee41d51eda003376f10576d1d7799909be75`.
- AAB SHA256 `fcb152da8df7fe66939ce8c93c038289fcc75a5c6057197af10453b9becf3262`.
- Universal SHA256 `32e552b82cf81425eeb1e5369d218f1833e6f619a2ab848f990a3f53ea2c453c`.
- Store-kit SHA256 `04aab56deee6e12587f6fa03f218f465cc1a0201dc2071894a64b6ee742b9538`.
- Publiczny APK HTTP200/63001694B i store-kit HTTP200/2473050B pobrano bez
  uwierzytelnienia i ponownie sprawdzono SHA256. AAB/universal mają zgodne digesty serwera.

Lokalne kopie `/home/roch/.cache/candyverse/artifacts/kingdom-1.1.0-3/`.
Certyfikat `2064a303250785a1ef85029a03a543dc759ab6d715f1fb2f05dccdca04e70506`
pozostaje taki sam jak1.0.0. Pakiet zawiera listing PL/EN, ikonę512, banner1024×500,
aktualne zrzuty/provenance, politykę i wyniki QA. Żadnych prywatnych kluczy.
Grafiki AI są lokalne, nie ma runtimeAI/nowych SDK; [źródła i prompty](../assets/kingdom/README.md).

## Telefon i ograniczenia

- Właściciel zaakceptował nową oprawę/przejścia w code2, ale wykrył flash podczas
  placement. Znaleziono i naprawiono białą warstwę zapisu, dodano regresję.
  **Właściciel jawnie polecił pominąć ponowny test telefonu. Nie prosić ponownie.**
  Code3 nie został na nim zainstalowany: USB odłączono przed aktualizacją;
  na telefonie pozostał1.1.0+2. Nie przypisujemy code3 ręcznego PASS telefonu.
- Baseline telefonu code2:1202s/699 ruchów/742 reakcje, JUnit1/0/0, GPU Impeller;
  eksport ogona wrappera dokończono ręcznie po edycji działającego skryptu.
  [Historyczny raport code2](KINGDOM_CODE2_REPORT.md). Świeży wrapper CI code3 PASS.
  Nie publikować zastąpionego draftuv1.1.0-rc.1/code2. Publiczny1.0.0-rc.1 bez zmian.
- Brak długiej ręcznej oceny pełnej ekonomii bez fixture.60FPS jest celem;
  CPU nie jest benchmarkiem GPU, a profil code2 nie dowodzi wydajności code3.
- Konto Play Console8799678699020536617 osobiste, weryfikacja w toku. Brak
  potwierdzonego dostępu do Console/wpisu aplikacji; nie przesłano AAB i nie
  zaakceptowano zobowiązań prawnych za wydawcę. APK GitHub nie zalicza testu Play.
- Klucz `/home/roch/.candyverse-signing/v1/` poza Git,0700/0600. Nie regenerować;
  właściciel wykonuje backup poza komputerem i zachowuje certyfikat przy Play
  App Signing (ADR-0014). [Procedura](RELEASE_GOOGLE_PLAY.md).

## Przekazanie

Root main z implementacją: PR#14/7b5db1a. Przekazanie raportów, listing/README,
publicznych linków i contents:read: [PR#15](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/15),
branch docs/kingdom-release-handoff, commit531fc68 i aktualizacja tego odnośnika.
Kod aplikacji pozostaje identyczny z przetestowanym źródłem61c34a4.
Wcześniejsze commity dowodów:ab14489/62fdc2f/e69ed04; code3:5dcc9f8/f4666f1.
Nowy agent czyta AGENTS→README→INDEX→STATUS→ROADMAP; nie powtarza wykonanej implementacji.

**Jedno konkretne następne zadanie:** po zakończeniu weryfikacji konta właściciela
utworzyć wpis Candyverse w Play Console do testu wewnętrznego aktualnego AAB.
