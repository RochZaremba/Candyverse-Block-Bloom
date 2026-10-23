# ADR-0021: Czytelny ekran gry i karty co 30 ruchów

Status: Accepted — jawne zamówienie właściciela 2026-10-23.
Zastępuje częstotliwość kart z ADR-0010/0020 oraz przewijany panel gry.

## Kontekst

Właściciel uznał ekran za przeładowany i nieczytelny. Zamówił ekran bez
przewijania, dodatkowe informacje i powody blokady w oknie pod ikoną oraz
znacznie rzadsze nagrody (30–40 ruchów). Przyjmujemy 30 poprawnych placementów.
Dotychczasowe Evolution sumowało progi co 5 ruchów i co 5 linii, co powodowało
również kilka kolejnych okien po jednym ruchu.

## Decyzja

Jedna nowa karta za każde 30 zaakceptowanych ułożeń klocka. Czyszczenie linii,
wybór karty, anulowanie, odrzucony ruch, bomba, tęcza i eraser nie tworzą
dodatkowych progów. Punktacja, premie combo, ładowanie mocy i finalizacja monet
pozostają bez zmian. Karty są nadal wybierane przed następnym ruchem; po
rozwinięciu wszystkich ścieżek silnik pomija etap wyboru.

Evolution wykorzystuje istniejący utrwalony licznik `moves`. Historyczne runy
bez Evolution otrzymują opcjonalne pole snapshotu `legacyMoves`, domyślnie 0.
Ich nowy interwał zaczyna się przy pierwszym ruchu po aktualizacji, ponieważ
stary format nie zapisywał liczby placementów. Schema3 pozostaje zgodna:
decoder przyjmuje brak pola i dotychczas zarobione kolejki kart. Nie przeliczamy
wstecz ruchów ani nie zabieramy kart/RNG/salda. Już oczekujące karty mogą więc
jednorazowo wystąpić w starej kolejce. Nowe wybory powstają tylko co 30 ruchów.

Ekran gry zawiera pasek wyniku/monet, dominującą kwadratową planszę, trzy sloty
oraz krótki komunikat i przyciski mocy. Układ wykorzystuje dostępny obszar
SafeArea, a nie przewijanie; plansza dostosowuje rozmiar po powiększeniu tekstu.
Spokojny gradient zastępuje ilustrację z dużym logo/banerem i bohaterami na
ekranie gry. Menu, wyspa i wynik zachowują oprawę.

Ikona informacji otwiera instrukcje, postęp kart i szczegóły mocy/synergii;
ustawienia są dostępne w tym samym oknie. Niedostępna moc wyjaśnia przyczynę
po dotknięciu, zamiast być martwym przyciskiem. Ostrzeżenie „Brak miejsca”
otwiera dostępny ratunek i jawne zakończenie podejścia. Zamknięcie okna niczego
nie zużywa. Opisy mogą przewijać się w oknie, nigdy razem z planszą.
Przyciski mają co najmniej 48 dp, etykiety PL/EN, tekst zachowuje skalowanie,
a checkpoint nadal blokuje dotyk bez białego flasha.

## Weryfikacja

Wymagane: progi 29→30 i 59→60, brak progów linii, odrzucone ruchy/moce,
persistencja i zgodne RNG, stary zapis i oczekujące karty. UI: mały telefon,
PL/EN/200%, plansza i wszystkie sloty bez scrolla, popup niedostępnej mocy,
ratunek, gesty i brak flasha. Wykonane kontrole i blokery: [STATUS](../STATUS.md).
