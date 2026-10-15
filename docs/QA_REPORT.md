# T-010 — raport QA

Stan2026-10-15:160/160 testów Flutter i62/62 testów silnika PASS.
Pełny20min natywny scenariusz na fizycznym telefonie i w CI jest w toku;
nie zaliczamy go przed końcowym raportem i JUnit.

## Zakres i potwierdzone kontrole

- Format/analyze/docs PASS. Goldeny, PL/EN,320/412dp, tekst200%, reset i odzyskiwanie zapisu.
- Game na krótkich ekranach mieści wszystkie trzy figury bez scrolla przy zwykłym tekście. Test wszystkich14 masek ×3 sloty ×2 rozmiary320×592/393×650 sprawdza granice każdego CandyTile; nowy golden `game_phone_compact.png`. Duży tekst zachowuje przewijanie. Poprawki dotyczą układu i skali podglądu, bez zmian GDD.
- Wspólny `runSmokeScenario` przechodzi lokalnie wszystkie fixture oraz jeden cykl19 ruchów/20 reakcji/Replay/reset. MemoryStorage, minimumDwellCycles i storageKind jawnie odróżniają ten test od natywnego QA; kilka sekund hosta nie zalicza20min.
- CI Flutter38718430226 SUCCESS. Profile APK i profile androidTest zbudowane na JDK21; SDK Flutter3.47.2/Dart3.13.2.
- Finalny podpisany produkcyjny APK przeszedł API24/36 i API35/16KB. Universal APK z finalnego AAB przeszedł API36. Dokładne hashe, runy oraz ograniczenia środowiska: [raport wydania](RELEASE_REPORT.md).

## Natywny scenariusz i dowody

Home PL → Settings EN/mute/haptyka/reduced motion → Game; nielegalny drag/tap;
clear9→10 i Sugar Rush; Eraser cancel/confirm; identyczny snapshot po odtworzeniu
sesji; Game Over i jednokrotna nagroda; Replay; wszystkie trzy obiekty do poziomu3,
ceny/saldo i ponowny odczyt; cztery reakcje;20 minut aktywnych ruchów/reakcji/przejść;
reset cancel/confirm i natywny odczyt świeżego profilu.

Fixture portfela/progresji są wyłącznie w testowym entrypoincie; nie potwierdzają
tempa zarabiania przez nowego gracza. Pętla dwell wykonuje prawdziwe ruchy przez
widgety UI i natywny DataStore. Stopwatch nie liczy builda, instalacji ani końcowego
resetu. Wrapper wymaga zgodnego UUID, storageKind=native-data-store, czasu≥1200s,
dodatnich liczników ruchów/reakcji/cykli, FrameTiming oraz Gradle/JUnit SUCCESS.

| Środowisko | Stan |
| --- | --- |
| Telefon2412DPC0AG, Android16/API36, arm64,4KB | IN_PROGRESS; profile Impeller/Vulkan, softwareRendering=false |
| CI API35, x86_64, Pixel2/KVM | IN_PROGRESS; jawne softwareRendering=true, run38718430099 |
| Odsłuch / odczuwalna haptyka | Wymagany wynik ręczny właściciela |
|60FPS na reprezentatywnym średnim telefonie | Niepotwierdzone; cel, nie deklaracja |
| Tempo ekonomii bez fixture | Nie wykonano długiej ręcznej oceny |

FrameTiming build/raster p95 to czas części klatki, a nie liczba FPS. Wyniku
CPU emulatora nie przedstawiamy jako wydajności GPU. Telefon jest rzeczywistym
urządzeniem właściciela; nie uznajemy go automatycznie za reprezentatywny benchmark.

## Odtworzenie i ochrona danych

```sh
CANDYVERSE_QA_DEVICE=emulator-5554 CANDYVERSE_SMOKE_MINUTES=20 scripts/android_smoke.sh
```

Wybierz jawnie urządzenie QA i sprawdź applicationId przed instalacją.
T-010 używa osobnej aplikacji com.example.candyverse, natywnych preferencji
`candyverse.qa.smoke.*`; wariant T-011 ma docelowe ID, dlatego nie uruchamiaj go
na istniejącej instalacji gracza. Wrapper nigdy nie czyści produkcyjnych danych ani
globalnego logcat. Może instalować/odinstalować swój target i androidTest.
Domyślnie AOT profile i natywny SDK FlutterTestRunner (ADR-0015). Opcja CPU jest
jawna, wyłącznie przez Intent testowej ActivityTestRule. Produkcyjny renderer bez zmian.

Artefakty: report.json, profile-build.log, instrumentation.log, JUnit,
android-lifecycle.log, API/model/page size i wersja Fluttera. Telefon: lokalny
`/home/roch/.cache/candyverse/qa-phone-final/`. Capture Flutter UI opcjonalny;
produkcyjne PNG pochodzą z osobnego smoke przez adb screencap.

## Naprawione problemy samego harnessu

- AndroidX1.2.0 zwraca null z getActivityIntent; jawny Intent i fail-fast AssertionError zapobiegają ukryciu błędu launch przez SDK.
- Nielegalny drag zachowuje zaznaczenie. Scenariusz jawnie ponownie wybiera figurę; powtórny tap tego samego slotu wcześniej ją odznaczał.
- Scenariusz czeka na widoczność/hitTestable widgetów oraz GameScreen przed odczytem kontrolera i przewija do resetu. Hostowy test obejmuje całą sekwencję przed kosztowną instrumentacją.
- Smoke produkcyjnego APK po HOME czeka na dowód rzeczywistego tła. Bez tego am start mógł trafić do Activity przed zakończeniem przejścia launchera.

Wcześniejsze nieudane próby i oczekiwanie runnera nie zaliczają aktywnego20min.
Problemy emulatorów są opisane w raporcie wydania; nie ustalono jednej przyczyny
wszystkich awarii. Zmiana testowego renderera nie zmieniła aplikacji produkcyjnej.
