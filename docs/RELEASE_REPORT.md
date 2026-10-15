# Raport kandydata Android1.0.0+1

Data:2026-10-15. Stan: **kandydat, końcowe QA w toku**. Nie przesłano aplikacji do Google Play.

## Tożsamość i artefakty

| Pole | Wartość |
| --- | --- |
| applicationId | `com.renvo.candyverse` |
| Wydawca / kontakt | Renvo / rochzaremba@gmail.com |
| Wersja |1.0.0+1 |
| min/target/compile SDK |24/36/36 |
| APK SHA256 | `8e4f0f670e476533f46e6f3b56f956e2700b5d8e0cd422da64cb9f14efe5e975` |
| APK rozmiar |50988653 bajtów |
| AAB SHA256 | `a07af0a46f36cfcd3cbde96a582b7ad8541140aa4045f91be203bdefe428efd3` |
| AAB rozmiar |50197815 bajtów |
| Certyfikat SHA256 | `2064a303250785a1ef85029a03a543dc759ab6d715f1fb2f05dccdca04e70506` |

Podpisany APK/AAB są w lokalnym `/home/roch/.cache/candyverse/artifacts/`, a kopie o zgodnych digestach są załącznikami szkicu GitHub `v1.0.0-rc.1`. Publikacja prerelease dopiero po zielonych kontrolach. To nie jest wydanie w Play.

## Potwierdzone kontrole

- Flutter stable3.47.2 / Dart3.13.2, enginea804b26164; `flutter --version` i `flutter doctor -v` uruchomione. Doctor zgłasza niezaakceptowane niektóre licencje SDK i brak Chrome. Buildy Android platform36 przechodzą; nie zmieniano globalnych ustawień SDK/JDK właściciela. CI używa JDK21; lokalny Flutter korzysta z JBR25, lokalny Gradle do androidTest z JDK21.
- `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, `flutter test`158/158, `dart test test/game`62/62 i `python3 scripts/test_release_tools.py`15/15 PASS. Goldeny/layout obejmują320/412dp, tekst200% i nowy kompaktowy telefon.
- `flutter build apk --release` i `flutter build appbundle --release` PASS z zewnętrzną konfiguracją podpisu. Nie ma debug fallbacku. Sekrety pozostają poza Git i CI.
- `scripts/audit_android_artifact.py` PASS finalnego APK i universal APK wygenerowanego z finalnego AAB: SDK24/36, release bez debuggable/testOnly, brak INTERNET i nieoczekiwanych permissions, allowBackup=false i pełne wykluczenia dziewięciu domen cloud/device transfer. Jedyna własna permission: `com.renvo.candyverse.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`.
- Sześć64-bitowych bibliotek ELF arm64/x86_64: LOAD/RELRO i APK ZIP16KB alignment PASS. Certyfikat release poprawny. Wersje zależności wynikają z `pubspec.lock`; nie wymuszano arbitralnej wersji DataStore.
- Bundletool1.18.3 `validate`, `dump config` z PAGE_ALIGNMENT_16K i `build-apks --mode=universal` PASS. `jarsigner -verify` potwierdza podpis JAR; ostrzeżenia self-signed/brak timestamp i kolejność ZIP przy odczycie JarInputStream są zachowane w lokalnym logu. To nie jest potwierdzenie przyjęcia AAB przez Play.
- GeneratedPluginRegistrant po release zawiera SharedPreferencesPlugin, bez integration_test. Zależności androidTest i testowe entrypointy nie stanowią funkcji produkcyjnego buildu.
- [Publiczna polityka](https://rochzaremba.github.io/Candyverse-Block-Bloom/) HTTP200, identyczna z `public_pages/index.html`; ta sama pełna treść PL/EN jest dostępna offline w Settings. Brak scripts/forms/analytics w hostowanej stronie. Gra nie ma backendu, reklam, IAP, kont ani telemetrii.

## Kontrole uruchomienia

Finalny podpisany APK musi przejść natywny smoke API24, API36 i API35/16KB, z rzeczywistymi input, screenshotami, tłem/powrotem oraz force-stop/restore. **Wynik aktualnego kandydata: PENDING CI.** Wcześniejszy APK przeszedł wszystkie trzy środowiska w CI38703558729; nie zastępuje to sprawdzenia nowego hasha po zmianie układu.

Pełny20min scenariusz profile opisuje [QA_REPORT](QA_REPORT.md); wynik aktualnego runnera CPU pozostaje PENDING. Emulator nie potwierdza60FPS na reprezentatywnym telefonie. Odsłuch i wibracje pozostają do ręcznego sprawdzenia przez właściciela, który zgłosił możliwość testu.

## Materiały i czynności właściciela

- Listing PL/EN i oryginalne feature graphics1024×500: `assets/store/`; ikona512×512 RGBA/sRGB: `assets/brand/store_icon_512.png`. Finalne screenshoty produkcyjnego APK pozostają do dołączenia po odczycie CI.
- Klucz ma trwałą prywatną lokalizację `/home/roch/.candyverse-signing/v1/`, poza wszystkimi repozytoriami; katalog0700, pliki0600. Backup poza komputerem i ciągłość certyfikatu przy Play App Signing wymagają działania właściciela — [ADR-0014](adr/0014-signing-certificate-continuity.md).
- Konto Play Console8799678699020536617 jest osobiste, weryfikacja w toku. Brak potwierdzonego dostępu narzędziowego. Po weryfikacji: utworzenie wpisu, deklaracje/IARC przez właściciela, test internal/closed i wymagany test12 opt-in/14 kolejnych dni, potem wniosek o dostęp produkcyjny. APK z GitHub nie zalicza testu Play.
- [Instrukcja wydania](RELEASE_GOOGLE_PLAY.md), [konfiguracja Android](ANDROID_RELEASE_SETUP.md), [materiały deklaracji](STORE_DECLARATIONS.md). Nie zaakceptowano warunków ani ocen prawnych za wydawcę.

Diagnostyka CI38710814859: finalny APK API24/API36 PASS, środowisko16KB z RAM2048 zakończyło aplikację z `ApplicationExitInfo reason=3 LOW_MEMORY` podczas startu. To odrębny dowód presji pamięci wewnątrz gościa, nie awarii hostowego RenderThread. Dla obrazu16KB przydzielono4096MB; skrypt zapisuje rzeczywisty MemTotal i dumpsys meminfo aplikacji. Wynik nowej próby pozostaje do odczytu.

Aktualny build po `c8b42e7` ma kompletne podglądy wszystkich14 masek,158 testów Flutter i15 testów narzędzi release PASS. Naprawiono fałszywy negatywny wynik smoke dla figuryS: origin może pozostać pusty; obecnie porównujemy pełną64-polową maskę po realnym tle i force-stop. Native16KB z RAM4GB doszło do wznowienia, po czym utraciło emulator. API35/36 smoke wybiera teraz oficjalnie wspierany backend ANGLE/SwiftShader (`swangle`), API24 zachowuje sprawdzony SwiftShader. To ustawienie hostowej emulacji, APK nadal uruchamia domyślny Impeller. Źródło trybów: [dokumentacja Android Emulator](https://developer.android.com/studio/run/emulator-acceleration). Nowe wyniki pozostają PENDING.
