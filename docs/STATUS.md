# STATUS — aktualizuj na końcu każdej sesji

**Data inicjalizacji:** 2026-10-14  
**Stan:** Dokumentacja wygenerowana; implementacja Fluttera **nie rozpoczęta**.  
**Ostatni potwierdzony commit:** brak (ZIP nie ma historii Git).  
**Repo/remote:** nie podano; agent ma odczytać faktyczny stan po uruchomieniu.

## Task tracker

| Task | Status | PR / commit / uwagi |
| --- | --- | --- |
| T-001 Bootstrap | TODO | — |
| T-002 Engine | TODO | — |
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

- **Zrobione:** przygotowano specyfikację, ADR, test plan, privacy i release checklist.
- **W trakcie:** nic.
- **Testy wykonane:** walidacja struktury dokumentów (weryfikacja ZIP); nie wykonano testów Fluttera.
- **Blokery:** brak danych wydawniczych (nazwa finalna, applicationId, dane publikującego, polityka prywatności URL, release key); nie blokują T-001.
- **Następne jedno zadanie:** **T-001** — sprawdź repo, skonfiguruj Flutter stable i Android, uruchom bazowy Home, zrób commit + PR/merge jeśli dostępne.

## Szablon aktualizacji po każdej sesji

```text
Data:
Branch / commit / PR (konkretne ID lub brak):
Tasks zmienione (bez udawania DONE):
Pliki / kluczowe decyzje:
Testy + wynik (komendy):
Co nie działa / zablokowane:
Następne jedno zadanie:
```

Agent powinien aktualizować górną sekcję, a nie tylko dopisywać historię na końcu. Nie oznaczaj TODO jako DONE, jeśli wymagania graficzne lub testy są niespełnione.
