# Candyverse: Block & Bloom — pakiet startowy dla Codexa

> **Status: sama dokumentacja, nie gotowa aplikacja.** Projekt Flutter zostanie utworzony przez agenta w zadaniu `T-001`. Aktualizacja: 2026-10-14.

Kolorowa gra mobilna 2D na Androida: **block puzzle 8×8 + lekkie ulepszenia roguelite + rozwijanie cukierkowej wyspy**. Pierwsze wydanie ma być dopracowane wizualnie, offline, bez reklam, zakupów, kont i backendu. Odbiorcy: głównie 10–16 lat, także starsi.

## Szybki start

1. Utwórz puste repozytorium GitHub (najlepiej prywatne) i sklonuj je lokalnie / podłącz do Codexa.
2. Wypakuj **zawartość** tego ZIP-a do katalogu głównego repozytorium (tak, by `AGENTS.md` i `README.md` znalazły się obok `.git/`). Nie usuwaj istniejących plików przy ewentualnym konflikcie.
3. Przeczytaj [AGENTS.md](AGENTS.md), [docs/INDEX.md](docs/INDEX.md), [docs/STATUS.md](docs/STATUS.md).
4. Zatwierdź dokumentację jako pierwszy commit, np. `docs: initialize Candyverse project specification`.
5. Uruchom Codexa w repozytorium z promptem z [START_CODEX.md](START_CODEX.md).

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
