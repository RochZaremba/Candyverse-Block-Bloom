# STATUS — rzeczywisty stan i przekazanie prac

**Aktualizacja:**2026-10-15. **Google Play: nieopublikowane.**
Main: `d50e612` (PR#9). T-010 i T-011 pozostają otwarte do końcowych testów.
Repozytorium: `RochZaremba/Candyverse-Block-Bloom`; fetch HTTPS, push SSH.

## Zadania

| Zadanie | Status | Potwierdzenie |
| --- | --- | --- |
| T-001 Bootstrap | DONE | PR#1, `a35c0e4` |
| T-002 Engine | DONE | PR#2, `d65c100` |
| T-003 Scoring/RNG | DONE | PR#3, `c74f03b`, `f27948e` |
| T-004 Touch UI | DONE | PR#4, `725561e`, `0af536b`, `6bfeacf` |
| T-005 Visual/VFX/SFX | DONE | PR#5, `2148fcc` |
| T-006 Upgrades | DONE | PR#6, `3b6712b` |
| T-007 Island | DONE | PR#7, merge `24ba7c3` |
| T-008 Save/economy | DONE | PR#8, merge `b4cb8b4` |
| T-009 Settings/i18n | DONE | PR#9, merge `d50e612`, CI38651090829 SUCCESS |
| T-010 QA/performance | IN_PROGRESS | PR#10, `000259d`; native20min w toku |
| T-011 Store/release | IN_PROGRESS | PR#11 draft, `6b0f2c5`; końcowe QA i materiały |

## Potwierdzone wyniki

- `flutter test`:160/160 na T-010 oraz zintegrowanym T-011; `dart test test/game`:62/62. Analyze, format, kontrola dokumentacji PASS. Narzędzia release:16/16 testów Python PASS. CI Flutter T-01038718430226 SUCCESS.
- Pełny współdzielony scenariusz hostowy zalicza wszystkie fixture i cykl ruchów/reakcji/replay/reset. MemoryStorage i krótszy czas są jawnie oznaczone; nie zaliczają native QA.
- Poprawiono Game na krótkich ekranach i skalowanie podglądu figur. Test wszystkich14 masek ×3 sloty ×2 rozmiary; goldeny i tekst200%. Brak zmiany reguł gry.
- Finalne podpisane APK/AAB1.0.0+1 zbudowano z produkcyjnego kodu `8b642bb`. Późniejsze zmiany dotyczą harnessu, dokumentacji i CI. Audyt manifestu, podpisu, minimalnych permissions, wykluczeń backupu, sześciu ELF64 i ZIP16KB PASS. Bundletool validate/config/universal oraz jarsigner PASS — [raport wydania](RELEASE_REPORT.md).
- Finalny APK przeszedł produkcyjny smoke API24 oraz API35/16KB z pełnym64-polowym porównaniem planszy po tle i force-stop. CI38719106009; takżeAPI36 APK PASS. Wariant AAB zatrzymał się po HOME: am start wysłano przed przejściem launchera na pierwszy plan, a aplikacja pozostała STOPPED bez crasha. Harness teraz wymaga dowodu rzeczywistego tła przed launch; ponowny wynik AAB do odczytu. Dawne udane testy innego hasha nie zastępują finalnego kandydata.
- Dwa rzeczywiste, nieedytowane screenshoty finalnego APK1080×1920 w `assets/store/screenshots/`; mają metadane CI i hashe. Listing PL/EN, autorskie feature graphics i launcher/store icon gotowe.
- [Publiczna polityka PL/EN](https://rochzaremba.github.io/Candyverse-Block-Bloom/) aktywna HTTP200; identyczna treść dostępna offline w Settings. Hosting branch `docs/privacy-site`, commit `efe5f2a`.

## Trwające testy i ograniczenia

- Telefon właściciela model2412DPC0AG, Android16/API36, arm64,4096B: natywny20min profile na domyślnym Impeller/Vulkan. Osobna aplikacja `com.example.candyverse`, namespace zapisu QA; nie czyścimy danych `com.renvo.candyverse`. Wynik PENDING. Logi lokalnie `/home/roch/.cache/candyverse/qa-phone-final/`.
- CI T-01038718430099: natywny20min runner z jawnym software rendererem. Czas Stopwatch, token i liczniki chronią przed zaliczeniem samego oczekiwania/starego logu. Wynik PENDING. ADR-0015 opisuje ograniczenia.
- Emulator GPU ma niestabilne próby, w tym zniknięcie całego urządzenia, system_server SIGSEGV oraz jeden potwierdzony LOW_MEMORY przy RAM2GB. Nie ustalono jednej przyczyny wszystkich awarii. Obecny run porównuje domyślny renderer z jawnie oznaczonym Skia diagnostic; produkcyjny renderer pozostaje bez zmian. Diagnostyczne opt-out nie zalicza domyślnej konfiguracji.
- Odsłuch i odczuwalna haptyka nadal wymagają wyniku ręcznego testu właściciela. Nie potwierdzono60FPS na reprezentatywnym telefonie ani długiej oceny tempa ekonomii bez fixture.

## Wydanie i blokery zewnętrzne

- Identyfikator `com.renvo.candyverse`; Renvo, rochzaremba@gmail.com. Konto Play Console8799678699020536617 jest osobiste, weryfikacja w toku. Sam identyfikator nie daje dostępu do przesyłania aplikacji.
- Podpisane pliki są lokalnie `/home/roch/.cache/candyverse/artifacts/` i w **szkicu** GitHub `v1.0.0-rc.1`; to nie jest opublikowany prerelease ani wydanie Play. Publikacja GitHub po końcowych zielonych kontrolach.
- Prywatny klucz `/home/roch/.candyverse-signing/v1/` poza Git, katalog0700/pliki0600; potrzebny backup poza komputerem. Nie regenerować. Zachować certyfikat przy Play App Signing (ADR-0014).
- Google Play wymaga zakończenia weryfikacji, rzeczywistych testerów nowego konta osobistego (12 opt-in/14 kolejnych dni), deklaracji/IARC właściciela i dostępu produkcyjnego. Nie przesłano AAB ani nie zaakceptowano zobowiązań prawnych w imieniu wydawcy.

## Kontynuacja

Worktree T-010: `/home/roch/programing/Renvo/candyverse-workers/t010`, branch `test/qa-hardening`, [PR#10](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/10).
Worktree T-011: `/home/roch/programing/Renvo/candyverse-workers/t011`, branch `chore/playstore-release`, [PR#11](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/11).
Root `main` pozostaje stabilny. Nie używać starych branchy workerów jako aktualnej wersji.

**Jedno następne zadanie:** odebrać raport końcowy20min na fizycznym telefonie i wynik CI T-010, następnie scalić PR#10 wyłącznie po zielonych kontrolach.

Kontrola16KB6b0f2c5 nie przeszła dwóch prób przez utratę całego emulatora; API24/API36/APK-z-AAB PASS. Kolejna konfiguracja wyłącza GLDirectMem wyłącznie na16KB. Nie zmieniono APK ani jego renderera. Telefon nadal testuje domyślny Vulkan.
