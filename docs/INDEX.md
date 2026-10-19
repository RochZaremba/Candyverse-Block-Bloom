# Indeks i sposób nawigacji

## Źródła prawdy

| Potrzeba | Otwórz |
| --- | --- |
| Wizja i granice produktu | [PRD](PRD.md) |
| Reguły, punkty, monety, upgrady | [Game Design](GAME_DESIGN.md) |
| Wrażenia, animacje, design tokens | [Visual Direction](VISUAL_DIRECTION.md) i [`../assets/design_tokens.json`](../assets/design_tokens.json) |
| Moduły Flutter, save, API wewnętrzne | [Architecture](ARCHITECTURE.md) |
| Zadania + zależności | [Roadmap](ROADMAP.md) |
| Obecny rzeczywisty stan i handoff | [Status](STATUS.md) |
| Nowa oprawa z pięciu zdjęć właściciela | [T-019 — podglądy](REFERENCE_UI_REVIEW.md) |
| Evolution1.3.0 — wydanie i QA | [Raport](EVOLUTION_RELEASE_REPORT.md) |
| Testy i DoD | [Test Plan](TEST_PLAN.md) |
| Publikacja Google Play | [Release](RELEASE_GOOGLE_PLAY.md) i [raport Candy Kingdom](KINGDOM_RELEASE_REPORT.md) |
| Prywatność i rodziny | [Privacy & Safety](PRIVACY_AND_SAFETY.md) |
| Pomysły na później | [Post V1](POST_V1.md) |
| Historia decyzji | [ADR](adr/README.md) |

## Zasada dla agentów

**Nowa sesja:** `AGENTS.md` → `STATUS.md` → `ROADMAP.md` → dokument specyficzny dla zadania → kod. Po wykonaniu: commit, PR (jeżeli można), testy, aktualizacja STATUS. Dokumentacja nie ma się rozrastać bez potrzeby; każda nowa ważna zasada powinna trafić do właściwego, istniejącego pliku albo nowego ADR.

## Status dokumentacji

Pierwotna specyfikacja v0.1 pozostaje źródłem zakresu V1. Stan implementacji i wyniki testów prowadzi [STATUS](STATUS.md); raporty [QA](QA_REPORT.md) i [wydania](RELEASE_REPORT.md) zawierają potwierdzone dowody oraz ograniczenia. Przed submission sprawdź ponownie wymagania sklepu.

Rozszerzenie po rc.1: [Candy Kingdom — plan i kontrakt](KINGDOM_EXPANSION.md).
