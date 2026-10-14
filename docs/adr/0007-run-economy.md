# ADR-0007: Monety tylko z ukończonego runu

**Status:** Accepted  
**Date:** 2026-10-14

## Context

Nagrody za każdą akcję mogą prowadzić do duplikacji po przywróceniu stanu i nieszczelnej ekonomii.

## Decision

Pending coins liczone w runie, saldo portfela rośnie wyłącznie przy idempotentnej finalizacji; zakupy tylko kolejnych poziomów obiektów.

## Consequences

Prosty model bez farmienia przy restarcie, uczciwa progresja. Wymaga dopracowanego checkpointowania.

## Alternatives rejected

Monety natychmiast przy każdym clear bez globalnej transakcji — trudniejsza spójność.
