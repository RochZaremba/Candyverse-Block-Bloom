# STATUS — rzeczywisty stan i przekazanie prac

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
