# STATUS — aktualizuj na końcu każdej sesji

**Data aktualizacji:**2026-10-15. **Stan:** T-001–T-009 scalone. T-010 i T-011 mają otwarte PR-y; finalny20min QA pozostaje niezaliczony do potwierdzenia wyniku.

## Task tracker

| Task | Status | Dowód |
| --- | --- | --- |
| T-001 Bootstrap | DONE | PR#1, `a35c0e4` |
| T-002 Engine | DONE | PR#2, `d65c100` |
| T-003 Scoring/RNG | DONE | PR#3, `c74f03b`, `f27948e` |
| T-004 Touch UI | DONE | PR#4, `725561e`, `0af536b`, `6bfeacf` |
| T-005 Visual/VFX/SFX | DONE | PR#5, `96cf704`–`2148fcc` |
| T-006 Upgrades | DONE | PR#6, `c3cd0e2`–`3b6712b` |
| T-007 Island | DONE | PR#7, merge `24ba7c3` |
| T-008 Save/economy | DONE | PR#8, merge `b4cb8b4`, CI38646672217 SUCCESS |
| T-009 Settings/i18n | DONE | [PR#9](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/9), merge `d50e612`, head `a98dbe4`, CI38651090829 SUCCESS;155 Flutter/62 Dart |
| T-010 QA/performance | IN_PROGRESS | [PR#10](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/10), head `e1c5922`;159 Flutter/62 Dart lokalnie PASS; native20min PENDING |
| T-011 Play Store prep | IN_PROGRESS | [PR#11](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/11), branch `chore/playstore-release`; podpisane APK/AAB i polityka gotowe, finalne CI/screenshoty w toku |

## Testy i poprawki

- T-010: natywny AOT profile/JUnit runner zamiast zrywającego się FlutterDriver, ADR-0015. Rzeczywisty DataStore pod testowym prefiksem, sześć ekranów, upgrade/eraser, jednokrotna nagroda, wszystkie zakupy, reset i20 minut UI gry/wyspy. UUID, Stopwatch i hostowy pomiar wymagane w raporcie; nie zaliczamy builda jako aktywnej gry. Poprzednie nieudane próby nie są wynikiem pozytywnym.
- JDK21 `assembleProfile assembleProfileAndroidTest` PASS na obu branchach.159/159 Flutter,62/62 Dart, format/analyze/docs i15/15 Python release tools PASS lokalnie. Finalne CI trzeba odczytać.
- Przegląd prawdziwego PNG wykrył ucinanie dolnej części tray na krótkim ekranie. `f191325` dopasowuje planszę/panele; testy393×650 i320×592 potwierdzają widoczność trzech figur i placement, nowy golden `game_phone_compact.png`. Tekst200% zachowuje scroll.
- Poprzedni podpisany APK przeszedł API24/36/35-16KB w CI[38703558729](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/38703558729). Powtórzenie na nowym buildzie pozostaje wymagane. Kolejny wcześniejszy run38708234422: API24/36 PASS,16KB brak świeżej hierarchii UI przy starcie — diagnostyka w toku, bez zaliczania tej próby.
- Emulator nie potwierdza60FPS średniego telefonu, odsłuchu ani wibracji. Te kontrole nadal NOT RUN na urządzeniu fizycznym. Szczegóły: [QA_REPORT](QA_REPORT.md).

## Kandydat wydania

- `com.renvo.candyverse`, wersja1.0.0+1, Renvo, rochzaremba@gmail.com. Release wymaga zewnętrznego podpisu; wyłączony backup/transfer i minimalne permissions; brak INTERNET w release. TestSDK jest wykluczony z release przez Flutter Gradle.
- APK po poprawce układu: SHA256 `8e4f0f670e476533f46e6f3b56f956e2700b5d8e0cd422da64cb9f14efe5e975`,50988653B. AAB: `a07af0a46f36cfcd3cbde96a582b7ad8541140aa4045f91be203bdefe428efd3`,50197815B. Pliki lokalnie `/home/roch/.cache/candyverse/artifacts/candyverse-1.0.0-1.apk` i `.aab`; szkic GitHub `v1.0.0-rc.1` pozostaje DRAFT do zielonego QA.
- APK i universal APK z finalnego AAB: audit SDK24/36, manifest/permissions/backup,6 ELF64/ZIP16KB i podpis PASS. Bundletool1.18.3 validate, JAR verification i PAGE_ALIGNMENT_16K PASS. Nie jest to przyjęcie przez Google Play.
- Certyfikat SHA256 `2064a303250785a1ef85029a03a543dc759ab6d715f1fb2f05dccdca04e70506`. Prywatny klucz i konfiguracja są poza Git w `/home/roch/.candyverse-signing/v1/`, katalog0700/pliki0600. Właściciel musi wykonać backup poza komputerem i zachować ciągłość certyfikatu przy Play App Signing (ADR-0014). Hasła nie są w dokumentacji/logach.
- Autorski launcher/splash, store icon512 i feature graphics1024×500 PL/EN gotowe. Prawdziwe finalne screenshoty do dołączenia po CI. Pełna polityka offline w Settings oraz publiczna: https://rochzaremba.github.io/Candyverse-Block-Bloom/ (HTTP200 i zgodność źródła potwierdzone). Hosting branch `docs/privacy-site`, commit `efe5f2a906d8e036a718ff1fe0af51fe32548460`; źródło `public_pages/` w PR#11.

## Blokery i następny krok

- Play Console `8799678699020536617`: **konto osobiste, weryfikacja w toku**, potwierdzone przez właściciela. Nie ma potwierdzonego dostępu narzędziowego ani wysłanego AAB/deklaracji. Zamknięty test12 testerów/14 kolejnych dni i wniosek o dostęp produkcyjny pozostają etapem konta właściciela, zgodnie z aktualnym wymaganiem dla nowych kont osobistych. Instalacje APK spoza Play nie zastępują tego testu.
- Nie publikowano w Google Play. GitHub prerelease nadal szkicem. Nie oznaczamy nieprzetestowanych funkcji jako ukończonych.
- Worktree: root `main` stabilne na `d50e612`; `.../candyverse-workers/t010` branch `test/qa-hardening`; `.../t011` branch `chore/playstore-release`. Workerzy zakończyli przekazane moduły, root integruje.
- **Jedno następne zadanie:** odczytać finalny native20min smoke PR#10 (raport czasu/aktywności/JUnit) i naprawić ewentualny błąd przed scaleniem.

- **Najnowszy runner `8e70d6d`:** native run38708821882 utracił emulator przy Settings→Game; nie potwierdzono jednej przyczyny awarii. CI wybiera teraz CPU rendering wyłącznie w testowej ActivityTestRule i RAM2048, zachowując AOT profile i20 minut. Programowy backend jest jawnie raportowany, nie dowodzi GPU/FPS telefonu. Lokalny testAPK skompilowany JDK21, bash/docs PASS. Nowy wynik nadal PENDING.

- **`c8b42e7`:** FittedBox usuwa ucięcie najwyższych/najszerszych figur w tray. Test wszystkich14 masek ×3 sloty ×2 rozmiary PASS;159 Flutter, analyze/format PASS. Finalne paczki zostają przebudowane, nowe sumy i smoke do zapisania przed releasem.

- **`07402e7`:** naprawiono null Intent w testowej ActivityTestRule oraz maskowanie błędu launch przez FlutterTestRunner; nieuruchomione oczekiwanie nie jest czasem aktywnej gry. Explicit Intent/fail-fast, profile testAPK compile JDK21 PASS8s. Nowy native20min PENDING.
- **Finalne APK/AAB po FittedBox:** audit/bundletool/certyfikat PASS;15 Python release tools. Smoke porównuje pełną64-polową maskę, obsługując figuręS z pustym origin. Cztery joby: APK API24/36/16KB oraz universal APK z AAB naAPI36, wszystkie wyniki nowego hasha do odczytu.

- **`e1c5922`:** native test zgłosił rzeczywisty błąd swojej sekwencji wyboru figury po illegal drag. Poprawiono reselection i dodano regresję;159/159 Flutter/analyze PASS. Brak zaliczonego20min, nowy run do odczytu.
