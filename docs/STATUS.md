# STATUS — aktualizuj na końcu każdej sesji

**Data aktualizacji:** 2026-10-15
**Stan:** T-001–T-008 zaimplementowane i przetestowane. T-008 ma ekonomię, zapis/resume i obsługę błędów; CI poprzednich headów SUCCESS (`38644250421`, `38645088319`); pełne maski dodatkowo sprawdzone lokalnie, najnowszy CI/merge odczytaj narzędziowo.
**Potwierdzone commity:** T-008 `78c5565`, `6469890`, `99511f8`, `2b9b74c`, `c037836`; merge T-007 `24ba7c3`, T-006 `ab53641`, T-005 `1f2d92c`.
**PR:** #1–#7 MERGED; [#7 — T-007](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/7), CI `38641631667` SUCCESS. [#8 — T-008](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/8): CI kodu `2b9b74c` SUCCESS; najnowszy head i merge odczytaj przez `gh pr view 8` / `git log`.
**Repo/remote:** `RochZaremba/Candyverse-Block-Bloom`, fetch HTTPS/push SSH. Root pracuje sam; T-007 worker odmówił startu przez brak kredytów, więc jego zadanie wykonał root.

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
| T-008 Save/economy | DONE | `78c5565`, `6469890`, `ba3e6fd`, `99511f8`;124 Flutter/61 Dart/format/analyze/docs/APK OK; PR #8; CI kodu `2b9b74c` SUCCESS |
| T-009 Settings/i18n | TODO | — |
| T-010 QA/performance | TODO | — |
| T-011 Play Store prep | TODO | — |

Dopuszczalne statusy: `TODO`, `IN_PROGRESS`, `BLOCKED`, `DONE` (po kryteriach akceptacji, nie po napisaniu kodu bez testów).

## Aktualna sesja / handoff

- **T-008 zaimplementowane:** pure Dart AppSaveV1/economy, walidowany wersjonowany JSON, exact resume board/tray masks+skins/RNG/kolejki/kart/eraser; monotonic ID przed runem/retry; nagroda i rekord w jednej idempotentnej finalizacji; ceny GDD, kolejne poziomy, brak pasywnych monet. SharedPreferencesAsync/DataStore Android; serializowane operacje gry/zakupów/ustawień. Home saldo/rekord/WZNÓW; realne zakupy i informacje cenowe wyspy.
- **Obsługa błędów:** bramka wejścia na czas zapisu; wynik po zapisaniu finalizacji, retry tej samej operacji (także restart); saldo i poziom zmieniają się po sukcesie. Uszkodzony/nowszy JSON zachowany i kopiowany do lokalnej kwarantanny; UI retry/jawne potwierdzenie odzyskania. Nie obiecujemy pełnej durability awarii systemu (ADR-0003/0011).
- **Testy dotychczas:** baseline101/101; pełny Flutter124/124, Dart61/61. Testy realnej nawigacji, pause/relaunch, zakup+restore, save-failure/retry, opóźniona finalizacja, repeat reward, przerwane potwierdzenie po zapisie na dysku, snapshot użycia gumki, równoczesne ustawienia/zakup, phase/counter/schema validation. Nowe Home i island_purchase_412 goldens; zakupowa wyspa obejrzana. Końcowy format/analyze bez problemów, docs32 poprawne; ponowny pełny Flutter124/124 i Dart61/61 OK. Native debug APK OK132.7s (finalny incremental11.5s po dodaniu pełnych masek), zainstalowany na API36; Częściowy smoke: rzeczywisty Home z wyspą/saldem obejrzany (`t008-home-rendered.png`); utworzony run1, umieszczona figura Z w0,0, DataStore odczytany przez run-as potwierdza score40,4 zajęte pola, zużyty slot0 oraz niezmieniony RNG1786627809. Po force-stop/start cały JSON jest identyczny (`t008-native-move.json`, `t008-native-restart.pb`); wizualne WZNÓW po restart jeszcze do sprawdzenia. Emulator zgłasza pierwszy fully drawn dopiero po3m12s, początkowe zrzuty czarne; brak reprezentatywnego pomiaru startup/performance.
- **Commity/branch/PR:** `feat/progression-save`, worktree `/home/roch/programing/Renvo/candyverse-workers/t008`; domena `78c5565`, integracja `6469890`. PR #8; CI `38644250421` SUCCESS dla `2b9b74c`; ostatnie uzupełnienie pełnych masek zgodnie z ADR-0008 także przechodzi workflow przed merge. Najnowszy head/merge odczytaj narzędziowo.
- **T-007:** PR#7 MERGED `24ba7c3`; finalne CI `38641631667` SUCCESS;101 Flutter/56 Dart/APK oraz scene levels0–3,4 postacie i accessibility/lifecycle potwierdzone.
- **Android smoke poprzedni:** Home→Game→placement0,0, score10 potwierdzone na wcześniejszym T-005 APK. Emulator AOSP ATD/no-KVM/no-audio nie potwierdza odsłuchu/haptyki ani reprezentatywnego FPS. Pełne20min QA w T-010.
- **Release dane właściciela:** docelowy `com.renvo.candyverse`, wydawca Renvo, kontakt rochzaremba@gmail.com. Zapisano w RELEASE_GOOGLE_PLAY; migracja konfiguracji i weryfikacja finalnego manifestu w T-011. Brak publicznego URL polityki i klucza upload blokuje publikację, nie rozwój gry.
- **Artefakty/logi:** `/home/roch/.cache/candyverse/t008-*.log`, APK/screenshoty w `/home/roch/.cache/candyverse/artifacts`, goldens w repo. Workerzy niedostępni przez quota kredytów; root realizuje etap samodzielnie. Ostateczny snapshot wymaga pełnych masek zgodnie z ADR-0008; wcześniejsze lokalne APK development ze skróconymi wpisami ID+skin mogą wymagać potwierdzonego odzyskania profilu (V1 nie została jeszcze wydana).
- **Niedokończone:** pełny Android smoke oraz bieżący stan finalnego merge PR#8 do odczytania narzędziowo; komplet ustawień/reset/PL-EN T-009, QA T-010 i release T-011.
- **Następne jedno zadanie:** **T-009 — komplet Settings, PL/EN i potwierdzony reset lokalnych danych**, po zamknięciu PR T-008.
