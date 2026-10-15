# ADR-0013: Ustawienia, tłumaczenia i niepewny reset

**Status:** Accepted  
**Date:** 2026-10-15

## Context

T-009 wprowadza PL/EN i reset jednego profilu ADR-0011. Zapis może utrwalić się przed utratą odpowiedzi. Ustawienia równoległe do niepotwierdzonej finalizacji nie mogą zastąpić nagrody starszym stanem. Reset musi uwzględniać usunięcie bez otrzymania potwierdzenia.

## Decision

SettingsModel pozostaje ChangeNotifier nad SavedSettings, a AppSessionScope udostępnia produkcyjną sesję trasom. Centralny AppStrings tłumaczy prezentowane komunikaty i semantykę PL/EN, także parametry liczbowe; Flutter SDK flutter_localizations zapewnia lokalizację standardowych kontrolek. Nazwy własne GDD pozostają niezmienne. Silnik nie zna języka.

Rewizje ustawień serializujemy razem z profilem. Odkładamy zapis ustawień, gdy kontroler gry oczekuje ponowienia niepotwierdzonej operacji; po powodzeniu zapisujemy najnowszą rewizję. Reset usuwa najpierw lokalną kwarantannę, następnie profil. Po wyjątku usunięcia odczyt pustego klucza potwierdza sukces; obecny profil potwierdza błąd, a błąd odczytu powoduje SaveResetUncertain. W tym stanie sesja blokuje pozostałe mutacje, przechowuje lokalne ustawienia i oferuje retry resetu. Udany reset zmienia generację sesji i unieważnia starsze callbacki.

## Consequences

Nie dodajemy biblioteki stanu ani zewnętrznego SDK lokalizacji. Nowe teksty wymagają wpisu centralnego i testów flow; zapis PL/EN jest częścią istniejącego schematu. Osobne testy obejmują zapis z utraconą odpowiedzią, następujące ustawienia, reset i jego retry. Ograniczenie durability ADR-0003 pozostaje.

## Alternatives rejected

Fire-and-forget ustawień oraz automatyczny sukces resetu po wyjątku mogłyby ukryć utratę progresji albo pozostawione dane. Reset przez zapis pustego profilu bez usunięcia diagnostyki nie spełnia obietnicy usunięcia danych.
