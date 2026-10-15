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
| Testy i DoD | [Test Plan](TEST_PLAN.md) |
| Publikacja Google Play | [Release](RELEASE_GOOGLE_PLAY.md) i [raport kandydata](RELEASE_REPORT.md) |
| Prywatność i rodziny | [Privacy & Safety](PRIVACY_AND_SAFETY.md) |
| Pomysły na później | [Post V1](POST_V1.md) |
| Historia decyzji | [ADR](adr/README.md) |

## Zasada dla agentów

**Nowa sesja:** `AGENTS.md` → `STATUS.md` → `ROADMAP.md` → dokument specyficzny dla zadania → kod. Po wykonaniu: commit, PR (jeżeli można), testy, aktualizacja STATUS. Dokumentacja nie ma się rozrastać bez potrzeby; każda nowa ważna zasada powinna trafić do właściwego, istniejącego pliku albo nowego ADR.

## Status dokumentacji

Pakiet v0.1 = specyfikacja i plan. `docs/STATUS.md` startuje z zadaniami `TODO`; nie udaje zakończonej implementacji. Data przeglądu wymogów sklepu: 2026-10-14. Przed releasem zweryfikuj polityki ponownie.
