# Test Plan i definition of done

Dla T-012–T-018 obowiązują [Candy Kingdom](KINGDOM_EXPANSION.md) i
[ADR-0016](adr/0016-kingdom-progression-and-art.md). Kryteria poniżej opisują
wymaganą weryfikację, nie wyniki. Aktualne potwierdzenia i nieukończone kontrole
prowadzi [STATUS](STATUS.md); wyniki historycznego rc.1 nie zaliczają1.1.0+2.

## Quality gates PR

Po T-001, jeśli istnieje Flutter SDK:

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
dart test test/game
flutter test
python3 scripts/check_docs.py
python3 scripts/test_release_tools.py
```

Na PR od T-004: co najmniej jeden widget test na główny flow. Na T-010/T-011 dodatkowo smoke test na fizycznym Androidzie/emulatorze i `flutter build appbundle` z odpowiednią konfiguracją (podpis dopiero gdy klucz dostarczony).

## Wymagane przypadki silnika

- T-002: legalne umieszczenie, zderzenie, przekroczenie krawędzi, brak zmiany stanu dla ruchu nielegalnego, clear 1 row/1 column, intersection clear raz, multi-line, game-over, pusta tray/refill po 3 sztukach.
- T-003: seeded RNG / replay, fairness generatora przy ograniczonej przestrzeni, score placement, combo reset, combo cap, Sugar Rush math.
- T-006: próg 5/10/15, queue przy wielu liniach, brak pustych kart, cap upgrades, eraser na pojedynczej zajętej komórce, zero reward za eraser, stan bez ruchów z dostępnym eraserem.
- T-008: coin balance, negative balance rejected, purchase next level, max level, insufficient funds, `completeRun` twice → award once, restore in the middle of run, interrupted save, malformed JSON/schema mismatch.

## Interakcje UI (ręczne / automatyczne)

1. Nowy profil → Home po angielsku → Play; Settings pod gear → wybór PL/EN; zapisany język zachowany po wznowieniu.
2. Drag block z ghost + nielegalna pozycja → brak utraty figury.
3. Ukończenie linii → efekt animacji/score/coin pending.
4. Milestone → wybór upgrade → faktyczna zmiana efektu.
5. Game over → raz nagroda → Replay oraz Island.
6. Upgrade Tree, House, Fountain → aktualny poziom i widoczny wzrost postępu; render zmienia etap co5 poziomów.
7. Tap character → reakcja; ponowne uruchomienie → zachowana wyspa.
8. Pauza/tło → powrót → ta sama plansza i figury.
9. Mute/haptics/reduced motion/reset → działanie przełączników, reset z potwierdzeniem.
10. Back navigation / nowy run / minimalny ekran / skalowanie tekstu → brak overflow/crashy.

## Candy Kingdom — regresje ekonomii i migracji

- Schema1→2 zachowuje portfel, rekord, trzy dotychczasowe poziomy, ID nagród,
  kompletną planszę/tray/RNG/upgrades/phase i ustawienia PL/EN. Brak dochodu
  sprzed pierwszego rozliczenia aktualizacji; kolejny zapis ma schema2.
- Zakupy każdego obiektu1..30: ceny1..3 bez zmian, dalsze kwadratowe, brak
  przeskoków, brak zakupu ponad30 i brak ujemnego portfela.
- Dochód: pusta wyspa0, poprawne zaokrąglenie stawki, +10%/gwiazdkę, online,
  długa przerwa offline i zachowana reszta przy krótkich tickach. Wstrzykiwany
  zegar; cofnięcie czasu i wielokrotny odczyt nie przyznają ponownie monet.
  Duże iloczyny nie przepełniają pośrednich obliczeń; niewyrażalne saldo lub
  stawka wywołują jawny błąd.
- Zakup/prestiż rozlicza poprzedni interwał starą stawką. Nieudany zapis,
  zapis z utraconym ACK, retry i restart procesu nie powielają dochodu/zakupu.
  Równoległy checkpoint i zmiany ustawień zachowują cały wspólny profil;
  błąd dochodu można ponowić z nakładki zapisu gry.
- Prestiż tylko przy3×30: anulowanie niczego nie zeruje, potwierdzenie dodaje
  jedną trwałą gwiazdkę, zeruje3 poziomy i zmienia krajobraz. Portfel, rekord,
  ustawienia i run pozostają. Odczyt po restarcie zachowuje wynik.

## Candy Kingdom — UI i natywne QA

- Home ma dokładnie dwa główne przyciski Play/Island oraz gear w lewym górnym
  rogu z celem dotyku48dp. Banner pochodzi od właściciela; renderowane zwierzaki
  i budynki są prawdziwymi lokalnymi assetami, z provenance.
- Goldeny Home i wyspy obejmują poziomy0/1/5/6/15/30 oraz kolejne krajobrazy;
  przed capture assety są załadowane. Sprawdź320dp/duży telefon, tekst200%,
  długie PL i EN, brak overflow i sensowne semantyki.
- Przejścia mają stabilne tło i załadowane obrazy; brak białego flash i chwilowo
  pustych sprite'ów. Komunikaty i potwierdzenia mają candy ramkę z maskotką.
  Reakcje, ograniczone confetti/fajerwerki i fanfara nie blokują dotyku;
  reduced-motion, wyciszenie, haptyka, TickerMode i tło działają niezależnie.
- Rozszerzony native smoke na fizycznym Androidzie trwa co najmniej20 minut
  aktywnej gry, zapisuje FrameTiming i wynik instrumentacji. Używa osobnego
  `com.renvo.candyverse.qa`, nie kasuje danych zwykłej gry. Scenariusz sprawdza
  gameplay, dochód, zakup30. poziomu, anulowanie/potwierdzenie prestiżu,
  ustawienia/reset i rzeczywisty Android DataStore. Hostowy smoke go nie zastępuje.
- Osobno audytuj nowy podpisany APK/AAB oraz uruchom zgodność produkcyjną:
  APK na API24 i API36, APK na rzeczywistym API35/16KB oraz APK wygenerowany
  z finalnego AAB na API36. Sprawdź input, screenshoty, tło/powrót i force-stop
  z identyczną64-polową planszą po wznowieniu. Wersja, SHA256 i raporty muszą
  dotyczyć tego samego nowego kandydata; nie nadpisuj artefaktów rc.1.

## Testy nieletnich i UX

- Brak reklam, zakupów, retencji wymuszanej karą, mechanizmów presji i nieproszonych powiadomień.
- Brak migotania/stroboskopów; pomniejszona liczba animacji działa.
- Brak tekstów zawstydzających przy porażce, brak przerwań w trakcie ważnego ruchu.
- Dobrze widoczne potwierdzenie resetu danych i konsekwencje braku chmury.

## Wizualny quality gate

- 6 ekranów nie przypomina gołego Material Scaffold.
- Te same tokeny i styl postaci w całej aplikacji.
- Postacie własne lub prawidłowo licencjonowane, minimum dwie animacje.
- Realne screenshoty ekranu 320–360 dp i dużego telefonu; złote testy z referencją, jeśli środowisko je wspiera.
- Czytelne linie/plansza, użyteczny touch target, kontrast wystarczający mimo pastelowej estetyki.

## Performance

Oceń na średniopółkowym sprzęcie: przynajmniej krótki profil animacji pełnego clear oraz wyspy. 60 FPS to **cel**, nie twierdzenie bez pomiaru. Sprawdź lifecycle, audio i wibracje. Profiling wyniku dołącz do PR T-010, albo zaznacz brak narzędzia.

## Release exit gate

Rzeczywisty podpisany APK/AAB z nowym versionCode i potwierdzonym certyfikatem / brak klucza wskazany jako blocker, `targetSdk >= 36` zweryfikowany, testy manualne potwierdzone, Data safety i policy zweryfikowane przeciw rzeczywistym zależnościom, listing odpowiada grze, status dokumentacji aktualny.

## T-021 Evolution

- `test/game/evolution_test.dart`:12 kart, niezależne progi ruchów/linii,
  ładowanie wierszami, krawędzie i łańcuchy,4 synergie, deterministyczna wymiana,
  cooldown, ratunek, schema1/2→3, restore i jednokrotna nagroda.
- `test/evolution_ui_test.dart`: podgląd/anulowanie/potwierdzenie bomby,
  slot/kolor, blokada checkpointu/retry, PL/EN/320dp/200% i prawdziwe goldeny.
- Rozszerzony host/native smoke odtwarza sesję po wymianie, sprawdza zapisane
  RNG/priming, wykonuje Rainbow Explosion i kontroluje pendingCoins/wallet.
  Natywny raport musi mieć evolutionPowersVerified/evolutionRestoreVerified.
  Wyniki hosta nie zastępują DataStore Androida; wynik CI sprawdzaj w STATUS.
