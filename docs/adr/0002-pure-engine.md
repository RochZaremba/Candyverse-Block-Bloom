# ADR-0002: Pure Dart i deterministyczny silnik

**Status:** Accepted  
**Date:** 2026-10-14

## Context

UI mobilne nie może określać reguł gry, a losowość utrudnia regresję.

## Decision

Modele, reduktory i punktacja bez zależności Flutter; sterowalny RNG z seedem/stabilnym stanem; UI emituje walidowane akcje.

## Consequences

Łatwe unit testy, reproducibility, lepsza obsługa save/resume. Wymaga separacji prezentacji od domeny.

## Alternatives rejected

Pisanie logiki w widgetach — szybciej na starcie, ale trudno testować i debugować.
