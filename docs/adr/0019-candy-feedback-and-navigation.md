# ADR-0019: Spójne komunikaty i nawigacja

Status: Accepted — zamówienie właściciela 2026-10-16.

## Decyzja

T-020 uzupełnia oprawę T-019: wspólne cukierkowe panele dla komunikatów,
ustawień, odzyskiwania zapisu i wyboru ulepszeń. Nowy lokalny atlas kontrolek
pasuje do control-atlas; tekst, semantyka i działania pozostają widgetami.
Komunikaty nie zasłaniają gry modalnie; można je zamknąć i odczytać przy dużym
tekście. Błąd zapisu nadal blokuje następny ruch i oferuje prawdziwy retry.
Potwierdzenia operacji destrukcyjnych pozostają wymagane.

Menu jest dostępne ze wszystkich zakładek wyspy; przycisk gry otwiera lub
wznawia istniejącą sesję przez AppSession. Menu usuwa pośrednie trasy, a powrót
z ustawień przywraca ekran, z którego je otwarto. Zmiana prezentacji nie zmienia
silnika, ekonomii ani schematu zapisu. Zakres offline i prywatności bez zmian.
