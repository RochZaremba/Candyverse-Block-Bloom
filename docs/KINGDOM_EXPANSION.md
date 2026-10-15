# Candy Kingdom — zatwierdzone rozszerzenie po V1

Właściciel 2026-10-15 polecił zaplanować i wdrożyć poniższe zmiany. To jawne
rozszerzenie poprzedniego zakresu V1, nie zmiana historycznego wydania rc.1.
Android/offline, brak reklam/IAP/kont/backendu, zasady planszy i bezpieczeństwo
nieletnich pozostają w mocy. Stare zapisy muszą zachować postęp i język.

## Plan wykonania i kryteria

| ID | Fragment | Wynik wymagany |
| --- | --- | --- |
| T-012 | Kontrakt rozszerzenia i migracja | plan/PRD/GDD/ADR, baseline160 PASS, zgodność odczytu schematu1 |
| T-013 | Długa progresja i ekonomia |30 poziomów każdego z3 obiektów, wyższe ceny powyżej3, pasywny dochód online/offline, atomowe rozliczenia i testy czasu/błędów |
| T-014 | Nowa wyspa / gwiazdki | dobrowolny reset ukończonej wyspy (3×30) za1 trwałą gwiazdkę; kolejny krajobraz, +10% dochodu/gwiazdkę; jawne potwierdzenie; zachować monety, rekord, ustawienia i run |
| T-015 | Renderowana oprawa | przesłany banner i tożsamość ikony, nowe AI renderowane kotek/piesek/królik/lisek, renderowane budynki i wyspy, lokalne assety/provenance/licencje |
| T-016 | Menu i język | tylko2 główne przyciski Play/Island, gear lewy górny róg, dekoracyjne animacje; nowe profile EN, PL w Settings, dotychczasowy wybór zachowany |
| T-017 | Przejścia i komunikaty | brak białego/błyskającego tła przejść, wspólny candy transition, cukierkowe komunikaty/dialogi z maskotką; bez systemowych toastów udających UI gry |
| T-018 | Celebracje i QA wydania | confetti/fanfary lokalne/fajerwerki bez fleszy, limit cząstek i reduced-motion/lifecycle; testy migracji/ekonomii/UI, goldeny, analyze/APK/AAB i smoke; nowy build, bez nadpisania rc.1 |

Kolejność: kontrakt → niezależne moduły ekonomii, grafiki i nawigacji → integracja
wyspy/komunikatów → testy i nowy kandydat. Każdy fragment ma osobny commit;
PR-y scalane po kontrolach. Status wykonania wyłącznie w STATUS.

## Ekonomia

- Poziomy0..30. Koszt1..3 zachowuje istniejące ceny startowe (łagodne wejście);
  koszt4..30 rośnie deterministycznie kwadratowo, osobno dla każdego obiektu.
- Dochód pasywny z rozbudowanych obiektów:1 moneta/minutę za każde rozpoczęte3
  poziomy łącznie; pusta wyspa nie produkuje. Gwiazdki dają +10% stawki każda.
  Obliczenia całkowite z zachowaniem ułamkowej reszty; nie resetować reszty co tick.
- Utrwalony znacznik czasu i jedno saldo w tym samym snapshot. Rozliczać stary
  interwał starą stawką przed zakupem/resetem wyspy; brak podwójnego przyznawania
  po restartach lub utracie potwierdzenia zapisu. Zegar wstrzykiwany w testach.
- Offline czas lokalny; cofnięcie zegara nie daje monet ani nie cofa high-watermark.
  Brak sieci/antycheatu i obietnicy ochrony przed ręczną zmianą zegara.
- Brak limitu odbioru wymuszającego codzienny powrót, streaków i utraty zapisanych
  monet po przerwie. UI pokazuje stawkę i saldo, bez presji czasu.
- Migracja1→2 nie nalicza dochodu sprzed instalacji aktualizacji. Zachowuje
  poziomy0..3, portfel, rekord, ID nagród, pełny aktywny run i język PL/EN.

## Oprawa i UX

- Źródło marki: obraz właściciela `Candyverse_ Whimsical Candy Kingdom-1.png`.
  Banner wyświetlany jako oryginalny obraz; ikona i nowe sprite'y zgodne z kotkiem.
- Cztery renderowane zwierzaki, idle + reakcje; scenografia zmienia motyw po
  prestiżu.6 etapów wizualnych budynków co5 poziomów; każdy zakup ma czytelny
  wzrost postępu, animację i aktualny poziom, nie sam niewidoczny licznik.
- Menu: Play (wznawia zapisany run) i Island; Settings jako gear48dp u góry po
  lewej. Ciepła renderowana oprawa, lekki ruch/sparkle, bez stroboskopów.
- Komunikaty oznaczają bannery/snackbary/dialogi wewnątrz gry. Nie dodawać push,
  uprawnienia powiadomień ani komunikacji sieciowej.
- English jest domyślne dla nowych/resetowanych profili i ekranów recovery.
  Istniejące zapisane PL/EN zachować. Settings zawiera oba języki.
- Animacje respektują OS/user reduced-motion, TickerMode i tło; nie blokują dotyku.
