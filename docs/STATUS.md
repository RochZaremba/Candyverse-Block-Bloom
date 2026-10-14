# STATUS — aktualizuj na końcu każdej sesji

**Data aktualizacji:** 2026-10-14
**Stan:** T-001–T-005 przetestowane lokalnie. Oprawa, lokalne SFX, FX i ustawienia feedbacku działają; T-006 gotowe na osobnym branchu do integracji. Brak wyspy/zapisu/i18n.
**Potwierdzone commity:** T-005 `96cf704`, `c00a742`, `e2ddf36`, `1d657bc`, `2148fcc`; merge T-004 `fa9fec6`, merge T-003 `cc85322`.
**PR:** #1–#4 MERGED; PR T-005 przygotowywany. Najnowszy head/merge odczytaj przez `gh pr view`/`git log`.
**Repo/remote:** `RochZaremba/Candyverse-Block-Bloom`, fetch HTTPS/push SSH. Root prowadzi integrację, dokumentację i PR-y; zmiany workerów są zachowane w commitach.

## Task tracker

| Task | Status | PR / commit / uwagi |
| --- | --- | --- |
| T-001 Bootstrap | DONE | `a35c0e4`, PR #1; format/analyze/test/docs/APK lokalnie i CI OK; smoke Android niewykonany |
| T-002 Engine | DONE | `d65c100`; 21 testów domeny w Dart, 27 testów łącznie; PR #2; lokalny debug APK OK |
| T-003 Scoring/RNG | DONE | `c74f03b`, `f27948e`; 39/39 Dart, 45/45 Flutter; PR #3; lokalny debug APK OK |
| T-004 Touch UI | DONE | `725561e`, `0af536b`, `6bfeacf`; 60 testów Flutter, 39 Dart, golden; PR #4; lokalny APK OK |
| T-005 Visual/VFX/SFX | DONE | `96cf704`, `c00a742`, `e2ddf36`, `1d657bc`, `2148fcc`; 66 Flutter/39 Dart, native APK OK; PR przygotowywany |
| T-006 Upgrades | IN_PROGRESS | worker na `feat/roguelite`; domena i realny wybór kart/eraser |
| T-007 Island | TODO | — |
| T-008 Save/economy | TODO | — |
| T-009 Settings/i18n | TODO | — |
| T-010 QA/performance | TODO | — |
| T-011 Play Store prep | TODO | — |

Dopuszczalne statusy: `TODO`, `IN_PROGRESS`, `BLOCKED`, `DONE` (po kryteriach akceptacji, nie po napisaniu kodu bez testów).

## Aktualna sesja / handoff

- **Zrobione T-005:** centralne tokeny promieni/czasów/limitu cząsteczek; spójny Home/kafelki; oryginalne krótkie WAV i offline SoundPool; mute/haptyka/reduced-motion; feedback zaakceptowanego placement/clear; board-local FX bez blokowania dotyku; kontrolki w Home i podczas gry; lifecycle stop/dispose. Licencje w `assets/ASSET_LICENSES.md`, ADR-0009 zaakceptowany.
- **Testy:** `flutter test` 66/66 (pełny przebieg po hookach: `/home/roch/.cache/candyverse/t005-full.log`); `dart test test/game` 39/39; format/analyze/docs OK. Nowy test integracji sprawdza clear/place/no feedback dla reject, brak blokowania podczas FX i faktyczne live mute/haptics. Game/Home/ghost/GameOver goldens odświeżone i obejrzane. Testy viewportu/skali i session settings przechodzą.
- **APK:** finalny `flutter build apk --debug` OK; native public FlutterLoader lookup oraz WAV ZIP compression=0 potwierdzone. Zainstalowany APK pre-integration T-005 i uruchomiony `com.example.candyverse/.MainActivity` na API36; activity resumed potwierdzone. Pierwszy screenshot był czarny, więc pełny manualny smoke nie jest jeszcze potwierdzony. Emulator bez audio/akceleracji nie zastępuje odsłuchu/haptyki na telefonie ani profilingu FPS.
- **Potwierdzone CI:** PR #4 run `38635291570` SUCCESS, merge `fa9fec6`. CI T-005 uruchomimy na aktualnym PR head; merge dopiero po SUCCESS.
- **T-006:** domena i UI gotowe w `/tmp/candyverse-t006`, branch `feat/roguelite`, commity `c3cd0e2`, `7e4cf6c`, `eec3e6c`; Dart54/54 i UI9/9 OK. Pełny przebieg przed integracją wymaga 3 aktualizacji Game golden. Root łączy hooki T-005 i tokeny reduced-motion/czasów. Nie oznaczaj DONE bez zintegrowanych testów.
- **T-007:** utworzony czysty worktree `/home/roch/programing/Renvo/candyverse-workers/t007`/`feat/island`; worker NIE rozpoczął kodowania — zgłoszony brak kredytów workspace. Root może kontynuować sam; nie twierdzimy, że scena istnieje.
- **Środowisko:** AVD `candyverse_api36` AOSP ATD, programowo bez `/dev/kvm`, proces odłączony. Zabrakło quota `/tmp` przy równoległych buildach: APK zachowane w `/home/roch/.cache/candyverse/artifacts`, `flutter clean` T-003/T-004 zwolnił3.8GB; worker odtworzył ucięty plik i ponowił testy. Dalsze checkouty/temporaria pod fizycznym `/home`, nie tmpfs.
- **Niedokończone:** integracja T-006, T-007 wyspa, T-008 ekonomia/save, T-009 localization/settings, QA/release. Publikacja wymaga docelowego ID, danych wydawcy/URL polityki i klucza podpisującego.
- **Następne jedno zadanie:** **T-006 — integracja i finalne testy kart/erasera**, potem T-007 samodzielnie, jeśli kredyty workerów nadal niedostępne.
