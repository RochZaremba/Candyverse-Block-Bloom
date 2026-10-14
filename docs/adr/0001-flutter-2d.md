# ADR-0001: Flutter bez silnika 3D

**Status:** Accepted  
**Date:** 2026-10-14

## Context

Gra to plansza 8×8 + pojedyncza scena wyspy; najważniejsze są animacje UI i łatwość publikacji.

## Decision

Flutter stable, CustomPainter i wbudowany system animacji. Flame tylko po nowym ADR uzasadnionym pomiarem lub wyraźnym uproszczeniem.

## Consequences

Mało zależności, szybki hot reload, własna estetyka, mniej obciążeń. Wymaga dyscypliny w repaint i lifecycle.

## Alternatives rejected

Unity/Godot — za ciężkie dla zakresu; Flame od startu — niepotrzebny dopóki brak dużej symulacji.
