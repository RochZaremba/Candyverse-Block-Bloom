# ADR-0008: Serializowalny RNG i uczciwy generator trójek

**Status:** Accepted  
**Date:** 2026-10-14

## Context

GDD i ADR-0002 wymagają odtwarzania runu po zapisie oraz sprawiedliwego refill. Sam seed systemowego `Random` nie definiuje stabilnego, publicznego stanu algorytmu. Wybór masek, korekta legalności i skiny muszą pozostawać powtarzalne po przywróceniu snapshotu.

## Decision

Wersja 1 używa Park–Miller (`state = state * 16807 % 2147483647`), stan w zakresie `1..2147483646`. Seed normalizujemy `seed % 2147483646 + 1`. `nextInt` stosuje rejection sampling zamiast obciążonego modulo; działania pozostają dokładne także przy kompilacji Dart do JS. `RandomSource` stanowi granicę wstrzyknięcia generatora/testów.

`GameEngine.seeded(seed: ...)` generuje stan startowy; każdy zaakceptowany ruch odtwarza RNG ze snapshotu `GameState.rngState`, a następnie zapisuje jego nowy stan. Refill występuje po clear i zużyciu wszystkich slotów. Odrzucony ruch zwraca ten sam stan; ruch bez refill nie zużywa RNG. Stara granica `TraySource` pozostaje dla testów jawnych trójek i nie deklaruje odtwarzania własnego, zewnętrznego RNG.

Katalog 14 masek pozostaje bez zmian. Wagi bazowe są jawne w `GameBalance`. Przy zajętości co najmniej 32/64 pól waga figury mającej co najmniej 4 pola jest dzielona całkowitoliczbowo przez 3 z minimum 1. Trójkę losujemy niezależnie według wag. Jeśli nie pasuje żaden element, ale istnieje legalna maska katalogu, zastępujemy jeden losowy slot legalną maską, również według wag. Pełna plansza nie wymusza ratunku. Po ewentualnej korekcie losujemy trzy skiny spośród siedmiu identyfikatorów z palety tokenów. Snapshot przechowuje zarówno maski, jak i skiny i stan po wszystkich losowaniach.

Silnik/generator wykonują niezmienny snapshot konfiguracji wag, a suma wag musi mieścić się w zakresie RNG. Zmiana algorytmu, kolejności losowań lub balansu wymaga świadomej decyzji o kompatybilności save/replay.

Punktacja mnoży combo i Sugar Rush w jednej formule: `placementPerCell * placedCells + baseClear * comboNumerator * (4 + sugarRushLevel) ~/ 16`. Zaokrąglenie następuje raz po połączonym mnożeniu; samo placement nie ma mnożnika.

## Consequences

Run można rozgałęzić lub odtworzyć na świeżej instancji silnika niezależnie od wcześniejszych wywołań. Mały serializowalny stan i konfiguracja pozwalają testować granice, fairness oraz dokładną punktację. To nie RNG kryptograficzny; offline puzzle nie potrzebuje takiej własności. Testy utrwalają algorytm i nie gwarantują rozkładu każdej konkretnej krótkiej partii ani wygranej.

## Alternatives rejected

`dart:math Random(seed)` jako jedyny zapis — brak publicznego snapshotu stanu i gwarancji stałości algorytmu. Wielokrotne losowanie do skutku — niepotrzebnie zmienny koszt i liczba losowań. Gwarantowanie wszystkich trzech legalnych figur — silniejsza pomoc niż kontrakt GDD.
