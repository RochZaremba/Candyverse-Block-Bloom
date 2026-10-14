# STATUS — aktualizuj na końcu każdej sesji

**Data inicjalizacji:** 2026-10-14
**Stan:** T-001 ukończony i przetestowany: projekt Flutter/Android oraz podstawowy Home. Brak rozgrywki — następny etap T-002.
**Potwierdzone commity:** `a35c0e4` — bootstrap, Home, testy i CI; `bc567a0` — README/handoff (baza dokumentacji: `d34394e`).
**PR:** [#1 — T-001](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/1). Stan merge i najnowszy commit sprawdź przez `gh pr view 1` / `git log`; dokumentacja jest częścią tego PR.
**Repo/remote:** `RochZaremba/Candyverse-Block-Bloom`, origin HTTPS; branch `chore/flutter-bootstrap`. GitHub CLI zalogowane, uprawnienia ADMIN; main bez branch protection.

## Task tracker

| Task | Status | PR / commit / uwagi |
| --- | --- | --- |
| T-001 Bootstrap | DONE | `a35c0e4`, PR #1; format/analyze/test/docs/APK lokalnie i CI OK; smoke Android niewykonany |
| T-002 Engine | TODO | — |
| T-003 Scoring/RNG | TODO | — |
| T-004 Touch UI | TODO | — |
| T-005 Visual/VFX/SFX | TODO | — |
| T-006 Upgrades | TODO | — |
| T-007 Island | TODO | — |
| T-008 Save/economy | TODO | — |
| T-009 Settings/i18n | TODO | — |
| T-010 QA/performance | TODO | — |
| T-011 Play Store prep | TODO | — |

Dopuszczalne statusy: `TODO`, `IN_PROGRESS`, `BLOCKED`, `DONE` (po kryteriach akceptacji, nie po napisaniu kodu bez testów).

## Aktualna sesja / handoff

- **Data:** 2026-10-14.
- **Zrobione:** `flutter create --platforms=android`, Flutter stable 3.47.2/Dart 3.13.2; compile/target SDK 36, minSdk 24; start w pionie; Home, centralne tokeny, autorska dekoracja wektorowa; CI format/analyze/test/docs/debug APK. README zawiera komendy uruchomienia.
- **Decyzje:** zgodne z istniejącymi ADR; brak nowej decyzji architektonicznej. Tymczasowy applicationId `com.example.candyverse`; podpis release wciąż debug. Roboto Apache 2.0 wyłącznie w testach, licencja dołączona.
- **Dalszy zakres:** Home nie zawiera przycisków udających grę; pełny Home, assety i pozostałe funkcje wymagają dalszych etapów. PR #1 scalany wyłącznie po zielonych kontrolach aktualnego head.
- **Testy wykonane:** `dart format --output=none --set-exit-if-changed .` OK; `flutter analyze` bez uwag; `flutter test` 6/6 OK (320/412 dp, tekst 1×/2×, golden 320 dp); `python3 scripts/check_docs.py` OK. `flutter build apk --debug` OK lokalnie; `aapt dump badging` potwierdza compile/target SDK 36, minSdk 24, nazwę aplikacji i launcher. Wszystkie kontrole CI dla `bc567a0` przeszły, run `38629526180` (format/analyze/test/docs/debug APK); kontrole końcowego commita dokumentacji sprawdź na PR. Referencja `test/goldens/home_320.png` obejrzana. Pierwszy przebieg testów przerwany z powodu ładowania assetu w fake async; poprawiono wspólny setup, kolejne pełne przebiegi zielone.
- **Środowisko:** Android SDK 36 i 36.1 dostępne. `flutter doctor -v` zgłasza część niezaakceptowanych licencji; brak Chrome nie blokuje Androida. `adb devices` nie pokazuje telefonu, brak AVD — nie wykonano smoke testu na Androidzie ani profilingu.
- **Blokery wydania:** finalny applicationId, dane publikującego/URL polityki i klucz podpisujący; nie blokują bootstrapu. Gra nie jest gotowa do publikacji.
- **GitHub:** push HTTPS odrzucony z powodu braku zakresu `workflow`; uwierzytelniony SSH zadziałał. Origin fetch HTTPS, push SSH. Nie zmieniano zakresu tokena ani zasad ochrony repo.
- **Następne jedno zadanie:** **T-002** — modele i czysty silnik planszy na `feat/puzzle-engine`, po sprawdzeniu stanu merge PR #1.
