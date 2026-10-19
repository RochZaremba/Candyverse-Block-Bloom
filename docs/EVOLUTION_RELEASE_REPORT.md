# Roguelite Evolution — kandydat1.3.0+6

Integracja2026-10-19. [PR#17](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/17)
scalony jako `b24a039`, [PR#18](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/18)
jako `ebb9c2a`. Implementacja `a351df1`, poprawka scenariusza `d4b5832`.
Podpisane APK/AAB powstały z `d4b5832`; kod produkcyjny jest identyczny z merge.

## Zmiana

12 kart w3 ścieżkach: Explosive Candy, Rainbow Magic, Lucky Paws. Cztery
synergie, aktywne moce, podgląd/anulowanie/potwierdzenie bomby, wybór slotu
oraz koloru. Schema3 zachowuje run-only poziomy, RNG i bonusy; stare profile1/2
migrują z zachowaniem dotychczasowego runu. Zasady [ADR-0020](adr/0020-roguelite-evolution.md).
Komunikaty i nawigacja T-020 są w tym samym wydaniu.

## Potwierdzone kontrole

- Flutter **230/230**, pure Dart **88/88**, release tools **19/19**,
  format/analyze/docs/diff PASS. [Flutter CI39114081585 SUCCESS](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/39114081585).
- [Native CI39114081625 SUCCESS](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/39114081625),
  source `d4b5832`:1202s aktywnej gry,610 ruchów,760 reakcji,38 cykli;
  DataStore, moce/restore i pozostała progresja PASS, JUnit1/0/0.
  [Surowy JSON](qa/evolution-api35-profile-cpu.json), [JUnit](qa/evolution-api35-junit.xml).
- 7429 FrameTiming; build p95=10579µs, raster p95=107503µs. Emulator/API35,
  software rendering — nie benchmark GPU ani potwierdzenie60FPS telefonu.
- Obejrzano prawdziwe PNG: [moce](qa/evolution-powers-native.png),
  [podgląd wybuchu](qa/evolution-bomb-preview-native.png), [po wybuchu](qa/evolution-cleared-native.png).
  Nieedytowane obrazy z adb; scenariusz używa jawnych fixture do synergii.
- Pierwszy native run39112472156 nie przeszedł: koniec serii ruchów otwierał
  modalną kartę, a test próbował kliknąć menu. `d4b5832` kończy wybory przed
  nawigacją; pełne ponowienie PASS. Nie skracano20-minutowego wymagania.
- Build APK/AAB release, audyt APK/universal (SDK24/36, brak INTERNET,
  backup exclusions,6 ELF64 i ZIP16KB), podpisy i bundletool validate/config
  PAGE_ALIGNMENT_16K PASS. Początkowy build trafił na stary generowany
  registrant integration_test; clean/pub get i normalny build odtworzyły go,
  bez zmiany źródeł. Release nie zawiera entrypointu instrumentacji.

[Podpisana macierz39229177997 SUCCESS](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/39229177997),
source `c463647`: **4/4 PASS**. Domyślny renderer, rzeczywisty input, tło/powrót,
force-stop i identyczne64 pola po restore we wszystkich wariantach:

- [APK API24](qa/evolution-signed-api24-pages4096-apk-default.json).
- [APK API36](qa/evolution-signed-api36-pages4096-apk-default.json).
- [APK API35, rzeczywiste16KB](qa/evolution-signed-api35-pages16384-apk-default.json).
- [Universal z finalnego AAB/API36](qa/evolution-signed-api36-pages4096-aab-default.json).

Obejrzano natywne rendery produkcyjnego APK i universal po restore.
Wyniku poprzedniego1.2.0+4 nie używamy do zaliczenia tego kandydata.

## Artefakty

Publiczny prerelease [v1.3.0-rc.1](https://github.com/RochZaremba/Candyverse-Block-Bloom/releases/tag/v1.3.0-rc.1),
wersja1.3.0/code6, opublikowany2026-10-19T09:25:41Z. Tag wskazuje `ebb9c2a`.
Poprzedni1.2.0+4 pozostaje dostępny bez zmian.

[Provenance binariów](qa/evolution-build-info.json). QA ZIP SHA256
`2f1a962ef994e5cbacb91f7187336176b86cbf5058c33b65956db9d03ad8e133`.
Publiczny APK pobrano bez uwierzytelnienia i sprawdzono SHA256/81732793B.
Publiczne digesty AAB/universal/QA porównano z lokalnymi hashami.

| Plik | SHA256 |
| --- | --- |
| candyverse-1.3.0-6.apk | 2070be4a7a1a880eb97c45ed14dcf610867f12e0dc215bf3b3ec04bb6c2edfd5 |
| candyverse-1.3.0-6.aab | 23a75fec50d09a3ad0efbb535ec2c2c85a72a4370c21277610458872b13ac369 |
| candyverse-1.3.0-6-from-aab.apk | fa58e649408bea6130f8dea79d3877963ee303408ce95176cef162d4d1969555 |

Certyfikat SHA256 `2064a303250785a1ef85029a03a543dc759ab6d715f1fb2f05dccdca04e70506`,
zgodny z wcześniejszym APK. Klucz pozostaje poza repo i CI. Do draftu runner
pobrał binaria krótkotrwałymi adresami tylko do odczytu. Po publikacji usunięto
oba CANDYVERSE_CANDIDATE_*_URL secrets. Workflow ma contents:read i hashe plików.

Self-signed/timestamp ostrzeżenia jarsignera dotyczą lokalnego certyfikatu;
nie są akceptacją AAB przez Google Play. Schema3 nie wspiera downgrade'u do
starej aplikacji. Balans wymaga dalszego playtestu, niezależnie od testów reguł.
Nie wykonywano ponownego testu telefonu zgodnie z decyzją właściciela.
Google Play pozostaje nieopublikowane. Nie zmieniano wcześniejszych wydań.

Lokalne pliki: `/home/roch/.cache/candyverse/artifacts/evolution-1.3.0-6/`.
Review agenta integrującego: brak wykrytych usterek blokujących po poprawce
scenariusza; to nie jest niezależna aprobata innego konta GitHub.
