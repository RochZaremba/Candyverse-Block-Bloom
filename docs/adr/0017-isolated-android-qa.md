# ADR-0017: Izolacja aplikacji QA na fizycznym Androidzie

**Status:** Accepted  
**Date:**2026-10-15

## Context

Właściciel testuje Candy Kingdom na telefonie z istniejącym lokalnym zapisem.
Natywny scenariusz QA celowo tworzy portfel i wyspę testową oraz sprawdza reset.
Sama osobna nazwa preferencji nie chroni instalacji przed wymianą pakietu,
konfliktem certyfikatów albo odinstalowaniem przez narzędzie deweloperskie.

## Decision

Rozszerzamy natywną instrumentację ADR-0015: jawna właściwość Gradle
`candyverseInstrumentation=true` wybiera applicationId `com.renvo.candyverse.qa`
i nazwę „Candyverse QA”. Namespace/klasa Activity pozostają produkcyjne,
dlatego runner rozwiązuje klasę przez PackageManager zamiast składać ją z ID.
Wariant release odrzuca tę właściwość; produkcja zachowuje ID i podpis.

Domyślny skrypt używa instrumentacji na jawnie wybranym jedynym urządzeniu.
Wstępny Flutter build profile tylko kompiluje; instalacji dokonuje dopiero
Gradle z właściwością QA. Alternatywny diagnostyczny Flutter drive nie przekazuje
tej właściwości, więc skrypt dopuszcza go wyłącznie na emulatorze (`ro.kernel.qemu=1`),
przed wywołaniem Fluttera. Smoke podpisanej produkcji również wymaga emulatora.
Żaden wrapper nie czyści danych produkcji; dokumentacja i logi rozróżniają
host memory, natywny DataStore, CPU oraz rzeczywisty renderer telefonu.

## Consequences

QA nie potwierdza zachowania podpisu release; temu służy osobna macierz
podpisanego APK/AAB. Czyste emulatory są przeznaczone do testu produkcyjnego
entrypointu. Nowy profil aplikacji .qa może zawierać fixture i nie jest zapisem
gracza. Ręcznie nadane nazwy i cele adb nie zastępują kontroli pakietu.

## Alternatives rejected

Instalowanie instrumentowanej aplikacji pod produkcyjnym ID na telefonie
gracza albo użycie Flutter drive jako przezroczystego zamiennika instrumentacji
nie daje wymaganej izolacji danych i tożsamości instalacji.
