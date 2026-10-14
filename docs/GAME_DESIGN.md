# Game Design Document (GDD) — kontrakt rozgrywki

**Wersja:** 0.1 · Każda zmiana reguł wpływająca na zapisy lub testy wymaga aktualizacji tego dokumentu i ewentualnie ADR.

## 1. Plansza i klocki

- Plansza: `8 × 8`, koordynaty `(row, col)` w zakresie `0..7`.
- Pole jest puste lub zawiera konkretny identyfikator koloru/skin. Kolor nie wpływa na zasady.
- Figury to niepuste zbiory względnych współrzędnych `(dr, dc)` bez duplikatów, w znormalizowanej postaci; min `dr=0`, min `dc=0`.
- Wymagane minimum 12 figur: 1×1, 1×2, 1×3, 1×4, 2×1, 3×1, 4×1, 2×2, L triomino (2 rotacje), T tetromino, S/Z, 3×3 (jako trudniejszy element). Można zachować 12–16 wyraźnie różnych masek.
- Gracz widzi **dokładnie 3 sloty**. Zużyte sloty pozostają puste, dopóki wszystkie 3 nie zostaną wykorzystane; wtedy generujemy nowy zestaw 3.
- W V1 brak ręcznego obracania figury. Obrócone warianty mogą być osobnymi figurami w generatorze.
- Legalny ruch: każda komórka maski przy danym origin musi znajdować się na planszy i być pusta. Ruch nielegalny nie zmienia stanu.
- Po legalnym ruchu umieść wszystkie bloki **naraz**, następnie wykryj pełne wiersze i kolumny w jednym przebiegu.
- Usuń unię tych pól jednocześnie: komórka na przecięciu pełnego wiersza i kolumny znika tylko raz, ale **liczą się dwie linie**.
- Po czyszczeniu i ewentualnym ponownym losowaniu sprawdź, czy którakolwiek z pozostałych figur pasuje w dowolnym miejscu.
- Gdy żadna nie pasuje, zakończ run (z wyjątkiem dostępnego aktywnego Rainbow Eraser — patrz sekcja 4).

## 2. Losowanie i uczciwość

- Silnik przyjmuje wstrzykiwany `RandomSource`, np. deterministyczny `seed` w testach.
- Jednoznaczny katalog masek i względnych wag trzymany w konfiguracji.
- W nowej trójce zapewnij przynajmniej jeden legalny element **jeśli jakikolwiek element katalogu może się zmieścić**. W przeciwnym razie naturalny game over.
- Ogranicz spam dużych kształtów przy mocno zajętej planszy. Algorytm nie może arbitralnie gwarantować wygranej ani świadomie wymuszać przegranej.
- RNG + konfiguracja muszą pozwalać odtworzyć konkretny test.

## 3. Wynik i kombinacje

Wartości startowe (wszystkie całkowite, konfigurowalne):

- `placementScore = 10 × liczba_pól_figury`
- `lineClearScore = 100 × liczba_usuniętych_linii`
- `multiClearBonus = 40 × max(0, liczba_linii - 1)`
- `streak` wzrasta o 1 przy ruchu usuwającym ≥1 linię, resetuje się do 0 przy ruchu bez czyszczenia.
- Za każde kolejne czyszczenie mnożnik punktów czyszczenia rośnie o 25%, max do `x2.0`: `numerator = 4 + min(streak - 1, 4)` dla streak ≥ 1; bazę punktową za czyszczenie `(lineClearScore + multiClearBonus)` mnożymy jako `floor(base * numerator / 4)`.
- Punkty za samo umieszczenie figury nie korzystają z combo.
- `Sugar Rush` dodaje 25% do **punktów czyszczenia** na poziom, maksymalnie 2 poziomy; zastosuj łączny mnożnik w jednej deterministycznej formule całkowitoliczbowej. Zapisz kolejność operacji w testach, bez floatów.
- Rekord punktów to maksymalny score pojedynczego runu.

## 4. Roguelite — dokładnie 3 efekty

