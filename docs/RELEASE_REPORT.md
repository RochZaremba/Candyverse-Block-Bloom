# Raport kandydata Android1.0.0+1

Data:2026-10-15. Stan: **publiczny prerelease, techniczne QA PASS**. Nie przesłano aplikacji do Google Play.

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

Podpisany APK/AAB są w lokalnym `/home/roch/.cache/candyverse/artifacts/`, a kopie o zgodnych digestach są załącznikami [publicznego prerelease `v1.0.0-rc.1`](https://github.com/RochZaremba/Candyverse-Block-Bloom/releases/tag/v1.0.0-rc.1). Opublikowano po zielonych kontrolach, tag `67f4ae5`, PR#11 MERGED. To nie jest wydanie w Play.

## Potwierdzone kontrole

- Flutter stable3.47.2 / Dart3.13.2, enginea804b26164; `flutter --version` i `flutter doctor -v` uruchomione. Doctor zgłasza niezaakceptowane niektóre licencje SDK i brak Chrome. Buildy Android platform36 przechodzą; nie zmieniano globalnych ustawień SDK/JDK właściciela. CI używa JDK21; lokalny Flutter korzysta z JBR25, lokalny Gradle do androidTest z JDK21.
- `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, `flutter test`160/160, `dart test test/game`62/62 i `python3 scripts/test_release_tools.py`16/16 PASS. Goldeny/layout obejmują320/412dp, tekst200% i nowy kompaktowy telefon.
- `flutter build apk --release` i `flutter build appbundle --release` PASS z zewnętrzną konfiguracją podpisu. Nie ma debug fallbacku. Sekrety pozostają poza Git i CI.
- `scripts/audit_android_artifact.py` PASS finalnego APK i universal APK wygenerowanego z finalnego AAB: SDK24/36, release bez debuggable/testOnly, brak INTERNET i nieoczekiwanych permissions, allowBackup=false i pełne wykluczenia dziewięciu domen cloud/device transfer. Jedyna własna permission: `com.renvo.candyverse.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`.
- Sześć64-bitowych bibliotek ELF arm64/x86_64: LOAD/RELRO i APK ZIP16KB alignment PASS. Certyfikat release poprawny. Wersje zależności wynikają z `pubspec.lock`; nie wymuszano arbitralnej wersji DataStore.
- Bundletool1.18.3 `validate`, `dump config` z PAGE_ALIGNMENT_16K i `build-apks --mode=universal` PASS. `jarsigner -verify` potwierdza podpis JAR; ostrzeżenia self-signed/brak timestamp i kolejność ZIP przy odczycie JarInputStream są zachowane w lokalnym logu. To nie jest potwierdzenie przyjęcia AAB przez Play.
- GeneratedPluginRegistrant po release zawiera SharedPreferencesPlugin, bez integration_test. Zależności androidTest i testowe entrypointy nie stanowią funkcji produkcyjnego buildu.
- [Publiczna polityka](https://rochzaremba.github.io/Candyverse-Block-Bloom/) HTTP200, identyczna z `public_pages/index.html`; ta sama pełna treść PL/EN jest dostępna offline w Settings. Brak scripts/forms/analytics w hostowanej stronie. Gra nie ma backendu, reklam, IAP, kont ani telemetrii.

## Kontrole uruchomienia

Finalny podpisany APK przeszedł produkcyjny smoke API24, API36 i rzeczywiste API35/16KB, a universal APK z finalnego AAB przeszedł API36. Wszystkie cztery joby [CI38721355212](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/38721355212) SUCCESS na head685f935. Każdy raport potwierdza hash, input Androida, screenshoty oraz identyczną pełną64-polową planszę po tle i force-stop. Universal APK ma SHA256 `cc9523e95b6af5135776d43730c6df0068c1ea255569a840107f0342a1582771`.

Dodatkowy wariant Skia diagnostic również przeszedł, lecz nie jest podstawą zaliczenia domyślnego renderera. APK/config pozostają bez zmian. Nie przypisujemy wcześniejszych awarii wyłącznie Impellerowi.

Pełny20min scenariusz profile opisuje [QA_REPORT](QA_REPORT.md); telefon2412DPC0AG/Android16 przeszedł1202s aktywnej gry i końcowy reset, natywne JUnit PASS. Emulator CPU również przeszedł1202s aktywności:686 ruchów/740 reakcji/37 cykli, CI38718430099 SUCCESS. Emulator nie potwierdza60FPS na reprezentatywnym telefonie. Właściciel potwierdził dźwięk, haptykę i oba przełączniki na zwykłej wersji z finalnego AAB (2026-10-15).

## Materiały i czynności właściciela

- Listing PL/EN i oryginalne feature graphics1024×500: `assets/store/`; ikona512×512 RGBA/sRGB: `assets/brand/store_icon_512.png`. Dwa finalne screenshoty1080×1920 oraz ich źródło/hashe są w `assets/store/screenshots/`. PNG pochodzą z natywnego screencap, bez edycji i bez fixture progresji.
- Klucz ma trwałą prywatną lokalizację `/home/roch/.candyverse-signing/v1/`, poza wszystkimi repozytoriami; katalog0700, pliki0600. Backup poza komputerem i ciągłość certyfikatu przy Play App Signing wymagają działania właściciela — [ADR-0014](adr/0014-signing-certificate-continuity.md).
- Konto Play Console8799678699020536617 jest osobiste, weryfikacja w toku. Brak potwierdzonego dostępu narzędziowego. Po weryfikacji: utworzenie wpisu, deklaracje/IARC przez właściciela, test internal/closed i wymagany test12 opt-in/14 kolejnych dni, potem wniosek o dostęp produkcyjny. APK z GitHub nie zalicza testu Play.
- [Instrukcja wydania](RELEASE_GOOGLE_PLAY.md), [konfiguracja Android](ANDROID_RELEASE_SETUP.md), [materiały deklaracji](STORE_DECLARATIONS.md). Nie zaakceptowano warunków ani ocen prawnych za wydawcę.

## Ograniczenia środowiska QA

Wcześniejsze emulatory utraciły proces hosta lub Android system_server; jedna próba16KB/RAM2GB ma potwierdzony LOW_MEMORY. Nie ustalono jednej przyczyny wszystkich awarii. Konfiguracja udanej macierzy przypina emulator37.1.11/build15917651, używa SwiftShader bez emulacji Vulkan; dla16KB ma4GB gościa i wyłączone GLDirectMem. To konfiguracja środowiska, bez zmiany renderera aplikacji. [Archiwum Android](https://developer.android.com/studio/emulator_archive), [akceleracja i sterowniki](https://developer.android.com/studio/run/emulator-acceleration).

Próba universal APK38719106009 nie przeszła wznowienia: log am start pokazał dostarczenie Intent do wciąż aktywnej Activity, podczas gdy późniejsze dumpsys i PNG pokazały grę STOPPED i launcher na pierwszym planie, bez app exit/crash. Harness obecnie czeka na rzeczywisty foreground innej aplikacji po KEYCODE_HOME, zanim wznowi grę. Nowy test AAB38719876208 PASS. Nie zaliczamy nieudanej próby jako sukcesu.

Dwie próby16KB na head6b0f2c5 utraciły całe urządzenie (przy Game, następnie po force-stop/resume), bez potwierdzonego OOM/segfault w logu hosta. Wyłączono eksperymentalne GLDirectMem wyłącznie dla tego emulatora; APK i domyślny renderer bez zmian. Konfiguracja38721355212 PASS na wszystkich czterech wariantach. Dodatkowy job Skia usunięto po zakończeniu porównania — oba wariantyAPI36 przeszły, brak podstaw do zmiany renderera produkcyjnego.

Kontrole finalnego head16f3db4 przed merge: Flutter38722227574 SUCCESS i wszystkie4 joby zgodności38722227448 SUCCESS. Dokumenty QA wskazują również wcześniejsze pozytywne runy dokładnie tych samych niezmienionych binariów. Publiczny store-kit jest snapshotem dokumentacji z chwili pakowania; bieżący STATUS i raport w repo zawierają późniejsze potwierdzenie publikacji.

Weryfikacja po publikacji bez tokenu/cookies: pełne pobranie APK i store-kit HTTP200, rozmiary i SHA256 zgodne z manifestem; AAB HEAD HTTP200/50197815B. To rzeczywiście dostępne publiczne pliki, a nie sam szkic release.
