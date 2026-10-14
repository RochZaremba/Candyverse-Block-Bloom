# ADR-0006: Małe PR-y i trwały handoff

**Status:** Accepted  
**Date:** 2026-10-14

## Context

Codex może pracować w wielu sesjach/branchach i stracić kontekst.

## Decision

AGENTS.md + STATUS.md + task IDs w ROADMAP, małe commity, PR dla pionowego fragmentu, zielone testy przed merge.

## Consequences

Kolejny agent wie, co zrobiono; czytelny diff i historia. Więcej operacji git, ale małe ryzyko porzuconych zmian.

## Alternatives rejected

Jeden duży branch i jeden końcowy commit — trudny przegląd i wznowienie.
