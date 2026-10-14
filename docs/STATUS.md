# STATUS — aktualizuj na końcu każdej sesji

**Data aktualizacji:** 2026-10-14
**Stan:** T-001–T-006 przetestowane lokalnie, gra ma feedback i realne upgrades/eraser. T-005 PR #5 oczekuje CI/merge; T-006 osobny PR po bazowym merge. T-007 jeszcze bez kodu, brak ekonomii/save/i18n.
**Potwierdzone commity:** T-006 `c3cd0e2`, `7e4cf6c`, `eec3e6c`, `91ed2a7`, `3b6712b`; T-005 `2148fcc`, `8920ba5`; merge T-004 `fa9fec6`, T-003 `cc85322`.
**PR:** #1–#4 MERGED; [#5 — T-005](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/5) weryfikowany; PR T-006 przygotowywany. Najnowsze head/merge odczytaj przez `gh pr view`/`git log`.
**Repo/remote:** `RochZaremba/Candyverse-Block-Bloom`, fetch HTTPS/push SSH. Workerzy ukończyli T-005/T-006; root dalej sam (T-007 worker odmówił startu z powodu braku kredytów workspace).

## Task tracker

| Task | Status | PR / commit / uwagi |
| --- | --- | --- |
| T-001 Bootstrap | DONE | `a35c0e4`, PR #1; format/analyze/test/docs/APK lokalnie i CI OK; smoke Android niewykonany |
| T-002 Engine | DONE | `d65c100`; 21 testów domeny w Dart, 27 testów łącznie; PR #2; lokalny debug APK OK |
| T-003 Scoring/RNG | DONE | `c74f03b`, `f27948e`; 39/39 Dart, 45/45 Flutter; PR #3; lokalny debug APK OK |
| T-004 Touch UI | DONE | `725561e`, `0af536b`, `6bfeacf`; 60 testów Flutter, 39 Dart, golden; PR #4; lokalny APK OK |
| T-005 Visual/VFX/SFX | DONE | `96cf704`, `c00a742`, `e2ddf36`, `1d657bc`, `2148fcc`; 66 Flutter/39 Dart, native APK OK; PR przygotowywany |
| T-006 Upgrades | DONE | `c3cd0e2`, `7e4cf6c`, `eec3e6c`, `91ed2a7`, `3b6712b`; 90 Flutter/54 Dart/native APK OK; PR przygotowywany |
| T-007 Island | TODO | — |
| T-008 Save/economy | TODO | — |
| T-009 Settings/i18n | TODO | — |
| T-010 QA/performance | TODO | — |
| T-011 Play Store prep | TODO | — |

Dopuszczalne statusy: `TODO`, `IN_PROGRESS`, `BLOCKED`, `DONE` (po kryteriach akceptacji, nie po napisaniu kodu bez testów).

## Aktualna sesja / handoff

- **Zrobione T-006:** dokładnie3 efekty; seedowane distinct karty, progi5/10/15 z kolejką; caps2 poziomy Sugar/Lucky i lifetime2 eraser; brak pustych kart; eraser occupied/confirm/cancel, no score/coins/RNG/combo, no-move exception i rezygnacja; realny pendingCoins Lucky; phase guards blokują ruch podczas wyboru; hooks FX/audio/settings T-005 zintegrowane.
- **Testy:** format/analyze OK; `dart test test/game`54/54; `flutter test`90/90 po merge i aktualizacji Game/ghost/karty golden. Obejrzano `upgrades_412.png`, tekst/card targets czytelne. Native debug APK OK19.1s. Logi pełnych przebiegów w `/home/roch/.cache/candyverse/t006-*.log`.
- **Decyzje:** ADR-0010 — kolejka, RNG snapshot kart i lifetime cap erasera; ADR-0009 native feedback. Brak zmian zakresu GDD.
- **PR/CI:** T-005 [PR#5](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/5) oczekuje SUCCESS aktualnego head. T-006 nie scalać przed bazowym merge; root zachowuje osobne PR-y pionowych etapów.
- **Android:** API36 AOSP ATD w trybie programowym, boot_completed=1. APK T-005 zainstalowany/start/resumed oraz prawdziwy Home screenshot `t005-home-awake.png` obejrzany. Sprawdzany Home→Game; pełny smoke ulepszeń/odsłuch/haptyka/FPS nadal niewykonany. Nie deklarować60FPS na tej emulacji.
- **Środowisko:** poprzedni quota tmpfs rozwiązany przez zachowanie APK i flutter clean tylko zakończonych buildów. Checkout T-007 i przyszłe artefakty na fizycznym `/home`. Brak kredytów zatrzymał worker T-007 zanim zmienił pliki; root może wykonać go samodzielnie.
- **Niedokończone:** T-007 scena/bohaterowie, T-008 ekonomia+save, T-009 komplet ekranów/i18n/reset, T-010 QA/performance, T-011 release. Wydanie wymaga finalnego ID, wydawcy/kontaktu, URL polityki i klucza.
- **Następne jedno zadanie:** **T-007 — autorska wyspa z3 budynkami×3 poziomy i4 postaciami**, worktree `/home/roch/programing/Renvo/candyverse-workers/t007`, branch `feat/island`; po potwierdzeniu merge PR#5/T-006.
