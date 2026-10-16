# STATUS — rzeczywisty stan i przekazanie prac

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
