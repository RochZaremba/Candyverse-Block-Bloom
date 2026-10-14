# STATUS — aktualizuj na końcu każdej sesji

**Data aktualizacji:** 2026-10-14
**Stan:** T-001–T-003 ukończone lokalnie; T-004 powstaje równolegle w osobnym checkout. Home pozostaje podstawowy do merge UI.
**Potwierdzone commity:** `c74f03b`, `f27948e` — T-003; `09ab75a` — merge T-002; `d44d9fd` — merge T-001.
**PR:** #1 i #2 MERGED; PR T-003 przygotowywany. Numer/najnowszy head i stan merge uzupełnimy po utworzeniu; końcowy stan można odczytać przez `gh pr view`/`git log`.
**Repo/remote:** `RochZaremba/Candyverse-Block-Bloom`; fetch HTTPS, push SSH. Workery T-003 `feat/scoring-rng`, T-004 `feat/game-ui` w osobnych worktree. Root koordynuje dokumentację, PR i merge.

## Task tracker

| Task | Status | PR / commit / uwagi |
| --- | --- | --- |
| T-001 Bootstrap | DONE | `a35c0e4`, PR #1; format/analyze/test/docs/APK lokalnie i CI OK; smoke Android niewykonany |
| T-002 Engine | DONE | `d65c100`; 21 testów domeny w Dart, 27 testów łącznie; PR #2; lokalny debug APK OK |
| T-003 Scoring/RNG | DONE | `c74f03b`, `f27948e`; 39/39 Dart, 45/45 Flutter; PR przygotowywany |
| T-004 Touch UI | IN_PROGRESS | osobny worker/checkout `feat/game-ui`; integracja T-003, testy i golden w toku |
| T-005 Visual/VFX/SFX | TODO | — |
| T-006 Upgrades | TODO | — |
| T-007 Island | TODO | — |
| T-008 Save/economy | TODO | — |
| T-009 Settings/i18n | TODO | — |
| T-010 QA/performance | TODO | — |
| T-011 Play Store prep | TODO | — |

Dopuszczalne statusy: `TODO`, `IN_PROGRESS`, `BLOCKED`, `DONE` (po kryteriach akceptacji, nie po napisaniu kodu bez testów).

## Aktualna sesja / handoff

- **Zrobione T-003:** całkowitoliczbowe placement/clear/multi-clear/combo; Sugar Rush bez wpływu na placement, pojedyncze zaokrąglenie końcowe; serializowalny Park–Miller RNG z rejection sampling; konfiguracja wag; ograniczenie dużych figur na zatłoczonej planszy; legalny element gwarantowany wyłącznie gdy istnieje; seedowane kolory z tokenów; replay ze snapshotu na nowym silniku i bez wpływu kolejności wcześniejszych wywołań.
- **Decyzja:** ADR-0008 opisuje algorytm RNG, fair replacement, stabilny snapshot konfiguracji i formułę punktacji. Pure Dart i dotychczasowa granica jawnych tray zachowane.
- **Testy bazowe:** repo czyste; `flutter test` 27/27. PR #2 MERGED (`09ab75a`), końcowe CI `38632160162` SUCCESS potwierdzone w poprzednim etapie.
- **Testy T-003:** format bez zmian; `flutter analyze` bez uwag; `dart test test/game` 39/39; `flutter test` 45/45. Testy skrajnych combo, pojedynczego floor, RNG/restore/branch replay, nielegalnych ruchów bez RNG, mutacji konfiguracji oraz 6400 losowań na planszach z pojedynczym wolnym polem.
- **Weryfikacja PR:** lokalny APK i CI sprawdzane przed merge aktualnego head. Testy lokalne nie oznaczają jeszcze zielonego CI.
- **Równolegle T-004:** worker UI zbudował controller, planszę, drag/ghost i tap select/place, Home Play oraz game-over/retry. Review zgłosił poprawki SafeArea/ghost i opisy figur dla TalkBack; nie oznaczamy UI DONE przed testami i przeglądem golden.
- **Środowisko:** zainstalowano Android 36 AOSP ATD x86_64, AVD `candyverse_api36`. Brak `/dev/kvm`; próba startu z `-accel off`. Smoke test/profiling nadal niepotwierdzone.
- **Niedokończone:** interfejs T-004, oprawa/dźwięk T-005, ulepszenia T-006, wyspa T-007, zapis/ekonomia T-008, ustawienia/i18n T-009, QA/release. Wydanie wymaga finalnego applicationId, danych wydawcy/URL polityki i klucza release. Brak tych danych nie blokuje T-003/T-004.
- **Następne jedno zadanie:** **T-004 — integracja i testy UI**, a po merge T-003/T-004 równoległe T-005 i T-006 zgodnie z zależnościami i upoważnieniem użytkownika.
