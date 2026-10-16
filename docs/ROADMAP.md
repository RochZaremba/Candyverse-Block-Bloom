# Roadmap — single source of truth dla kolejności pracy

Zadania mają stabilne ID. **Status wykonania prowadź wyłącznie w `STATUS.md`, nie duplikuj go tutaj.** Agent bierze najniższy ID z niezrealizowanymi kryteriami i spełnionymi zależnościami; nie blokuje się na zbędnych perfekcjonizmach wczesnych etapów, ale nie zamyka pozornie tasków.

| ID | Zadanie | Zależności | Kryterium akceptacji | Preferowany branch |
| --- | --- | --- | --- | --- |
| T-001 | Bootstrap Flutter / Android | — | `flutter create`, konfiguracja Android API 36+, uruchamia się Home, podstawowe testy/format | `chore/flutter-bootstrap` |
| T-002 | Modele i silnik planszy | T-001 | testy placement, clear rows/cols, 8×8, 12+ figur, tray, game-over | `feat/puzzle-engine` |
| T-003 | Punktacja i seedowane RNG | T-002 | testowane score/combo/fair refill, deterministic replay | `feat/scoring-rng` |
| T-004 | UI game i sterowanie dotykiem | T-002 | drag-drop, ghost, illegal move, adaptacja do ekranów | `feat/game-ui` |
| T-005 | Spójny art direction + VFX + SFX | T-004 | cukierkowa plansza, animacje, dźwięk, mute/reduced-motion, asset licensing | `feat/candy-visuals` |
| T-006 | 3 roguelite upgrades | T-003,T-004 | karty, progi, efekty, edge case eraser, testy | `feat/roguelite` |
| T-007 | Scena wyspy + postacie | T-005 | 3 obiekty × 3 poziomy i 4 autorskie animowane postacie | `feat/island` |
| T-008 | Ekonomia i zapis/odczyt | T-006,T-007 | monety, zakupy, idempotentna finalizacja, resume, testy | `feat/progression-save` |
| T-009 | Navigation / settings / localization | T-008 | 6 ekranów, PL/EN, reset danych, brak martwych klików | `feat/app-polish` |
| T-010 | QA, golden/smoke, optymalizacja | T-009 | test matrix, profiling 60FPS aspirational, poprawione problemy | `test/qa-hardening` |
| T-011 | Privacy, store assets, release | T-010 | poprawne teksty/URL, listing, release config, test AAB, signing instr. | `chore/playstore-release` |

## Zamówiona prezentacja według referencji — 2026-10-16

| ID | Zadanie | Zależności | Kryterium akceptacji | Preferowany branch |
| --- | --- | --- | --- | --- |
| T-020 | Spójne komunikaty i intuicyjna nawigacja | T-019 | Wspólne cukierkowe komunikaty/ustawienia/recovery, nowe kontrolki z provenance, menu i gra z każdej zakładki wyspy, poprawny stos tras, PL/EN/320dp/tekst200%, testy i rendery | feat/candy-flow-polish |
| T-019 | Pięć ekranów według zdjęć właściciela | T-018 | Lokalne tła, żywe UI i zapis, menu/gry/wynik/okno/wyspa, działające zakładki i zakupy, goldeny 9:16, małe ekrany i tekst 2×, analyze/test/build | feat/reference-candy-ui |

## Pull request strategy

T-001 bootstrap osobny PR; T-002 i T-003 mogą mieć osobne PR; UI i VFX nie powinny trafiać jako jeden gigantyczny PR. Każdy PR ma testy i weryfikację, a merge jest dozwolony wyłącznie po pozytywnych wymaganych kontrolach. `main` zawsze ma się budować (po utworzeniu Flutter). W nowych sesjach sprawdzaj, czy branch/PR nie został już zrobiony.

## Dodatkowe reguły

- T-005 i T-007 są pełnoprawnymi, wymagającymi etapami; **nie obniżaj jakości grafiki ze względu na nazwę MVP**.
- Jeśli zabraknie dostępu do urządzenia, nie kłam o smoke testach — zapisz blokadę w STATUS i kontynuuj testy dostępne lokalnie.
- Po zakończeniu T-011 przejdź przez `docs/RELEASE_GOOGLE_PLAY.md`; nie publikuj bez właściciela.

## Zamówione rozszerzenie Candy Kingdom po rc.1

Właściciel2026-10-15 zatwierdził rozszerzenie zakresu. Szczegóły i kryteria:
[KINGDOM_EXPANSION](KINGDOM_EXPANSION.md).

| ID | Zadanie | Zależności | Kryterium akceptacji | Preferowany branch |
| --- | --- | --- | --- | --- |
| T-012 | Kontrakt i migracja | T-011 | zatwierdzony plan, PRD/GDD/ADR, kontrakt migracji starego zapisu | feat/candy-kingdom-expansion |
| T-013 |30 poziomów i pasywna ekonomia | T-012 | testy cen/czasu/atomowości/resume | feat/kingdom-economy |
| T-014 | Prestiż / gwiazdki | T-013 | potwierdzony reset3×30, trwała gwiazdka i nowy krajobraz | feat/kingdom-economy |
| T-015 | Renderowane assety i postacie | T-012 | marka właściciela,4 zwierzaki AI, budynki/wyspy i provenance | feat/kingdom-art |
| T-016 | Menu i domyślny EN | T-012 |2 przyciski, gear, zachowanie starego języka | feat/kingdom-navigation |
| T-017 | Płynne przejścia / komunikaty | T-016 | brak flash, candy UI z maskotką i dostępność | feat/kingdom-navigation |
| T-018 | Celebracje i QA | T-013–T-017 | efekty, testy/goldeny/build/native smoke i nowy kandydat | feat/candy-kingdom-expansion |
