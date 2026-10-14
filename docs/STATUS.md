# STATUS — aktualizuj na końcu każdej sesji

**Data aktualizacji:** 2026-10-15
**Stan:** T-001–T-008 scalone; T-009 zaimplementowane i sprawdzone lokalnie, PR/CI w przygotowaniu. T-010 harness i T-011 konfiguracja przygotowywane równolegle, niezaliczone bez integracji/testów.
**Potwierdzone commity:** merge T-008 `b4cb8b4`, head `5d081ff`; T-009 `c34eced`, `bef81e1`, `3263632`, `085e97a`, `60316b5`, `a2a1f26`, `2eba311`, `ccbd433`.
**PR:** #1–#8 MERGED; [#8](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/8), finalne CI `38646672217` SUCCESS. T-009 PR jeszcze nieutworzony.
**Repo/remote:** `RochZaremba/Candyverse-Block-Bloom`, fetch HTTPS/push SSH. Root integruje; workerzy mają rozdzielone moduły/worktree.

## Task tracker

| Task | Status | PR / commit / uwagi |
| --- | --- | --- |
| T-001 Bootstrap | DONE | `a35c0e4`, PR #1; format/analyze/test/docs/APK lokalnie i CI OK; smoke Android niewykonany |
| T-002 Engine | DONE | `d65c100`; 21 testów domeny w Dart, 27 testów łącznie; PR #2; lokalny debug APK OK |
| T-003 Scoring/RNG | DONE | `c74f03b`, `f27948e`; 39/39 Dart, 45/45 Flutter; PR #3; lokalny debug APK OK |
| T-004 Touch UI | DONE | `725561e`, `0af536b`, `6bfeacf`; 60 testów Flutter, 39 Dart, golden; PR #4; lokalny APK OK |
| T-005 Visual/VFX/SFX | DONE | `96cf704`, `c00a742`, `e2ddf36`, `1d657bc`, `2148fcc`; 66 Flutter/39 Dart, native APK OK; PR #5 |
| T-006 Upgrades | DONE | `c3cd0e2`, `7e4cf6c`, `eec3e6c`, `91ed2a7`, `3b6712b`; 90 Flutter/54 Dart/native APK OK; PR #6 |
| T-007 Island | DONE | `b1945e7`, `f632c57`, `daad0e1`;101 Flutter/56 Dart/native APK OK; PR #7, merge `24ba7c3` |
| T-008 Save/economy | DONE | `78c5565`, `6469890`, `ba3e6fd`, `99511f8`;125 Flutter/62 Dart/format/analyze/docs/APK OK; PR #8; CI kodu `2b9b74c` SUCCESS |
| T-009 Settings/i18n | IN_PROGRESS | `2eba311`;151 Flutter/62 Dart/analyze/APK OK; finalny review i PR/CI |
| T-010 QA/performance | IN_PROGRESS | osobny harness Android; rzeczywisty smoke jeszcze niewykonany |
| T-011 Play Store prep | IN_PROGRESS | konfiguracja/ikony/audyt osobno; brak konta Play Console i klucza |

Dopuszczalne statusy: `TODO`, `IN_PROGRESS`, `BLOCKED`, `DONE` (po kryteriach akceptacji, nie po napisaniu kodu bez testów).

## Aktualna sesja / handoff

- **T-009:** sześć ekranów z prawdziwą nawigacją, pełne Settings, PL/EN zapisane w profilu i aktualizowane na otwartych ekranach, przywracane po restarcie. Reset wymaga potwierdzenia, usuwa profil i lokalną kwarantannę, przywraca ustawienia; przerywa callbacki poprzedniej generacji sesji. Przejście z wyniku na wyspę oraz prawdziwe zakupy. Centralne tłumaczenia także dynamicznych komunikatów i semantyki, SDK flutter_localizations.
- **Naprawione błędy zapisu:** ustawienia nie nadpisują nagrody, jeśli zapis runu utrwalił się, lecz odpowiedź z magazynu zgłosiła błąd. Po retry zachowują najnowszą rewizję. Reset po utracie potwierdzenia sprawdza odczyt; niepewny stan wymaga ponowienia resetu, blokuje inne mutacje i nie udaje sukcesu (ADR-0013).
- **Weryfikacja T-009:** pełny `flutter test`151/151; `dart test test/game`62/62; `flutter analyze` bez problemów; debug APK zbudowany33.5s. Goldeny PL Settings oraz EN Home/Upgrade; flow EN Settings→Home→Game/Island, wynik→wyspa/replay;320/412dp tekst2×; reset/cancel/failure/ack/retry. Recovery EN korzysta z języka urządzenia, gdy profil jest nieczytelny; poprawny profil zachowuje zapisany PL/EN. Cztery dodatkowe testy recovery6/6 i analyze OK. Logi `/home/roch/.cache/candyverse/t009-*.log`. Native smoke zmian T-009 jeszcze nie wykonany, należy do T-010.
- **T-008:** exact resume pełnych masek/skina/RNG/kolejek/faz, idempotentna nagroda, serializowany zapis, ceny GDD.125 Flutter/62 Dart i native debug APK OK. Częściowy native smoke na API36: run1, placement Z0,0, score40 i4 pola; JSON byte-identical po force-stop/start. Wcześniejszy emulator bez KVM zgłasza fully drawn dopiero po3m12s; brak reprezentatywnego FPS/odsłuchu/haptyki.
- **Workerzy:** `t009_settings` przygotowuje T-011 w `/home/roch/programing/Renvo/candyverse-workers/t011`, `release_audit` T-010 w `.../t010`, root T-009 w `.../t009`. Przygotowane T-011 commity `0dd901c`, `733ceb9`, `cbe60bd`, `ad1cdb0` nie są jeszcze zintegrowanym wydaniem. T-010 harness `d18991c` wymaga poprawionych fixture i uruchomienia.
- **Release właściciel:** `com.renvo.candyverse`, Renvo, rochzaremba@gmail.com. Właściciel potwierdził brak konta Play Console i klucza. Publiczny URL polityki jeszcze nieutworzony. Można przygotować klucz poza repo, podpisane APK/AAB i materiały; nie można oznaczyć publikacji Google Play jako wykonanej bez konta/dostępu i obowiązkowych etapów właściciela.
- **Niedokończone:** review i PR/CI T-009, rzeczywisty20min smoke/profile T-010, finalny podpisany build/audyt, hosting polityki i materiały T-011, publikacja sklepu.
- **Następne jedno zadanie:** zamknąć PR T-009 po zielonym CI, następnie uruchomić harness T-010 na Androidzie.
