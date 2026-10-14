# Candyverse: Block & Bloom — pakiet startowy dla Codexa

> **Status: bootstrap i silnik z punktacją/RNG (T-001–T-003), nie gotowa gra.** Flutter stable 3.47.2, Android API 36, podstawowy Home. Silnik Dart ma 14 figur, placement, clear, punktację/combo oraz seedowany, uczciwy refill z kolorowymi skinami. Interfejs rozgrywki, wyspa i zapis są w kolejnych etapach. Aktualizacja: 2026-10-14.

Kolorowa gra mobilna 2D na Androida: **block puzzle 8×8 + lekkie ulepszenia roguelite + rozwijanie cukierkowej wyspy**. Pierwsze wydanie ma być dopracowane wizualnie, offline, bez reklam, zakupów, kont i backendu. Odbiorcy: głównie 10–16 lat, także starsi.

## Szybki start

Wymagane: Flutter stable **3.47.2** (Dart 3.13.2), JDK zgodny z Gradle 9.3.1 (CI: 21), Android SDK platform 36 oraz zaakceptowane lokalnie licencje SDK.

```sh
flutter pub get
flutter run
```

Podłącz telefon Android lub uruchom emulator przed `flutter run`. Projekt zawiera wyłącznie platformę Android, `minSdk 24`, `compileSdk/targetSdk 36`. `com.example.candyverse` to tymczasowy identyfikator developerski; release używa na razie podpisu debug i nie nadaje się do publikacji.

Kontrole przed PR:

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
dart test test/game
flutter test
python3 scripts/check_docs.py
flutter build apk --debug
```

Referencja Home: [`test/goldens/home_320.png`](test/goldens/home_320.png). Testy obejmują 320/412 dp i skalę tekstu 1×/2×. Fonty Roboto w `test/fonts/` (Apache 2.0, dołączona licencja) służą wyłącznie powtarzalnym testom wizualnym. Kontrole GitHub Actions używają tej samej wersji Fluttera.

Czytaj [AGENTS.md](AGENTS.md), [docs/INDEX.md](docs/INDEX.md) i [docs/STATUS.md](docs/STATUS.md) przed wznowieniem prac. Następny etap: **T-004 — interfejs gry i sterowanie dotykiem**.

## Dokumenty źródłowe (nie zastępuj ich jednym wielkim promptem)

| Dokument | Odpowiada na pytanie |
| --- | --- |
| [AGENTS.md](AGENTS.md) | Jak agent ma pracować, commitować i wznawiać kontekst? |
| [docs/INDEX.md](docs/INDEX.md) | Gdzie szukać źródła prawdy? |
| [docs/PRD.md](docs/PRD.md) | Co jest w V1, a czego nie wolno dorabiać? |
| [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) | Jak dokładnie działa gra, progresja i ekonomia? |
| [docs/VISUAL_DIRECTION.md](docs/VISUAL_DIRECTION.md) | Jak ma wyglądać i animować się cukierkowy świat? |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Jak zorganizować kod i zapis stanu? |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Jakie zadania wykonywać, w jakiej kolejności? |
| [docs/STATUS.md](docs/STATUS.md) | Co faktycznie już zrobiono i co dalej? |
| [docs/TEST_PLAN.md](docs/TEST_PLAN.md) | Co musi przejść przed mergem i releasem? |
| [docs/RELEASE_GOOGLE_PLAY.md](docs/RELEASE_GOOGLE_PLAY.md) | Jak dojść do Play Console? |
| [docs/PRIVACY_AND_SAFETY.md](docs/PRIVACY_AND_SAFETY.md) | Jak chronić dane i użytkowników nieletnich? |
| [docs/adr/](docs/adr/) | Dlaczego podjęto kluczowe decyzje? |

## Reguła projektu

**DoD = funkcjonalna gra + wysoka jakość grafiki + prawdziwe testy + uczciwa dokumentacja.** Placeholder udający gotową funkcję nie zalicza zadania. Bez zgody właściciela nie zmieniaj zakresu V1 ani nie dodawaj monetyzacji.

## Uwaga o materiałach

`assets/design_tokens.json` zawiera paletę i parametry animacji, **nie prawdziwe assety gry**. `templates/PRIVACY_POLICY_*.md` to **wzory do uzupełnienia po audycie kodu**, a nie oświadczenia o już sprawdzonych praktykach. Przed publikacją właściciel musi ustalić nazwę, unikalny `applicationId`, dane kontaktowe, prawa do assetów i klucz podpisujący.
