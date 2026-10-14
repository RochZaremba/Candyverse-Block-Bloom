# STATUS — aktualizuj na końcu każdej sesji

**Data aktualizacji:** 2026-10-14
**Stan:** T-001–T-004 przetestowane lokalnie; podstawowa gra Home/Game/Game Over działa. T-005/T-006 w równoległych, oddzielnych checkoutach. Brak jeszcze wyspy i trwałego zapisu.
**Potwierdzone commity:** `cc85322` — merge T-003; `725561e`, `0af536b`, `6bfeacf` — T-004. Wcześniej merge T-002 `09ab75a` i T-001 `d44d9fd`.
**PR:** #1–#3 MERGED, [#4 — T-004](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/4). Najnowszy head i merge sprawdź przez `gh pr view 4`/`git log`; ten handoff jest częścią PR #4.
**Repo/remote:** `RochZaremba/Candyverse-Block-Bloom`; fetch HTTPS, push SSH. Root prowadzi dokumentację/PR/merge; workery mają oddzielne worktree i rozdzielone moduły.

## Task tracker

| Task | Status | PR / commit / uwagi |
| --- | --- | --- |
| T-001 Bootstrap | DONE | `a35c0e4`, PR #1; format/analyze/test/docs/APK lokalnie i CI OK; smoke Android niewykonany |
| T-002 Engine | DONE | `d65c100`; 21 testów domeny w Dart, 27 testów łącznie; PR #2; lokalny debug APK OK |
| T-003 Scoring/RNG | DONE | `c74f03b`, `f27948e`; 39/39 Dart, 45/45 Flutter; PR #3; lokalny debug APK OK |
| T-004 Touch UI | DONE | `725561e`, `0af536b`, `6bfeacf`; 60 testów Flutter, 39 Dart, golden; PR #4; lokalny APK OK |
| T-005 Visual/VFX/SFX | IN_PROGRESS | worker na `feat/candy-visuals`; warstwa feedback, wygląd, audio/ustawienia |
| T-006 Upgrades | IN_PROGRESS | worker na `feat/roguelite`; domena i realny wybór kart/eraser |
| T-007 Island | TODO | — |
| T-008 Save/economy | TODO | — |
| T-009 Settings/i18n | TODO | — |
| T-010 QA/performance | TODO | — |
| T-011 Play Store prep | TODO | — |

Dopuszczalne statusy: `TODO`, `IN_PROGRESS`, `BLOCKED`, `DONE` (po kryteriach akceptacji, nie po napisaniu kodu bez testów).

## Aktualna sesja / handoff

- **Zrobione T-004:** realny Play na Home, dominująca plansza 8×8 z kaflami jelly, 3 sloty, ghost/collision feedback, legalny i nielegalny drag, tap-select/tap-place, semantyka kształtów, wynik/pending coins, game-over, retry z nowym seedem i potwierdzenie wyjścia. Usunięto błędy SafeArea, cancel oraz dwóch palców (drugi drag/tap nie może umieścić innej figury).
- **Testy:** format bez zmian; `flutter analyze` bez uwag; `dart test test/game` 39/39; `flutter test` 60/60; golden Home320, Game320/412, ghost320 z SafeArea24 i GameOver412 obejrzane; tekst2× i320×640 ze scroll/tap sprawdzone. `flutter build apk --debug` OK lokalnie. Dokumenty/linki/tokeny walidowane.
- **Potwierdzone CI:** T-003 run `38634132911` SUCCESS, PR #3 MERGED (`cc85322`). T-004 CI musi przejść na aktualnym head przed merge; lokalne wyniki nie są deklaracją wyniku CI.
- **Równolegle:** T-005 worker owns tile/theme/Home/new feedback/audio/settings; T-006 owns domain/upgrades/GameScreen/Controller. Root integruje hooki FX/audio po testach obu, bez równoległego nadpisywania plików. Użytkownik jawnie upoważnił kolejne etapy i parallel workers.
- **Decyzje:** brak nowej decyzji architektonicznej T-004; realizacja Flutter/ChangeNotifier i pure Dart z istniejących ADR. ADR-0008 opisuje RNG/scoring z T-003.
- **Emulator:** Android36 AOSP ATD x86_64, AVD `candyverse_api36`, uruchomienie programowe bez `/dev/kvm`. Po przerwaniu sesji proces zniknął; ponownie uruchomiony i adb widzi urządzenie, ale usługa package jeszcze niedostępna w trakcie boot. Pierwsza próba instalacji APK zwróciła `Can't find service: package`; smoke nadal niewykonany, brak pomiaru FPS.
- **Niedokończone:** T-005/T-006, wyspa, ekonomia/save, ustawienia/i18n, QA i release. Wydanie wymaga applicationId, danych wydawcy/URL polityki i klucza release; nie blokują T-004.
- **Następne jedno zadanie:** **T-005 — spójna oprawa, VFX i SFX**, równolegle z T-006 po przetestowanym T-004; nie scalać zależnych etapów przed pozytywnymi kontrolami bazowych PR.
