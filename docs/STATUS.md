# STATUS — aktualizuj na końcu każdej sesji

**Data aktualizacji:** 2026-10-14
**Stan:** T-001 i T-002 ukończone lokalnie. Aplikacja pokazuje podstawowy Home; silnik planszy nie jest jeszcze podłączony do UI. Następny etap T-003.
**Potwierdzone commity:** `d65c100` — modele/silnik i testy T-002; `204154e` — kontrakt i dokumentacja; `d44d9fd` — merge bootstrapu T-001.
**PR:** [#1 — T-001](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/1) MERGED. [#2 — T-002](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/2). Stan merge i najnowszy head sprawdź przez `gh pr view 2` / `git log`; ten handoff jest częścią PR #2.
**Repo/remote:** `RochZaremba/Candyverse-Block-Bloom`; fetch HTTPS, push SSH; branch `feat/puzzle-engine`. Uprawnienia ADMIN; reguły merge należy ponownie sprawdzić przed scaleniem.

## Task tracker

| Task | Status | PR / commit / uwagi |
| --- | --- | --- |
| T-001 Bootstrap | DONE | `a35c0e4`, PR #1; format/analyze/test/docs/APK lokalnie i CI OK; smoke Android niewykonany |
| T-002 Engine | DONE | `d65c100`; 21 testów domeny w Dart, 27 testów łącznie; PR #2; lokalny debug APK OK |
| T-003 Scoring/RNG | TODO | — |
| T-004 Touch UI | TODO | — |
| T-005 Visual/VFX/SFX | TODO | — |
| T-006 Upgrades | TODO | — |
| T-007 Island | TODO | — |
| T-008 Save/economy | TODO | — |
| T-009 Settings/i18n | TODO | — |
| T-010 QA/performance | TODO | — |
| T-011 Play Store prep | TODO | — |

Dopuszczalne statusy: `TODO`, `IN_PROGRESS`, `BLOCKED`, `DONE` (po kryteriach akceptacji, nie po napisaniu kodu bez testów).

## Aktualna sesja / handoff

- **Data:** 2026-10-14.
- **Zrobione:** niezmienna plansza 8×8 ze skinami; walidowane maski i katalog 14 różnych figur; akcja placement; legal placements; równoczesny clear wierszy/kolumn z unią pól; dokładnie 3 sloty, refill po ostatniej figurze; bazowe game-over. Metadane ruchu przygotowane dla UI i punktacji. CI rozszerzone o niezależny `dart test test/game`.
- **Commity:** `d65c100` implementacja; commit dokumentacji sprawdź w `git log`. Bootstrap PR #1 potwierdzony jako scalony, merge `d44d9fd`; jego końcowe CI `38630455721` SUCCESS.
- **Decyzje:** realizacja ADR-0002, bez nowych istotnych decyzji architektonicznych. `TraySource` to granica do generatora z T-003, bez domyślnego/fikcyjnego losowania. `test` dodano wyłącznie jako dev dependency, silnik nie importuje Fluttera.
- **Testy bazowe przed edycją:** `flutter test` 6/6 OK; repo było czyste.
- **Testy T-002:** `dart test test/game` 21/21 OK; `flutter test` 27/27 OK, w tym niezmieniony golden Home; `flutter analyze` bez uwag; format i walidacja dokumentów OK. Testy obejmują 14 masek i wszystkie originy -1..8 na planszy z przeszkodami, granice/kolizje/nielegalne sloty, niezmienność snapshotów, jedno- i wieloliniowe czyszczenie, przecięcie 15 pól/2 linie, 64 pola/16 linii, kolejność clear/refill/game-over i walidację generatora.
- **Weryfikacja PR:** `flutter build apk --debug` OK lokalnie. CI PR #2 uruchomione; merge wyłącznie po SUCCESS dla aktualnego head (format/analyze/Dart test/Flutter test/docs/APK). Main nie ma reguł wymagających dodatkowego review — potwierdzone API `rules/branches/main` zwróciło pustą listę. Wynik końcowego CI i merge sprawdź na PR; nie twierdzimy jeszcze, że CI T-002 przeszło.
- **Niedokończone:** punktacja/combo, seedowane RNG, wagi i fair refill (T-003); dotykowe UI (T-004); wyjątek game-over z eraserem (T-006); zapis (T-008). Pełna gra nie jest gotowa.
- **Środowisko / blokery:** brak podłączonego Androida/AVD — smoke test i profiling niewykonane. Brak finalnego applicationId, klucza release i danych wydawniczych; nie blokują T-002. Nadal konfiguracja developerska `com.example.candyverse`, podpis debug.
- **Następne jedno zadanie:** **T-003 — punktacja i seedowane RNG**, branch `feat/scoring-rng`, po potwierdzeniu merge PR #2.
