# ADR-0015: Natywna instrumentacja profilowego QA

**Status:** Accepted  
**Date:** 2026-10-15

## Context

Dłuższy harness integracyjny wymaga prawdziwego DataStore i20 minut aktywnej gry. Połączenie hostowego FlutterDriver/VMService wielokrotnie zanikało w CI przed ukończeniem scenariusza. W jednej próbie kernel potwierdził awarię hostowego RenderThread, lecz nie ustalono jednej przyczyny wszystkich rozłączeń. Niezależny podpisany APK przeszedł smoke API24/36/16KB.

## Decision

Domyślny wrapper QA używa natywnego FlutterTestRunner z Flutter SDK i AndroidJUnitRunner. Osobne androidTest uruchamia rzeczywistą MainActivity, wybieraną z packageName target context, więc nie koduje developerskiego ID. Flaga Gradle `candyverseInstrumentation=true` wybiera testBuildType profile; release nie zawiera testAPK ani SDK integration_test. AndroidX test dependencies są wyłącznie androidTestImplementation.

Gradle musi zakończyć connectedProfileAndroidTest powodzeniem. Raport zawiera unikalny token uruchomienia, rzeczywisty Stopwatch dwell, hostowy czas instrumentacji, liczniki ruchów/reakcji/cykli oraz FrameTiming. Wrapper wymaga zgodnego tokenu, czasu i aktywności; nie przyjmuje starego logu jako wyniku. Domyślny renderer APK pozostaje bez zmian; stare drive można wybrać jawnie na urządzeniu, gdzie połączenie działa.

## Consequences

QA obejmuje profil AOT, natywne preferencje i te same widgety bez zależności od hostowego RPC. Emulator nadal nie reprezentuje telefonu; metryki nie potwierdzają60FPS ani odsłuchu/wibracji. Fixture progresji są jawne i wyłącznie w testowym entrypoincie. Nie skracamy20 minut ani nie zaliczamy nieudanych prób. Dokumentujemy wyniki dopiero po narzędziowym potwierdzeniu.

## Alternatives rejected

Zaliczenie samego uruchomienia albo obniżenie długości smoke ukrywałoby brak dowodu stabilności. Debugowe metryki nie zastępują profile. Zmiana produkcyjnego renderera dla naprawienia runnera wymagałaby osobnych dowodów i nie jest częścią tej decyzji.

Źródła: [Flutter integration tests](https://docs.flutter.dev/testing/integration-tests), natywny FlutterTestRunner i przykład androidTest w zainstalowanym SDK3.47.2.

## Update2026-10-15

Run38708821882 utracił cały emulator także przy natywnym JUnit, po Settings→Game; kernel nie potwierdził OOM ani kolejnego segfault w tej próbie. CPU renderer jest teraz jawną opcją testowej ActivityTestRule, przekazywaną wyłącznie przez argument instrumentacji. Używa oficjalnych stałych FlutterShellArgs z SDK (`enable-software-rendering=true`, `enable-impeller=false`). CI wybiera tę opcję; raport oznacza softwareRendering=true. Profil AOT i20min pozostają wymagane, metryk CPU nie przedstawiamy jako GPU/FPS telefonu. Produkcyjny APK i jego oddzielny smoke zachowują domyślny renderer.

Kontrola samego scenariusza jest współdzielona z hostowym widget testem: MemoryStorage, jeden cykl, jawna etykieta storageKind. Służy wykrywaniu błędów finderów i przejść bez przebudowy Androida. Nie jest testem trwałości ani20min; wrapper natywny odrzuca tę etykietę. Android pozostaje jedynym źródłem dowodu DataStore i realnego czasu.
