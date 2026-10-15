# Candy Kingdom — kandydat1.1.0+2

Data:2026-10-15. Google Play: nieopublikowane. Raport dotyczy rozszerzenia
[Candy Kingdom](KINGDOM_EXPANSION.md); historyczny [raport1.0.0](RELEASE_REPORT.md)
i pliki v1.0.0-rc.1 pozostają niezmienione.

## Tożsamość zamrożonych plików

Źródło binariów: commit6e0780f. Finalny head PR#14f060300 zawiera późniejsze
zmiany dokumentacji, listingów, grafiki sklepu, workflow i ochrony diagnostycznego drive; kod produkcyjny jest
identyczny. Flutter3.47.2/Dart3.13.2; AndroidSDK24/36, versionCode2.
ApplicationId `com.renvo.candyverse`, Renvo / rochzaremba@gmail.com.

| Plik | Bajty | SHA256 |
| --- | --- | --- |
| candyverse-1.1.0-2.apk |63001694 | `cb84b22b4422bc88f6cb5cd84a6d514e5e5f37e2200e2041df6f77a12ec1bfda` |
| candyverse-1.1.0-2.aab |61933291 | `f3ae85ca7bf187395e6c32d2c3e91d6b4b35cb365f6fe3a989e79f49753ada7a` |
| candyverse-1.1.0-from-aab.apk |63050867 | `20f3ee18aa8b3ec07c07d9aba284485f98345a2b4edb9877f251af7afeb34730` |

Certyfikat obu APK: `2064a303250785a1ef85029a03a543dc759ab6d715f1fb2f05dccdca04e70506`,
ten sam co1.0.0. Klucz zewnętrzny nie był regenerowany ani publikowany.
Lokalne kopie: `/home/roch/.cache/candyverse/artifacts/kingdom-1.1.0/`.

## Potwierdzone lokalnie

- Format/analyze PASS;193/193 Flutter,71/71 Dart silnika,19/19 Python release tools.
- Goldeny Home, rozwoju0/1/5/6/15/30 i trzech motywów, layout320/412dp,
  tekst200%, PL/EN i reduced-motion; rzeczywista grafika wczytana przed capture.
- Hostowy rozszerzony smoke PASS: pasywny dochód, poziom30, anulowanie/prestiż,
  zapis gwiazdki i zachowanie portfela/runu. To nie zastępuje Android DataStore.
- Build APK/AAB release PASS z istniejącym zewnętrznym kluczem. APK oraz APK
  wygenerowane z AAB: poprawny manifest, uprawnienia, brak INTERNET/debuggable,
  wykluczenia backupu, sześć ELF64 i ZIP16KB, apksigner PASS.
- aapt2 potwierdza1.1.0/code2. Bundletool1.18.3 validate/config16KB/build-apks
  PASS; jarsigner potwierdza podpis AAB. Ostrzeżenia self-signed/brak timestamp
  i kolejność ZIP/JarInputStream zachowano w lokalnych logach.
- Przegląd agentów ekonomii i release bez wykrytego blokera. Nowy zapis schema2
  odczytuje schema1, zachowuje wybrany język, run i saldo; dochód nie obejmuje
  czasu sprzed migracji. To lokalny zegar, bez obietnicy antycheatu.

## Weryfikacja Androida

Fizyczny20min profile na Android16/API36/arm64/4KB działa w osobnym ID
`com.renvo.candyverse.qa`; nie kasuje danych zwykłej gry. Pierwszą próbę przerwano
przed instalacją, nie zalicza się do czasu. Wynik ponownej próby oczekuje.

CI finalnego headf060300:

- [Flutter38731841063 SUCCESS](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/38731841063).
- [Signed compatibility38731841152 SUCCESS](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/38731841152): wszystkie cztery przypadki domyślnego renderera,
  rzeczywisty input oraz pełna64-polowa plansza po tle i force-stop.
  [API24/APK](qa/kingdom-signed-api24-pages4096-apk-default.json),
  [API36/APK](qa/kingdom-signed-api36-pages4096-apk-default.json),
  [API35/16KB/APK](qa/kingdom-signed-api35-pages16384-apk-default.json),
  [API36/z AAB](qa/kingdom-signed-api36-pages4096-aab-default.json).
- Android smoke38731841069 —20min aktywnej interakcji i natywny zapis na CPU.

Nie oznaczać kandydata jako zweryfikowanego na podstawie dawnych wyników1.0.0.

## Materiały i zewnętrzne czynności

Renderowane lokalne assety i prompty: [provenance](../assets/kingdom/README.md).
Nowy [feature graphic1024×500](../assets/store/kingdom_feature_graphic.png)
z [promptem](../assets/store/KINGDOM_FEATURE_PROVENANCE.md), ikona512px
i aktualny listing PL/EN. Historyczne screenshoty1.0.0 nie opisują nowego UI.

Konto Play właściciela pozostaje w weryfikacji; nie przesłano AAB do Console,
nie zaakceptowano deklaracji ani warunków za wydawcę. Backup klucza poza
komputerem i zachowanie certyfikatu przy Play App Signing: ADR-0014.
