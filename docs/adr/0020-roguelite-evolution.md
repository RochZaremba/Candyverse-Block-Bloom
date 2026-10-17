# ADR-0020: Roguelite Evolution

Status: Accepted — zamówienie właściciela 2026-10-18.
Supersedes ADR-0010 for new runs; legacy runs retain its rules.

## Context

Właściciel zamówił12 ulepszeń,3 ścieżki, bomby, wymianę kształtu, premie combo
oraz4 synergie. Poniższe wartości to jawny początkowy balans implementacji.

## Decision

T-021: trzy ścieżki po cztery kolejne karty. Wybór oferuje następny poziom
każdej niewymaksowanej ścieżki, tasowany snapshot RNG. Próg to wzrost
`max(moves ~/ 5, totalClearedLines ~/ 5)`; przekroczenia kolejkują się.
Każde5 poprawnych placementów daje rozwój również bez czyszczenia. Akcje mocy
nie liczą się jako ruchy, nie ładują cooldownu ani progów i nie resetują combo.

| Ścieżka | Karty1–4 | Efekty |
| --- | --- | --- |
| Explosive Candy | Explosive Candy, Blast Radius, Chain Reaction, Sugar Nova | Co3 usunięte **wiersze** ładunek (kolumny nie ładują); maks3. L1 krzyż5 pól, L2 obszar3×3, L3 łańcuchy, L4 ładowanie co2 wiersze. |
| Rainbow Magic | Rainbow Magic, Quick Magic, Color Mastery, Rainbow Reserve | Wymiana wybranego niepustego slotu na inny ID; pierwsze użycie gotowe. Cooldown6/4/4/3 placementów; L3+ wybór koloru wymienianego klocka. |
| Lucky Paws | Lucky Paws, Combo Treats, Golden Paws, Lucky Cascade | Combo = multi-clear>=2 lub kolejne czyszczenie (streak>=2). Premia40×poziom punktów i2×poziom monet; L4 dodatkowo2 monety za każdą linię combo. |

Ładunki bomb są zachowane nawet przy pustej planszy. Zajęte pola otrzymują
znaczniki bomb deterministycznie w kolejności row-major, do liczby ładunków.
Gracz wskazuje zajęte pole; potwierdzenie pokazuje rzeczywisty zasięg. L3+
trafienie znacznika uruchamia jego3×3, raz na znacznik, bez rekurencji/duplikacji.
Detonacja zużywa1 ładunek oraz dodatkowy za każdy inny uruchomiony znacznik.
Usunięcie znacznika zwykłą linią nie wybucha, pozostałe ładunki otrzymują nowe
znaczniki. Same eksplozje nie liczą linii i nie dają bazowych monet/punktów.

Synergie (automatyczne, widoczne w UI):
- **Rainbow Explosion**: Explosive>=2 + Rainbow>=2. Wymiana primuje następną
  bombę; gracz wybiera kolor, bomba usuwa również wszystkie pola tego koloru.
- **Golden Explosion**: Explosive>=2 + Paws>=2. Każde rzeczywiście zniszczone
  przez bombę pole daje1 pending coin, również z koloru/łańcuchów, raz na pole.
- **Lucky Spectrum**: Rainbow>=2 + Paws>=2. Wymiana daje2 pending coins.
- **Candy Constellation**: wszystkie trzy>=3. Combo doładowuje1 bombę, limit3.

Stan Evolution jest niemutowalny i pure Dart: poziomy, ruchy, cooldown,
ładunki/progress wierszy, indeksy znaczników, priming oraz bonusCoins.
Wszystkie decyzje i RNG podlegają dotychczasowemu checkpoint/retry. Pending
bonusy trafiają do portfela dopiero przy idempotentnej finalizacji.

Schema3 zapisuje Evolution oraz bonusCoins ostatniego wyniku. Decoder1/2
zachowuje profil i trwający legacy run bez zmiany jego kart/RNG. Nowe runy mają
Evolution; brak cichego przeliczenia starej nagrody. Nowsza wersja odrzucana.
Stara aplikacja odrzuci schema3 — nie wspieramy downgrade'u.

## Consequences

Brak zegarowych cooldownów, reklam, nowych SDK i presji czasu. Dostępna moc
może uratować planszę przed game over. Ratunek tęczą jest dostępny tylko jeśli
istnieje inne pasujące ID katalogu, żeby nie oferować niemożliwego ratunku.
UI ma PL/EN, liczniki, znaczniki, podgląd i potwierdzenie bomby, wybór slotu
oraz koloru. FX używają obecnego ograniczonego burst i reduced-motion.
Parametry wymagają dalszego playtestu balansu; testy dowodzą reguł, nie zabawy.
