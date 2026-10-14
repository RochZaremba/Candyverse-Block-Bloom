# ADR-0003: Jeden lokalny snapshot v1

**Status:** Accepted  
**Date:** 2026-10-14

## Context

Gracz musi wznowić run i nie dostawać nagrody dwa razy. Brak backendu i kont.

## Decision

AppSaveV1 serializowane wersjonowanym JSON-em pod jednym kluczem SharedPreferencesAsync; `completeRun()` idempotentne wg runId; zapis jednej całości po zmianie.

## Consequences

Minimalna architektura i łatwe testy. Nie daje gwarancji transakcji przy awarii systemu; w razie zwiększenia wymagań zmienić na transakcyjne SQLite z nowym ADR.

## Alternatives rejected

Wiele nieskoordynowanych kluczy — ryzyko rozjazdu salda/run; chmura — poza zakresem.
