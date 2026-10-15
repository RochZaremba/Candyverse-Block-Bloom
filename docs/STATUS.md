# STATUS — aktualizuj na końcu każdej sesji

**Data aktualizacji:** 2026-10-15
**Stan:** T-001–T-009 scalone; PR #9 CI SUCCESS (`38651090829`), merge `d50e612`. T-010 harness i T-011 konfiguracja przygotowywane równolegle, niezaliczone bez integracji/testów.
**Potwierdzone commity:** merge T-008 `b4cb8b4`, head `5d081ff`; T-009 `c34eced`, `bef81e1`, `3263632`, `085e97a`, `60316b5`, `a2a1f26`, `2eba311`, `ccbd433`.
**PR:** #1–#8 MERGED; [#8](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/8), finalne CI `38646672217` SUCCESS. [#9](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/9) MERGED, head `a98dbe4`, merge `d50e612`, CI `38651090829` SUCCESS.
**Repo/remote:** `RochZaremba/Candyverse-Block-Bloom`, fetch HTTPS/push SSH. Root integruje; workerzy mają rozdzielone moduły/worktree.

## Task tracker

| Task | Status | PR / commit / uwagi |
| --- | --- | --- |
| T-001 Bootstrap | DONE | `a35c0e4`, PR #1; format/analyze/test/docs/APK lokalnie i CI OK; smoke Android niewykonany |
| T-002 Engine | DONE | `d65c100`; 21 testów domeny w Dart, 27 testów łącznie; PR #2; lokalny debug APK OK |
| T-003 Scoring/RNG | DONE | `c74f03b`, `f27948e`; 39/39 Dart, 45/45 Flutter; PR #3; lokalny debug APK OK |
| T-004 Touch UI | DONE | `725561e`, `0af536b`, `6bfeacf`; 60 testów Flutter, 39 Dart, golden; PR #4; lokalny APK OK |
| T-005 Visual/VFX/SFX | DONE | `96cf704`, `c00a742`, `e2ddf36`, `1d657bc`, `2148fcc`; 66 Flutter/39 Dart, native APK OK; PR #5 |
| T-006 Upgrades | DONE | `c3cd0e2`, `7e4cf6c`, `eec3e6c`, `91ed2a7`, `3b6712b`; 90 Flutter/54 Dart/native APK OK; PR #6 |
| T-007 Island | DONE | `b1945e7`, `f632c57`, `daad0e1`;101 Flutter/56 Dart/native APK OK; PR #7, merge `24ba7c3` |
| T-008 Save/economy | DONE | `78c5565`, `6469890`, `ba3e6fd`, `99511f8`;125 Flutter/62 Dart/format/analyze/docs/APK OK; PR #8; CI kodu `2b9b74c` SUCCESS |
| T-009 Settings/i18n | DONE | PR #9 merge `d50e612`;155 Flutter/62 Dart/analyze/APK/CI OK |
| T-010 QA/performance | IN_PROGRESS | osobny harness Android; rzeczywisty smoke jeszcze niewykonany |
| T-011 Play Store prep | IN_PROGRESS | konfiguracja/ikony/audyt osobno; brak konta Play Console i klucza |

Dopuszczalne statusy: `TODO`, `IN_PROGRESS`, `BLOCKED`, `DONE` (po kryteriach akceptacji, nie po napisaniu kodu bez testów).

## Aktualna sesja / handoff

- **T-009:** sześć ekranów z prawdziwą nawigacją, pełne Settings, PL/EN zapisane w profilu i aktualizowane na otwartych ekranach, przywracane po restarcie. Reset wymaga potwierdzenia, usuwa profil i lokalną kwarantannę, przywraca ustawienia; przerywa callbacki poprzedniej generacji sesji. Przejście z wyniku na wyspę oraz prawdziwe zakupy. Centralne tłumaczenia także dynamicznych komunikatów i semantyki, SDK flutter_localizations.
- **Naprawione błędy zapisu:** ustawienia nie nadpisują nagrody, jeśli zapis runu utrwalił się, lecz odpowiedź z magazynu zgłosiła błąd. Po retry zachowują najnowszą rewizję. Reset po utracie potwierdzenia sprawdza odczyt; niepewny stan wymaga ponowienia resetu, blokuje inne mutacje i nie udaje sukcesu (ADR-0013).
- **Weryfikacja T-009:** pełny końcowy `flutter test`155/155; `dart test test/game`62/62; `flutter analyze` bez problemów; debug APK zbudowany33.5s. Goldeny PL Settings oraz EN Home/Upgrade; flow EN Settings→Home→Game/Island, wynik→wyspa/replay;320/412dp tekst2×; reset/cancel/failure/ack/retry. Recovery EN korzysta z języka urządzenia, gdy profil jest nieczytelny; poprawny profil zachowuje zapisany PL/EN. Cztery dodatkowe testy recovery6/6 i analyze OK. Logi `/home/roch/.cache/candyverse/t009-*.log`. Native smoke zmian T-009 jeszcze nie wykonany, należy do T-010.
- **T-008:** exact resume pełnych masek/skina/RNG/kolejek/faz, idempotentna nagroda, serializowany zapis, ceny GDD.125 Flutter/62 Dart i native debug APK OK. Częściowy native smoke na API36: run1, placement Z0,0, score40 i4 pola; JSON byte-identical po force-stop/start. Wcześniejszy emulator bez KVM zgłasza fully drawn dopiero po3m12s; brak reprezentatywnego FPS/odsłuchu/haptyki.
- **Workerzy:** `t009_settings` przygotowuje T-011 w `/home/roch/programing/Renvo/candyverse-workers/t011`, `release_audit` T-010 w `.../t010`, root T-009 w `.../t009`. Przygotowane T-011 commity `0dd901c`, `733ceb9`, `cbe60bd`, `ad1cdb0` nie są jeszcze zintegrowanym wydaniem. T-010 harness `d18991c` wymaga poprawionych fixture i uruchomienia.
- **Release właściciel:** `com.renvo.candyverse`, Renvo, rochzaremba@gmail.com. Właściciel potwierdził brak konta Play Console i klucza. Publiczny URL polityki jeszcze nieutworzony. Można przygotować klucz poza repo, podpisane APK/AAB i materiały; nie można oznaczyć publikacji Google Play jako wykonanej bez konta/dostępu i obowiązkowych etapów właściciela.
- **Niedokończone:** rzeczywisty20min smoke/profile T-010, finalny podpisany build/audyt, hosting polityki i materiały T-011, publikacja sklepu.
- **Następne jedno zadanie:** uruchomić poprawiony harness T-010 na Androidzie i zapisać realne wyniki.

