# ADR-0011: Serializowany zapis, bramka wejścia i odzyskiwanie

**Status:** Accepted  
**Date:** 2026-10-14

## Context

T-008 łączy ruchy, nagrody, zakupy i ustawienia w snapshot ADR-0003. Asynchroniczna odpowiedź magazynu może przyjść po kolejnej interakcji; uszkodzony lub nowszy JSON nie może być po cichu zastąpiony pustym profilem.

## Decision

`AppSaveV1` i reduktory ekonomii są czystym Dartem. Produkcyjny adapter używa `SharedPreferencesAsync` (domyślny Android DataStore); cały profil jest wersjonowanym JSON-em pod `candyverse.save.v1`. Mutacje sesji przechodzą przez jedną kolejkę, odczytując najnowszy stan wewnątrz operacji. Saldo i poziomy stają się widoczne po powodzeniu zapisu. Zaakceptowana akcja gry blokuje następne wejście na czas zapisu; wynik końcowy jest dostępny dopiero po utrwaleniu finalizacji. Błąd zachowuje snapshot w pamięci i oferuje ponowienie tej samej operacji.

Nieczytelny JSON pozostaje pod kluczem głównym. Jego oryginał kopiujemy do `candyverse.save.quarantine` przed pokazaniem odzyskiwania. To kopia diagnostyczna, nigdy drugi portfel ani alternatywne źródło progresji. Zastąpienie wymaga jawnego potwierdzenia utraty postępu; kopia pozostaje do potwierdzonego resetu danych. Błąd odczytu magazynu oferuje retry bez resetu.

## Consequences

Można testować restart i awarię zapisu deterministycznie na adapterze pamięciowym. Nie obiecujemy pełnej trwałości po katastrofalnej awarii systemu: ograniczenie ADR-0003 pozostaje. Zapis po każdej akcji oznacza krótki rzeczywisty czas oczekiwania; trzeba sprawdzić go na urządzeniu w QA. Kopia diagnostyczna pozostaje wyłącznie lokalna i także podlega resetowi.

## Alternatives rejected

Zapisy fire-and-forget i wiele kluczy salda — ryzyko nadpisania nowszego postępu. Automatyczny reset przy błędzie parsowania — ukryta utrata danych. Udawana gwarancja transakcyjnego dysku — nie jest kontraktem wybranego magazynu.
