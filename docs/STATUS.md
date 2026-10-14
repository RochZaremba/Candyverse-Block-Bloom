# STATUS — aktualizuj na końcu każdej sesji

**Data aktualizacji:** 2026-10-14
**Stan:** T-001–T-007 przetestowane lokalnie. Gra, ulepszenia i autorska żywa wyspa działają; portfel/purchases/save/i18n jeszcze niegotowe.
**Potwierdzone commity:** T-007 `b1945e7`, `f632c57`, `daad0e1`; merge T-006 `ab53641`, T-005 `1f2d92c`, T-004 `fa9fec6`.
**PR:** #1–#6 MERGED; PR T-007 przygotowywany. Najnowsze head/merge odczytaj przez `gh pr view`/`git log`.
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
| T-007 Island | DONE | `b1945e7`, `f632c57`, `daad0e1`;101 Flutter/56 Dart/native APK OK; PR przygotowywany |
| T-008 Save/economy | TODO | — |
| T-009 Settings/i18n | TODO | — |
| T-010 QA/performance | TODO | — |
| T-011 Play Store prep | TODO | — |

Dopuszczalne statusy: `TODO`, `IN_PROGRESS`, `BLOCKED`, `DONE` (po kryteriach akceptacji, nie po napisaniu kodu bez testów).

## Aktualna sesja / handoff

- **Zrobione T-007:** oryginalne Canvas/painter diorama Candy Tree/Jelly House/Rainbow Fountain levels0–3; cztery odmienne Pink Mochi/Blue Jelly/Lemon Blob/Minty Monster z idle/blink/breathe i tap reaction; właściwa semantyka48dp; stop przy OS/user reduced-motion, tle i TickerMode. Home ma żywy fragment świata i realną trasę Island, a obiekty otwierają informacje. Brak atrap zakupu — adapter ekonomii będzie w T-008.
- **Testy:** format/analyze/docs OK; Flutter101/101 (pełny generator i późniejsze porównanie golden); Dart56/56. Golden wyspy level0/1/2/3 i Home odświeżone, level3 obejrzany;320/412dp tekst2×, semantyka/react wszystkich postaci, lifecycle bez tickerów w tle/reduced, nawigacja i details OK. Początkowy błąd fixture SemanticsHandle poprawiony przez jawne finally/dispose przed końcem testu. Native debug APK OK19.5s.
- **Potwierdzone CI/merge:** T-005 run `38638144507` SUCCESS, merge `1f2d92c`; T-006 run `38639887735` SUCCESS, merge `ab53641`. T-007 CI sprawdzimy przed merge aktualnego PR head.
- **Android smoke częściowy:** rzeczywisty API36 AOSP ATD: Home→Game, wybór jednopolowej figury i placement w0,0, wynik10, zużyty slot oraz feedback „Klocek na miejscu” potwierdzone screenshotem `t005-move.png`; także Home/Game zrzuty obejrzane. To wcześniejszy APK T-005, nie pełny smoke upgrade/wyspy/save. Emulator no-audio/no-KVM nie potwierdza odsłuchu, haptyki ani reprezentatywnego FPS.
- **Artefakty/logi:** `/home/roch/.cache/candyverse/artifacts`, logi `t007-*.log`; referencje trwałe w `test/goldens`. APK i kod nieutracone po tmpfs quota. Dalsze worktree pod fizycznym `/home`; test/failures oraz android/.kotlin ignorowane jako artefakty.
- **Decyzje:** brak nowej istotnej decyzji T-007; realization ADR Flutter2D/tokeny/odrębna domena. Zasoby własne, licencje aktualne.
- **Niedokończone:** T-008 monety/finalizacja/zakupy/save/resume, T-009 komplet settings/PL-EN/reset, QA oraz release. Brak docelowego applicationId, wydawcy/kontaktu/publicznego privacy URL i klucza podpisującego nadal blokuje publikację, nie rozwój gry.
- **Następne jedno zadanie:** **T-008 — ekonomia i pojedynczy lokalny snapshot**, na `feat/progression-save` po merge T-007. SharedPreferencesAsync API potwierdzone w oficjalnej dokumentacji pakietu; nie obiecujemy pełnej durability przy katastrofalnej awarii.