Moment wyboru: każde **5 kolejnych łącznie wyczyszczonych linii** (milestone 5, 10, 15...). Jeśli podczas ruchu przekroczono próg, zaplanuj jedną kartę wyboru na bezpieczny moment po zakończeniu animacji i przed następnym ruchem; kolejne progi obsłuż bez utraty postępu (kolejka wyborów).

- **Sugar Rush** (maks. 2 poziomy): +25% do punktów z usuwania linii na poziom.
- **Lucky Jelly** (maks. 2 poziomy): +25% do *bazowych Candy Coins* za run na poziom. Ostateczne zaokrąglenie w dół, obliczane raz przy przyznawaniu nagrody.
- **Rainbow Eraser** (maks. 2 użycia na run): pozwala wymazać jedno zajęte pole, nie daje punktów ani coinów, zużywa jedno użycie. Wybór komórki jest potwierdzany przed zastosowaniem. Jeśli nie ma ruchu, a eraser jest dostępny i są zajęte pola, zamiast natychmiastowego game-over pokaż czytelną opcję jego użycia; po rezygnacji run można zakończyć.

Karty zawierają nazwę, ikonę i prawdziwy opis. Losuj (seedowane) maks. 3 dostępne ulepszenia bez duplikatów; jeśli mniej niż trzy jest dostępnych, pokaż tylko możliwe opcje. Jeśli brak dostępnych, pomiń etap wyboru. Wszystkie efekty znikają po zakończeniu runu.

## 5. Monety i wyspa

- `baseCoins = 5 × liczba_linii_wyczyszczonych_w_runie`. Brak coinów za samo dotknięcie ekranu i brak darmowego generatora offline.
- `awardedCoins = floor(baseCoins × (4 + poziomLuckyJelly) / 4)`.
- W trakcie gry UI pokazuje `pendingCoins`; saldo wyspy rośnie **tylko po finalizacji runu**.
- Każdy run ma lokalny, monotonnie rosnący numer ID. Finalizacja zapisuje w **jednym stanie** nowe saldo, rezultat, rekord, `lastAwardedRunId`, status runu. Wielokrotne wywołanie finalizacji tego samego ID nie może przyznać nagrody ponownie.
- Dane zapisu mogą zostać utracone po odinstalowaniu aplikacji (brak chmury); zakomunikuj użytkownikowi przy resetowaniu danych.

Poziomy obiektów na wyspie i ceny (poziom 0 = niezakupiony):

| Obiekt | Poziom 1 | Poziom 2 | Poziom 3 |
| --- | --- | --- | --- |
| Candy Tree | 10 | 25 | 45 |
| Jelly House | 15 | 30 | 50 |
| Rainbow Fountain | 20 | 35 | 55 |

Każdy upgrade kupuje **kolejny** poziom (bez przeskakiwania), od razu wizualnie go zmienia. Zero biernych generatorów waluty, cooldownów i opłat prawdziwymi pieniędzmi.

## 6. Postacie

Pink Mochi, Blue Jelly, Lemon Blob, Minty Monster. Każda ma inny kształt i minimum: `idle` (oddech/pływanie), `tap reaction` (podskok/mrugnięcie). Nie ma czatu, dialogów AI, kolekcji losowych i śledzenia czasu.

## 7. Save / Resume / Pause

- Po każdym zaakceptowanym ruchu zapisuj snapshot: plansza, figury/tray, `rngSeed`+stan (lub serializowalny RNG), score, streak, lines, upgrades, pendingCoins, wybór/stan UI istotny dla gry.
- Snapshot musi pozwolić wznowić run bez ponownego losowania i bez innego wyniku.
- Pauza i przejście do tła nie kończą runu. Nie ma kary za długą przerwę.
- Nagroda i jej ID przyznawane dokładnie raz; testy crash/restart i ponownej finalizacji są obowiązkowe.

## 8. Pętla UX

`Start` → `Place` → `Clear` → `Points & juice` → (`Upgrade at threshold`) → `Continue` → (`Game over`) → `Coins once` → `Island or Retry`.

Nie implementuj streaków codziennych, wymuszonych przerw reklamowych ani mechanizmów presji społecznej. Animacje są celebracją gracza, nie sztucznym opóźnieniem interakcji.
