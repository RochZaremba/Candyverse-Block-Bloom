# T-010 — raport QA

**Stan: NOT RUN.** Ten plik opisuje przygotowany scenariusz; nie potwierdza
przejścia smoke, podpisanego AAB, 20 minut stabilnej gry ani 60 FPS.

## Automatyczny smoke na Androidzie

Dev dependency `integration_test` pochodzi z Flutter SDK. Uruchom na jawnie
wybranym emulatorze / urządzeniu QA:

```sh
CANDYVERSE_QA_DEVICE=emulator-5554 scripts/android_smoke.sh
CANDYVERSE_QA_DEVICE=emulator-5554 CANDYVERSE_SMOKE_MINUTES=20 scripts/android_smoke.sh
```

Domyślnie build PROFILE; do diagnostyki można ustawić `CANDYVERSE_QA_MODE=debug`.
APK testowego entrypointu zastępuje aplikację na tym urządzeniu; produkcyjny
entrypoint należy potem ponownie zainstalować. Preferencje testu używają
odrębnego prefiksu `candyverse.qa.smoke.*` przez prawdziwy natywny
`PreferencesStorage`. Skrypt nie czyści produkcyjnego profilu ani globalnego
logcat. Fixture i seed występują wyłącznie w `integration_test/`, nie w `lib/`.

Scenariusz używa rzeczywistych widgetów, zapisów natywnych i aktualnych reguł:
Home PL → Settings EN/mute/haptyka/reduced motion → Game; nielegalny drag i tap;
clear 9→10 linii i Sugar Rush; Eraser cancel/confirm; odczyt identycznego
snapshotu po ponownym zbudowaniu aplikacji; Game Over i nagroda jednokrotna;
Replay z nowym ID; rzeczywiste zakupy wszystkich trzech obiektów do poziomu3
z weryfikacją ceny/salda i ponownym odczytem; cztery reakcje postaci;
reset cancel/confirm i odczyt nowego profilu.

Początkowe stany milestone/no-move są jawnie kontrolowanymi fixture, w tym
linie potrzebne do nagrody i rozbudowy. Wynik **nie dowodzi czasu zdobycia monet
przez nowego gracza** ani naturalnego dojścia do tych ekranów. Osobny manualny
playthrough powinien sprawdzić tempo ekonomii bez fixture.

W wariancie 20-minutowym Stopwatch mierzy rzeczywisty czas aktywnej pętli:
reakcje wyspy, powrót do gry, legalne ruchy przez UI, wybory ulepszeń i Replay.
Czas instalacji/startu nie jest częścią deklarowanych20min. Test nie używa
`pumpAndSettle` przy niekończącej się animacji wyspy; czeka na konkretne warunki
z ograniczeniem czasu.

Artefakty trafiają do `build/qa-smoke` lub `CANDYVERSE_QA_OUTPUT`: PNG sześciu
ekranów i resetu, `report.json` bez treści preferencji, log polecenia, wersja
Flutter/API/model/page size i ograniczony log błędów. Capture odpowiadają
aplikacji z fixture; nie zastępują screenshotów finalnego release build.

## Matryca i ograniczenia

| Kontrola | Stan / wymagany dowód |
| --- | --- |
| Format/analyze/unit/widget/golden | NOT RUN w T-010; odczytaj finalny CI |
| Sześć ekranów PL/EN / nawigacja | NOT RUN; screenshoty i wynik harnessu |
| Native preferences i idempotentność | NOT RUN; wynik harnessu |
| Android force-stop/relaunch | NOT RUN; oddzielny smoke produkcyjnego APK, porównanie stanu bez wypisywania JSON |
| Rzeczywiste tło / powrót | NOT RUN; adb/Home i powrót na produkcyjnym APK |
| 20 minut aktywnej pętli | NOT RUN; report activeDwellSeconds ≥1200 |
| 320dp / 412dp / tekst2× | NOT RUN finalnego UI; widget/golden i manualne potwierdzenie |
| Odsłuch / haptyka | NOT RUN; urządzenie z audio i wibracjami |
| 60 FPS / startup średni telefon | NOT RUN; reprezentatywny telefon i profiler |
| APK/AAB, finalny manifest/16KB | NOT RUN finalnego release; raport T-011 |

FrameTiming zbiera liczbę próbek oraz build/raster p95 i liczbę klatek
przekraczających16.667ms; pomiar obejmuje UI testowanej sesji, również capture.
Nie jest deklaracją FPS. Emulator AOSP ATD bez KVM i bez audio nie reprezentuje
średniego telefonu i nie potwierdza odsłuchu/haptyki. Test lifecycle/force-stop
nie jest zastąpiony ponownym `pumpWidget`.

Po uruchomieniu uzupełnij datę, head/PR, rzeczywiste komendy, liczby, urządzenie,
problemy i poprawki; pozostaw niewykonane kontrole jako NOT RUN / BLOCKED.

## Wykryte ograniczenie runnera

Run38695515416 zakończył się utratą emulatora. Diagnostyka hosta potwierdziła
segfault `RenderThread` emulatora; dostępne14GB pamięci wyklucza wcześniejsze
podejrzenie OOM w tej próbie. Zmieniono emulator na SwiftShader GLES z wyłączoną
emulacją Vulkan (`-feature -Vulkan`), bez zmiany produkcyjnych ustawień silnika.
Dalsze wyniki dotyczą tej konfiguracji; Vulkan i60FPS na fizycznym telefonie
pozostają niepotwierdzone. Timeout screenshotu ogranicza blokadę testu.

Zrzuty tego harnessu wykonuje Flutter RepaintBoundary w rzeczywistym rendererze
urządzenia, w jego pixelRatio. To obrazy UI Fluttera, bez systemowych pasków;
pełne natywne screenshoty finalnego APK wykonuje osobny smoke `adb screencap`.
Nie konwertujemy SurfaceView na ImageView: komentarz Flutter SDK ostrzega,
że taka konwersja zmienia renderowanie całego pomiaru. PNG są wysyłane przez
reportData i zapisuje je driver również przy niepowodzeniu testu. Systemowe
reduced-motion jest raportowane oddzielnie; CI pozostawia animacje włączone.

Domyślny harness nie wykonuje GPU readback podczas testu stabilności; emulowany
RenderThread ulegał awarii również przy drugim RepaintBoundary capture. Loguje
kamienie milowe, a natywne screenshoty pochodzą ze smoke podpisanego APK.
Opcjonalne `--dart-define=CANDYVERSE_CAPTURE_FLUTTER_UI=true` zachowuje capture
Flutter UI do urządzeń, które go wspierają. Raport wskazuje metodę capture.
Czas dwell zapisujemy przed końcowym resetem, aby reset nie zwiększał pomiaru.

Po kolejnej awarii hostowego RenderThread również bez GPU capture wybieramy
stabilnościowy profil API35 (target/compile aplikacji pozostaje36), GLES i
GLDirectMem. Podpisany APK ma niezależny smoke API24/API36 i środowiska16KB.
To zmiana urządzenia QA, nie konfiguracji produkcyjnego silnika. Wyłączenie
Vulkan i GLDirectMem jest znanym obejściem emulacji, którego wynik nadal trzeba
potwierdzić: [runner issue393](https://github.com/ReactiveCircus/android-emulator-runner/issues/393).
