# STATUS — rzeczywisty stan i przekazanie prac

**Aktualizacja:**2026-10-15. **Google Play: nieopublikowane.**
Main: `85c7a91`, merge [PR#13](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/13) — kontrakt Candy Kingdom.
Implementacja rozszerzenia jest na `feat/kingdom-integration`; szczegóły poniżej.
T-001–T-011 scalone. Publiczny prerelease GitHub gotowy. Publikacja Google Play **BLOCKED** etapami konta właściciela, nieukończona.
Repo `RochZaremba/Candyverse-Block-Bloom`; fetch HTTPS, push SSH.

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
| T-010 QA/performance | DONE | PR#10, head `000259d`, merge `41800a6`; CI i telefon20min PASS |
| T-011 Store/release | DONE | PR#11, head `16f3db4`, merge `67f4ae5`; podpisane APK/AAB i publiczny prerelease; Play nieopublikowane |
| T-012 Kingdom contract | DONE | PR#13, head4add259, merge85c7a91, CI38727224494 SUCCESS |
| T-01330 levels / passive income | IN_REVIEW | implementacja i lokalne testy w integracji; czeka native/CI/merge |
| T-014 Prestige / stars | IN_REVIEW | schema2 i potwierdzany reset; czeka native/CI/merge |
| T-015 Rendered assets | IN_REVIEW |29d96db, provenance/PROMPTS, goldeny; czeka native/CI/merge |
| T-016 Menu / English default | IN_REVIEW |2 przyciski i gear, stare języki zachowane; czeka native/CI/merge |
| T-017 Transitions / notices | IN_REVIEW | candy UI, opaque transitions i reduced-motion tests; czeka native/CI/merge |
| T-018 Celebrations / release QA | IN_PROGRESS | podpisane1.1.0+2, lokalne193 testy PASS; native i CI jeszcze niezaliczone |

## Historyczne potwierdzone testy1.0.0+1

-160/160 Flutter na T-010 i zintegrowanym T-011;62/62 Dart silnika. Format/analyze/docs PASS.16/16 Python narzędzi release. CI Flutter T-01038718430226 oraz T-01138721355323 SUCCESS.
- **Telefon2412DPC0AG, Android16/API36, arm64,4KB:** profile Impeller/Vulkan,1202s aktywnej gry,699 ruchów,744 reakcje,38 cykli.7338 próbek FrameTiming; build p95=10,893ms, raster p95=8,550ms. Gradle SUCCESS, JUnit1/0 failures/0 errors. [Raport](qa/phone-api36-profile.json).
- **CI emulator API35/CPU:** native DataStore,1202s,686 ruchów,740 reakcji,37 cykli,7232 FrameTiming samples. [CI38718430099 SUCCESS](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/38718430099), [raport](qa/ci-api35-profile-cpu.json). CPU nie potwierdza wydajności GPU.
- **Właściciel:** dźwięk, odczuwalna haptyka i oba niezależne przełączniki potwierdzone na produkcyjnym APK wygenerowanym z finalnego AAB. Zainstalowano bez czyszczenia danych. Testowa aplikacja T-010 miała osobny ID i preferencje; nie wykonywano clear/uninstall aplikacji produkcyjnej.
- **Finalny podpisany APK/AAB:** SDK24/36, certyfikat release, brak INTERNET/nieoczekiwanych permissions, wykluczenia backupu, sześć ELF64+ZIP16KB PASS. Bundletool validate/config/universal i jarsigner PASS.
- **Zgodność produkcyjna:** wszystkie cztery joby [CI38721355212](https://github.com/RochZaremba/Candyverse-Block-Bloom/actions/runs/38721355212) SUCCESS na685f935: API24/API36 APK, rzeczywiste API35/16KB APK, API36 APK z finalnego AAB. Input Androida, PNG, tło/powrót, force-stop i pełna identyczna64-polowa plansza po wznowieniu. [Raport wydania](RELEASE_REPORT.md), [QA](QA_REPORT.md), dowody JSON w `docs/qa/`.
- Poprawiono Game na krótkich ekranach i skalowanie preview wszystkich14 masek. Testy granic figur,320×592/393×650, goldeny i tekst200%. Reguły gry bez zmian.

## Wydanie i materiały

Identyfikator `com.renvo.candyverse`; Renvo, rochzaremba@gmail.com. Wersja1.0.0+1.
Produkcja zbudowana z `8b642bb`; później zmieniono tylko testy/docs/CI.
Pliki w `/home/roch/.cache/candyverse/artifacts/` oraz [publicznym prerelease `v1.0.0-rc.1`](https://github.com/RochZaremba/Candyverse-Block-Bloom/releases/tag/v1.0.0-rc.1):

- APK SHA256 `8e4f0f670e476533f46e6f3b56f956e2700b5d8e0cd422da64cb9f14efe5e975`.
- AAB SHA256 `a07af0a46f36cfcd3cbde96a582b7ad8541140aa4045f91be203bdefe428efd3`.
- APK z AAB SHA256 `cc9523e95b6af5135776d43730c6df0068c1ea255569a840107f0342a1582771`.

Listing PL/EN, oryginalne feature graphics i launcher/store icon gotowe.
Dwa nieedytowane PNG1080×1920 w `assets/store/screenshots/` z provenance/hashami.
[Polityka PL/EN](https://rochzaremba.github.io/Candyverse-Block-Bloom/) HTTP200,
byte-identyczna ze źródłem; cała treść również offline w Settings.
Hosting branch `docs/privacy-site`, commit `efe5f2a`.

## Ograniczenia i blokery zewnętrzne

- Play Console8799678699020536617: konto osobiste, weryfikacja w toku. Nie potwierdzono dostępu narzędziowego ani utworzenia aplikacji w Console. Nie przesłano AAB/deklaracji i nie zaakceptowano zobowiązań prawnych za wydawcę.
- Po weryfikacji: wpis aplikacji, formularze/IARC właściciela, test internal/closed, wymagane12 testerów opt-in/14 kolejnych dni i wniosek o dostęp produkcyjny. APK GitHub nie zalicza testu Play. [Instrukcja](RELEASE_GOOGLE_PLAY.md).
- Prywatny klucz `/home/roch/.candyverse-signing/v1/`, poza Git, katalog0700/pliki0600; backup poza komputerem wymagany od właściciela. Nie regenerować. Zachować certyfikat przy Play App Signing (ADR-0014).
-60FPS jest celem; p95 części klatki nie dowodzi stałej liczby FPS. Telefon nie został wybrany jako reprezentatywny benchmark średniej klasy. Brak długiej ręcznej oceny tempa ekonomii bez fixture; fixture nie są kodem produkcyjnym.
- Emulator GPU bywał niestabilny, z utratą całego urządzenia; jedna próba LOW_MEMORY, inne bez ustalonej przyczyny. Nieudane próby zachowano, nie zaliczają QA. Finalna macierz jest zielona; produkcyjny renderer nie został zmieniony. Szczegóły w RELEASE_REPORT.

## Kontynuacja

Root `main` stabilny. T-010 worktree `.../candyverse-workers/t010`, branch `test/qa-hardening`, PR#10 MERGED.
T-011 worktree `/home/roch/programing/Renvo/candyverse-workers/t011`, branch `chore/playstore-release`, PR#11 MERGED.
Handoff po publikacji: branch `chore/public-release-handoff` w root, commit `d6c712c`; aktualizacja dokumentacji i zmniejszenie CI contents write→read dla publicznych plików.
Logi telefonu lokalnie `/home/roch/.cache/candyverse/qa-phone-final/`; nie publikować identyfikatora USB i logów pozostałych aplikacji.

## Zamknięcie sesji wydania

- PR#10 i#11 MERGED po wszystkich zielonych kontrolach. Finalny head wydania16f3db4: Flutter38722227574 SUCCESS i wszystkie cztery przypadki zgodności38722227448 SUCCESS. Tag `v1.0.0-rc.1` wskazuje `67f4ae5`.
- Prerelease opublikowano2026-10-15 o10:48:29 UTC. Załączniki: APK/AAB/universal APK, SHA256SUMS, build-info.json i store-kit ZIP. Brak kluczy prywatnych w załącznikach.
- Publiczne pobieranie bez uwierzytelnienia: APK HTTP200/50988653B i zgodny SHA256; store-kit HTTP200/614878B i zgodny SHA256; AAB HEAD HTTP200/50197815B. Tag wskazuje merge67f4ae5.
- Podpisane binaria pozostają niezmienione. Store-kit jest snapshotem przygotowania kandydata; aktualny stan sesji jest w tym pliku. Nie mylić publicznego APK z zaliczeniem testu Google Play.

**Jedno następne zadanie:** po zakończeniu weryfikacji konta właściciela utworzyć wpis Candyverse w Play Console i przesłać zweryfikowany AAB1.0.0+1 do testu wewnętrznego, zgodnie z RELEASE_GOOGLE_PLAY. Nie podawać haseł ani klucza w czacie.

## Nowa sesja — Candy Kingdom2026-10-15

Właściciel jawnie rozszerzył V1; plan wszystkich zmian zapisany w KINGDOM_EXPANSION, PRD/GDD/Visual i ADR-0016. Baseline flutter test160/160 PASS; main349684e czysty przed pracą. Plan wykonano na feat/candy-kingdom-expansion; aktualny stan integracji poniżej.

### Integracja Candy Kingdom — aktualny stan

Plan T-012 scalony: [PR#13](https://github.com/RochZaremba/Candyverse-Block-Bloom/pull/13),
head4add259, merge85c7a91; CI38727224494 SUCCESS. Historyczne wyniki V1 powyżej
nie stanowią potwierdzenia nowego wydania1.1.0+2.

Branch `feat/kingdom-integration`, ostatni commit implementacji `6e0780f`.
Zintegrowano T-013–T-017:30 poziomów, schema2/migrację, dokładny pasywny dochód,
prestiż/gwiazdki i3 krajobrazy, renderowane zwierzaki/budynki, menu2 przyciski,
gear, EN dla nowych profili, candy komunikaty i opaque przejścia. Wspólny zapis
serializuje dochód razem z ruchami gry; testy obejmują utratę potwierdzenia i retry.
Assety/provenance/prompty: `assets/kingdom/`. Fanfara prestiżu i nowy launcher
w `29d96db`; izolacja aplikacji QA i rozszerzony smoke w `ac02b16`.

Potwierdzone lokalnie: `flutter test --concurrency=2`193/193 PASS,
`dart test test/game`71/71 PASS, `flutter analyze` PASS, format65 plików bez zmian,
`python3 scripts/check_docs.py`48 dokumentów PASS,
`python3 scripts/test_release_tools.py`19/19 PASS. Goldeny obejmują nowy Home,
wyspy poziomu0/1/5/6/15/30 i różne światy; testy małych ekranów/200% tekstu
i reduced-motion przechodzą. Hostowy scenariusz nowych zakupów, dochodu
i anulowania/potwierdzenia prestiżu PASS, ale nie zastępuje Android DataStore.

T-018 IN_PROGRESS: pierwszą próbę przerwano przed instalacją; ponowny fizyczny test20min uruchomiony na podłączonym telefonie,
osobny applicationId `com.renvo.candyverse.qa` / „Candyverse QA”, bez kasowania
zwykłej aplikacji. Wynik jeszcze nieznany. Logi lokalne:
`/home/roch/.cache/candyverse/qa-kingdom-phone-retry/`. Podpisane buildy1.1.0+2
zbudowano w osobnym worktree `.../candyverse-workers/kingdom-release`,
ze źródła6e0780f i dotychczasowego zewnętrznego klucza. APK i universal APK
przechodzą audit manifest/permissions/backup/ELF64/ZIP16KB i mają certyfikat
`2064a303250785a1ef85029a03a543dc759ab6d715f1fb2f05dccdca04e70506`.
Wersja/APK potwierdzona aapt2:1.1.0/code2. AAB bundletool validate/config16KB,
jarsigner PASS (self-signed/time/JarInputStream warnings zapisane w logu).
Nowe pliki lokalne `/home/roch/.cache/candyverse/artifacts/kingdom-1.1.0/`:

- APK `cb84b22b4422bc88f6cb5cd84a6d514e5e5f37e2200e2041df6f77a12ec1bfda`.
- AAB `f3ae85ca7bf187395e6c32d2c3e91d6b4b35cb365f6fe3a989e79f49753ada7a`.
- Universal `20f3ee18aa8b3ec07c07d9aba284485f98345a2b4edb9877f251af7afeb34730`.

Przeglądy agentów ekonomii i release nie wykryły blokera; poprawiono dokumentację
pochodzenia grafiki52c08a8 i listing PL/EN12718e5. Poprzednie materiały1.0.0 są
historyczne. Nowy PR integracyjny jeszcze nieutworzony; draft kandydata przygotowywany.

Niedokończone: rzeczywisty smoke nowej wersji na telefonie, audyt APK/AAB,
cztery przypadki zgodności nowego podpisanego kandydata, CI i merge integracji.
Nie oznaczać tego rozszerzenia jako opublikowanego ani w pełni przetestowanego.
Blokery Play Console i backupu klucza pozostają aktualne.

**Jedno następne zadanie:** zakończyć i udokumentować fizyczny smoke T-018,
następnie przygotować nowego kandydata1.1.0+2 do macierzy zgodności.
