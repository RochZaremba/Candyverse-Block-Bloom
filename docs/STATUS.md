# STATUS — aktualizuj na końcu każdej sesji

**Data aktualizacji:** 2026-10-14
**Stan:** T-001–T-007 scalone; T-008 ekonomia, zapis, resume i obsługa błędów zaimplementowane, końcowe kontrole w toku.
**Potwierdzone commity:** T-008 `78c5565`, `6469890`; merge T-007 `24ba7c3`, T-006 `ab53641`, T-005 `1f2d92c`.
**PR:** #1–#7 MERGED; [#7 — T-007](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/7), CI `38641631667` SUCCESS. PR T-008 przygotowywany na `feat/progression-save`.
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
| T-008 Save/economy | IN_PROGRESS | `78c5565`, `6469890`; końcowe kontrole i PR w toku |
| T-009 Settings/i18n | TODO | — |
| T-010 QA/performance | TODO | — |
| T-011 Play Store prep | TODO | — |

Dopuszczalne statusy: `TODO`, `IN_PROGRESS`, `BLOCKED`, `DONE` (po kryteriach akceptacji, nie po napisaniu kodu bez testów).

## Aktualna sesja / handoff

- **T-008 zaimplementowane:** pure Dart AppSaveV1/economy, walidowany wersjonowany JSON, exact resume board/tray skins/RNG/kolejki/kart/eraser; monotonic ID przed runem/retry; nagroda i rekord w jednej idempotentnej finalizacji; ceny GDD, kolejne poziomy, brak pasywnych monet. SharedPreferencesAsync/DataStore Android; serializowane operacje gry/zakupów/ustawień. Home saldo/rekord/WZNÓW; realne zakupy i informacje cenowe wyspy.
- **Obsługa błędów:** bramka wejścia na czas zapisu; wynik po zapisaniu finalizacji, retry tej samej operacji (także restart); saldo i poziom zmieniają się po sukcesie. Uszkodzony/nowszy JSON zachowany i kopiowany do lokalnej kwarantanny; UI retry/jawne potwierdzenie odzyskania. Nie obiecujemy pełnej durability awarii systemu (ADR-0003/0011).
- **Testy dotychczas:** baseline101/101; pełny Flutter122/122, Dart61/61. Testy realnej nawigacji, pause/relaunch, zakup+restore, save-failure/retry, opóźniona finalizacja, repeat reward, równoczesne ustawienia/zakup, phase/counter/schema validation. Nowe Home i island_purchase_412 goldens; zakupowa wyspa obejrzana. Analyze bez problemów po poprawieniu unused import, końcowy ponowny przebieg w toku. Native debug APK OK132.7s, zainstalowany na API36; smoke trwałego Android storage rozpoczęty, jeszcze nie potwierdzony.
- **Commity/branch/PR:** `feat/progression-save`, worktree `/home/roch/programing/Renvo/candyverse-workers/t008`; domena `78c5565`, integracja `6469890`. PR T-008 przygotowywany; końcowy head/CI/merge sprawdzić narzędziowo.
- **T-007:** PR#7 MERGED `24ba7c3`; finalne CI `38641631667` SUCCESS;101 Flutter/56 Dart/APK oraz scene levels0–3,4 postacie i accessibility/lifecycle potwierdzone.
- **Android smoke poprzedni:** Home→Game→placement0,0, score10 potwierdzone na wcześniejszym T-005 APK. Emulator AOSP ATD/no-KVM/no-audio nie potwierdza odsłuchu/haptyki ani reprezentatywnego FPS. Pełne20min QA w T-010.
- **Release dane właściciela:** docelowy `com.renvo.candyverse`, wydawca Renvo, kontakt rochzaremba@gmail.com. Zapisano w RELEASE_GOOGLE_PLAY; migracja konfiguracji i weryfikacja finalnego manifestu w T-011. Brak publicznego URL polityki i klucza upload blokuje publikację, nie rozwój gry.
- **Artefakty/logi:** `/home/roch/.cache/candyverse/t008-*.log`, APK/screenshoty w `/home/roch/.cache/candyverse/artifacts`, goldens w repo. Workerzy niedostępni przez quota kredytów; root realizuje etap samodzielnie.
- **Niedokończone:** końcowe kontrole/PR/CI/merge T-008; komplet ustawień/reset/PL-EN T-009, QA T-010 i release T-011.
- **Następne jedno zadanie:** **T-009 — komplet Settings, PL/EN i potwierdzony reset lokalnych danych**, po zamknięciu PR T-008.
