# ADR-0014: Ciągłość certyfikatu podpisującego

**Status:** Accepted  
**Date:** 2026-10-15

## Context

Pierwsza dystrybucja APK może poprzedzać zakończenie weryfikacji osobistego konta Play Console. Gra ma lokalny zapis bez chmury. Android wymaga zgodnego certyfikatu przy aktualizacji istniejącej instalacji.

## Decision

Zachowujemy wygenerowany zewnętrzny klucz jako tożsamość podpisanego APK. Nazwa aliasu `upload` nie oznacza, że można wyrzucić go po wybraniu nowego klucza Google. Przy konfiguracji Play App Signing należy zachować ten certyfikat przez udostępniony przez Google proces importu istniejącego klucza (PEPK), jeśli instalacje APK mają przechodzić na aktualizacje Play. Następnie można zarejestrować odrębny upload key, nie zmieniając certyfikatu aplikacji.

## Consequences

Klucz i hasła pozostają poza repo/logami/artefaktami publicznymi i wymagają backupu właściciela poza komputerem. Enrollment nie został wykonany. Nie akceptujemy automatycznie nowego certyfikatu ani warunków prawnych za wydawcę. Wybór innego certyfikatu wymaga jawnego uwzględnienia ponownej instalacji i możliwej utraty postępu.

## Alternatives rejected

Cicha wymiana certyfikatu przy przejściu do sklepu naruszyłaby oczekiwanie zachowania postępu offline. Klucz debug nie jest wydaniem.

Źródło sprawdzone2026-10-15: [Android app signing](https://developer.android.com/studio/publish/app-signing).
