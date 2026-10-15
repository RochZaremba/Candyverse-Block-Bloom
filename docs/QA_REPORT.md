# T-010 — raport QA

**2026-10-15: testy lokalne PASS; pełny20min native smoke oczekuje na wynik CI.**
Nie oznaczamy testu stabilności jako zakończonego przed odczytem raportu.

## Wyniki potwierdzone

- `flutter test`:158/158, w tym goldeny, PL/EN,320/412dp, tekst200%, reset i odzyskiwanie zapisu.
- `dart test test/game`:62/62; `flutter analyze`, format i kontrola dokumentacji PASS.
- JDK21 `assembleProfile assembleProfileAndroidTest`: PASS na branchach T-010 i T-011; testAPK zawiera natywny FlutterTestRunner.
- Poprawiono układ Game na krótkich telefonach: plansza dopasowuje rozmiar, panele są bardziej zwarte, wszystkie trzy figury mieszczą się bez scrolla przy zwykłym tekście. Testy393×650 i320×592 sprawdzają pełne granice figur oraz wykonują placement. Zwiększony tekst zachowuje przewijanie. Referencja: `test/goldens/game_phone_compact.png`.
- Podpisany produkcyjny APK z PR#11 przeszedł niezależny smoke API24, API36 i API35/16KB: [CI38703558729](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/38703558729). Prawdziwe input/PNG, tło/powrót, force-stop/wznowienie stanu. To wcześniejszy kandydat przed poprawką układu; finalny build musi powtórzyć te testy.

## Odtworzenie pełnego scenariusza

```sh
CANDYVERSE_QA_DEVICE=emulator-5554 CANDYVERSE_SMOKE_MINUTES=20 scripts/android_smoke.sh
```

Wybierz wyłącznie jednorazowy emulator QA. Domyślnie AOT profile i natywna instrumentacja Androida (ADR-0015), bez hostowego FlutterDriver. Skrypt wymaga jednego jawnie wybranego urządzenia; preferencje mają prefiks `candyverse.qa.smoke.*`. Nie czyści profilu gracza ani globalnego logcat. Instalacja testAPK zastępuje aplikację na urządzeniu QA.

Scenariusz: Home PL → Settings EN/mute/haptyka/reduced motion → Game; nielegalny drag/tap; clear9→10 i Sugar Rush; Eraser cancel/confirm; identyczny snapshot po odtworzeniu sesji; Game Over i jednokrotna nagroda; Replay; wszystkie trzy obiekty do poziomu3, ceny/saldo i ponowny odczyt; cztery reakcje;20 minut aktywnych ruchów/reakcji/przejść; reset cancel/confirm i natywny odczyt świeżego profilu.

Progi i saldo w części testu są jawnymi fixture wyłącznie w `integration_test/`; nie dowodzą tempa zarabiania przez nowego gracza. W pętli dwell ruchy są wykonywane przez UI. Stopwatch mierzy aktywny czas, bez builda/instalacji i końcowego resetu. Raport jest skorelowany unikalnym tokenem; wrapper wymaga ≥1200 sekund, dodatnich liczników aktywności i FrameTiming oraz powodzenia Gradle/JUnit.

Artefakty `build/qa-smoke`: report.json, profilowy build, instrumentacja/JUnit, lifecycle logcat, API/model/page size i wersja Fluttera. Capture Flutter UI jest opcjonalny; domyślnie bez GPU readback. Natywne screenshoty produkcyjnego entrypointu pochodzą z osobnego smoke T-011.

## Matryca i ograniczenia

| Kontrola | Wynik |
| --- | --- |
| Unit/widget/golden/layout/format/analyze | PASS lokalnie; finalne CI do odczytu |
| API24/36/16KB, produkcyjny entrypoint i lifecycle | PASS wcześniejszego kandydata, CI wyżej; finalny build do powtórzenia |
| Pełny native20min, ulepszenia/ekonomia/reset | PENDING CI nowego runnera |
| FrameTiming AOT | PENDING raport; emulator nie dowodzi FPS telefonu |
| Odsłuch / haptyka | NOT RUN na fizycznym telefonie |
|60FPS / startup reprezentatywnego telefonu | NOT RUN; cel, nie potwierdzony wynik |
| Tempo ekonomii bez fixture | NOT RUN jako długi ręczny playthrough |
| Podpisany finalny APK/AAB / bundletool | Raport wydania T-011 po przebudowie układu |

CI korzysta z KVM, API35 google_apis x86_64, Pixel2, SwiftShader GLES, wyłączonej emulacji Vulkan/GLDirectMem i włączonych animacji. Domyślny renderer produkcyjny pozostaje bez zmian. Poprzednie próby FlutterDriver traciły połączenie; jeden kernel log potwierdził segfault hostowego RenderThread, lecz nie ustalono jednej przyczyny wszystkich awarii. Żadna z nieudanych prób nie zalicza20 minut. Zastąpiono hostowe RPC natywnym runnerem SDK, bez obniżania czasu lub trybu profile.

Aktualizacja runnera: natywny run38708821882 także utracił emulator przed pełną rozgrywką. CI wybiera jawnie software rendering przez testowy Intent, bez hostowego VMService i bez zmiany konfiguracji release. Raport softwareRendering=true dotyczy CPU; GPU potwierdza osobny smoke produkcyjnego APK. Wynik20min nadal PENDING.

Dodatkowy przegląd PNG wykrył ucięcie4-polowej pionowej figury wewnątrz kompaktowego tray. FittedBox skaluje wyłącznie podgląd figury, bez zmiany jej maski lub reguł placement. Test wszystkich14 masek w trzech slotach przy320×592 i393×650 potwierdza granice każdego renderowanego CandyTile;158 Flutter tests, analyze i format PASS. Finalny podpisany build wymaga przebudowy i powtórzenia smoke.