- **T-010 próba pierwsza:** natywny profile build/start wykonany, test przerwany przy pierwszym screenshot przez Android PixelCopy result3 (brak bufora). Nie jest wynikiem pozytywnym. Dodano ograniczone retry wyłącznie tego błędu; pozostałe błędy propagują się. Ponowny emulator po restarcie hosta uruchamiany bez KVM.
- **Klucz:** wygenerowany prywatnie poza wszystkimi worktree, `/var/tmp/roch-candyverse-signing-v1/` (katalog0700, pliki0600). Hasła niewypisywane i poza Git. Wymaga trwałego, bezpiecznego backupu właściciela; `/var/tmp` może podlegać czyszczeniu. Podpisany finalny build jeszcze niewykonany.

- **Aktualizacja właściciela:** identyfikator konta Play Console `8799678699020536617`. Nie potwierdzono jeszcze dostępu narzędziowego, rodzaju konta ani gotowości produkcyjnej. Klucz ma teraz trwałą prywatną kopię `/home/roch/.candyverse-signing/v1/`, poza Git; wymagany backup poza tym komputerem.
- **CI T-010:** pierwszy KVM run `38694449126` zakończony FAILURE po utracie całego emulatora, przed ukończeniem scenariusza. Dodano ograniczenie pamięci/workerów Gradle i diagnostykę kernela; wynik kolejnej próby do sprawdzenia.

- **T-011 aktualnie:** `com.renvo.candyverse`, autorski launcher/splash, wyłączony backup/transfer; HTML polityki PL/EN i identyczna pełna treść offline; listing i feature graphics1024×500. Kandydat1.0.0+1 zbudowany/podpisany lokalnie, APK static audit SDK24/36,6 bibliotek ELF64/16KB/ZIP i brak sieciowych permissions PASS. Wcześniejszy AAB0.1 został zwalidowany bundletool1.18.3 i wygenerował poprawnie podpisany/audytowany APK; finalny AAB1.0 wymaga powtórzenia tych kontroli.155 testów Flutter i analyze po pełnej polityce OK. Nowy smoke produkcyjnego entrypointu jest przygotowany, jeszcze NOT RUN.
- **Play Console:** konto `8799678699020536617`, osobiste, właściciel potwierdził trwającą weryfikację. Brak potwierdzonego dostępu narzędziowego. Dalsze etapy sklepu wymagają zakończenia weryfikacji i sprawdzenia wymaganego closed test12 osób/14 dni; nie twierdzimy, że aplikacja jest w sklepie.

- **Polityka publiczna:** https://rochzaremba.github.io/Candyverse-Block-Bloom/ potwierdzone HTTP200 i byte-identical z `public_pages/index.html`. Wygenerowany branch hostingowy `docs/privacy-site`, commit `efe5f2a906d8e036a718ff1fe0af51fe32548460` zawiera tylko HTML/CSS/.nojekyll; źródło polityki należy do PR T-011.
- **Kandydat finalnego APK:** SHA256 `e3dacccae6d9fb6f7bf4a96b94db40962d2a320984f254a278e90c1b94df127f`; ponowny build po integracji dev SDK i ograniczeniu Gradle przeszedł audyt. Release Gradle wyklucza integration_test (potwierdzone lokalnym kodem SDK i produkcyjnym GeneratedPluginRegistrant). Szkic GitHub `v1.0.0-rc.1` pozostaje DRAFT do QA.155 Flutter/62 Dart/analyze/format/docs i debug APK po integracji OK.
- **Bloker QA runnera:** kernel potwierdził segfault RenderThread emulatora, nie OOM. Wyłączono emulację Vulkan; harness zachowuje produkcyjny SurfaceView i przechwytuje Flutter UI przez RepaintBoundary, pełne natywne PNG są osobnym smoke podpisanego APK. Kolejny run pozostaje do odczytania; nie oznaczono20min/FPS jako wykonanych.
- **T-010 runner natywny:** ADR-0015, AndroidJUnitRunner/FlutterTestRunner w wariancie profile, wyłącznie testowe zależności. Lokalnie JDK21 `assembleProfile assembleProfileAndroidTest` SUCCESS47s; format/analyze/docs/bash syntax PASS. UUID raportu, Stopwatch i hostowy czas zapobiegają zaliczeniu starego lub skróconego wyniku.20min nowego runnera jeszcze NOT RUN; PR#10 pozostaje otwarty.
- **Konto właściciela:** Play Console8799678699020536617 osobiste, weryfikacja w toku.
