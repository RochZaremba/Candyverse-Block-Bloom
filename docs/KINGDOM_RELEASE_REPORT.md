# Candy Kingdom — kandydat1.1.0+3

Data:2026-10-15. **Google Play: nieopublikowane.** Źródło zakresu:
[Candy Kingdom](KINGDOM_EXPANSION.md) i ADR-0016/0017. Poprzedni niepublikowany
[code2](KINGDOM_CODE2_REPORT.md) odrzucono po ręcznym wykryciu flash checkpointu.
Historyczny publiczny1.0.0-rc.1 pozostaje bez zmian.

## Zamrożone binaria

Źródło61c34a44de1bfebc0d9c31aa6243a2c049f10018; head PR#14 to231258a.
ApplicationId `com.renvo.candyverse`, Renvo / rochzaremba@gmail.com,
Flutter3.47.2/Dart3.13.2, Android min/target/compile24/36/36, versionCode3.

| Plik | Bajty | SHA256 |
| --- | --- | --- |
| candyverse-1.1.0-3.apk |63001694 | `3af487f4105810001d293af7e460ee41d51eda003376f10576d1d7799909be75` |
| candyverse-1.1.0-3.aab |61933456 | `fcb152da8df7fe66939ce8c93c038289fcc75a5c6057197af10453b9becf3262` |
| candyverse-1.1.0-3-from-aab.apk |63050867 | `32e552b82cf81425eeb1e5369d218f1833e6f619a2ab848f990a3f53ea2c453c` |

Certyfikat SHA256 pozostaje
`2064a303250785a1ef85029a03a543dc759ab6d715f1fb2f05dccdca04e70506`.
Klucz zewnętrzny nie był regenerowany; hasła nie trafiły do repo ani argumentów.
Pliki lokalne: `/home/roch/.cache/candyverse/artifacts/kingdom-1.1.0-3/`.
Kandydat `v1.1.0-rc.2` ma te same hashe. Nie publikować zastąpionego code2.

## Naprawa i potwierdzone testy

GameController nadal serializuje ruch i blokuje kolejną mutację do ACK.
Przyczyną flash była95% biała warstwa prezentacji zapisu, nie reguły silnika.
Zwykły zapis ma teraz przezroczystą barierę wejścia/semantyki; błąd i retry
pozostają widoczne. Regresja RED przed30fa7b0, GREEN po: wszystkie piksele
ekranu przy16ms/100ms opóźnionego zapisu odpowiadają obrazowi po ACK;
próba drugiego dotyku nie zmienia stanu. Animacje lokalne pozostają.

- Pełne194/194 Flutter PASS, analyze PASS, format65 plików bez zmian;
 19/19 Python release tools i linki/docs PASS.
- Podpisane APK/AAB release PASS. APK i universal: SDK, manifest, brak INTERNET,
  uprawnienia, backup exclusions, sześć ELF64 oraz ZIP16KB PASS.
- aapt2 potwierdza1.1.0/code3; apksigner certyfikat zgodny z poprzednim wydaniem.
  Bundletool1.18.3 validate/config PAGE_ALIGNMENT_16K/build-apks i jarsigner PASS.
- Właściciel jawnie polecił **pominąć ponowny test telefonu**. Code3 nie został
  zainstalowany na telefonie (odłączony); nie przypisujemy mu ręcznego PASS.
  Baseline renderowanej oprawy/telefonu code2 jest opisany oddzielnie.

## CI nowego źródła

- [Flutter38734971516 SUCCESS](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/38734971516):194Flutter/71Dart/19Python/analyze/debugAPK.
- Signed Android compatibility38734971548: API36/APK, API35/16KB/APK
  i API36/universal PASS w pierwszej próbie. API24 w pierwszej próbie wymagało ponowienia: UI
  zasłoniło systemowe okno „Messenger has stopped”, a Candyverse Home był
  wyrenderowany pod nim. [Zachowany zrzut awarii infrastruktury](qa/kingdom-code3-api24-attempt1-failure.png).
  XML/logi są lokalnie w qa-code3-signed-attempt1/api24. Nie zaliczono tej próby;
  powtórzono wyłącznie nieudany job na świeżym emulatorze, bez zmian APK.
  **Finalnie wszystkie4PASS**,
  [CI38734971548](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/38734971548).
  Pełne64pola identyczne po tle i force-stop, rzeczywisty input i PNG.
  [API24](qa/kingdom-code3-signed-api24-pages4096-apk-default.json),
  [API35/16KB](qa/kingdom-code3-signed-api35-pages16384-apk-default.json),
  [API36/APK](qa/kingdom-code3-signed-api36-pages4096-apk-default.json),
  [API36/z AAB](qa/kingdom-code3-signed-api36-pages4096-aab-default.json).
- [Android smoke38734971558 SUCCESS](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/38734971558):1202s aktywnej gry,691 ruchów,740 reakcji,37 cykli,
  Android DataStore i flagi dochód/poziom30/prestiż PASS. JUnit1/0/0.
  [Surowy raport](qa/kingdom-code3-ci-api35-profile-cpu.json).7292 FrameTiming:
  build p95=5693µs, raster p95=52847µs. To renderer CPU, nie wydajność GPU
  ani potwierdzenie60FPS; fizyczny retest code3 pominięty na polecenie właściciela.

## Materiały i ograniczenia

Lokalne assety/prompty: [provenance](../assets/kingdom/README.md),
nowy [banner1024×500](../assets/store/kingdom_feature_graphic.png)
i [prompt](../assets/store/KINGDOM_FEATURE_PROVENANCE.md), ikona512px i listing
PL/EN. Nowe nieedytowane screenshoty Home/Game EN1080×1920 pochodzą z powyższego
podpisanego code3: [provenance](../assets/store/screenshots/en/provenance.json).

Zegar offline nie zapewnia antycheatu. Pełna rozbudowa bez fixture nie została
ręcznie rozegrana; brak presji/codziennych terminów pozostaje kontraktem.
Konto osobiste Play w weryfikacji; brak uploadu AAB i prawnych deklaracji
za wydawcę. Backup klucza poza komputerem i ciągłość certyfikatu: ADR-0014.
