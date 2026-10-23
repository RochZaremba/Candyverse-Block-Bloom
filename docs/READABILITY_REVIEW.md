# Czytelna gra — 1.3.1+7

T-022, źródła kodu `5a5392b` (UI/testy `e0659d3`). Wersja robocza na
`fix/readable-game`, przygotowana 2026-10-23. Podpisany release nieopublikowany.

Plansza i trzy sloty są widoczne bez przewijania. Pasek wyniku/monet zastępuje
baner i duży panel. Informacje o kartach, mocach i ustawieniach otwierają się
pod ikoną. Brak miejsca otwiera konkretne opcje ratunku lub zakończenia;
niedostępna moc wyjaśnia powód. Nowa karta co30 zaakceptowanych ułożeń, bez
progów linii. Licznik, RNG, zdobyte karty i monety zachowują się przy resume.
Kontrakt i migracja: [ADR-0021](adr/0021-readable-game-and-upgrade-cadence.md).

## Rzeczywiste obrazy z testów Fluttera

- [Plansza360](../test/goldens/reference_game_360.png).
- [PL320×592/tekst200%](../test/goldens/evolution_powers_pl_320.png),
  [EN](../test/goldens/evolution_powers_en_320.png).
- [Okno pomocy PL200%](../test/goldens/game_help_pl_320.png),
  [EN](../test/goldens/game_help_en_320.png).
- [Brak miejsca i ratunek](../test/goldens/game_no_space_412.png).
- [Ghost nad palcem](../test/goldens/game_ghost_320.png).

Obrazy obejrzano po aktualizacji; znaczek gotowej tęczy używa teraz ikony
zamiast nieobsługiwanego glifu. Okno braku miejsca pokazuje przyczynę i akcje,
bez sprzecznej instrukcji układania. Plansza nie przewija się, opisy w oknie
mogą się przewijać przy dużym tekście.

## Wykonane kontrole

- Flutter3.47.2/Dart3.13.2, zależności z wymuszonym lockfile.
- `flutter test --no-pub --concurrency=2`: **236/236 PASS**, ostatni pełny
  przebieg **bez** aktualizacji goldenów po finalnej zmianie UI.
- `dart test test/game`: **93/93 PASS**, w tym progi30/60/90, brak progów za
  linie, wznowienie29→30 z identycznym RNG, legacy i zachowanie starych kolejek.
- `flutter analyze`:0 problemów; format/docs/diff PASS; Python release tools19/19.
- Host smoke: prawdziwe akcje UI z MemoryStorage,19 ruchów/20 reakcji/1 cykl,
  checkpoint/restore, moce, income, poziom30, prestiż i reset PASS. To nie Android
  DataStore,20min native QA ani pomiar wydajności GPU.
- Build APK podglądowego ARM64 PASS; audyt pakietu/SDK24/36/uprawnień/backup,
  4 biblioteki ELF64, ZIP16KB i podpis debug PASS. To test statyczny, nie
  uruchomienie na urządzeniu16KB.

## APK podglądowe

`build/artifacts/candyverse-1.3.1-7-preview-arm64.apk`,130258689 bajtów.
SHA256: `e3b4af6a949ae571adea4f229ebc3c6db91cd0768ee6ae5e484e282e16c80f59`.
Pakiet `com.renvo.candyverse.preview`, versionName1.3.1/versionCode7,
nazwa **Candyverse Preview**, ARM64, debug. Instaluje się obok produkcyjnej gry
z osobnym zapisem; nie zastępuje podpisanej instalacji ani jej danych.
Nie jest artefaktem do Play ani podpisanym aktualizacyjnym APK.
[Komenda i audyt](ANDROID_RELEASE_SETUP.md#apk-podglądowe-bez-zmiany-obecnej-instalacji).

## Pozostało do podpisanego wydania

Dostęp do Fluttera i API GitHub działa po zmianie sieci. Nie ma jednak
CANDYVERSE_KEY_PROPERTIES ani dotychczasowego klucza w tym środowisku.
Nie generowano zamiennika produkcyjnego. Publikacja podpisanego APK/AAB
wymaga istniejącego certyfikatu, audytu i QA podpisanych artefaktów.
Brak urządzenia/emulatora lokalnie; wcześniejsza decyzja właściciela o pominięciu
ponownego telefonu pozostaje w mocy. Przesyłanie assetu do GitHub zwróciło HTTP401 mimo działającego API; pusty
szkic release pozostaje nieopublikowany. APK jest lokalnie i w linku w czacie.
Bieżący stan PR/CI/release: [STATUS](STATUS.md).
