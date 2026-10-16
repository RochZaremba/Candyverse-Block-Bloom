# ADR-0018: Oprawa według pięciu referencji ekranów

Status: Accepted — jawne polecenie właściciela, 2026-10-16.

## Kontekst

Właściciel przekazał pięć kompozycji menu, planszy, wyniku, okna powrotu i wyspy,
zamawiając wygląd możliwie bliski referencjom. Dotychczasowe małe ilustracje na
pastelowym tle i płaskie przyciski nie odpowiadają temu zamówieniu.

## Decyzja

Osobne lokalne tła zachowują kompozycję logo, krajobrazów i zwierzaków. Liczby,
plansza, trzy klocki, przyciski, okna i karty budynków są rzeczywistym UI Fluttera.
Puste powierzchnie przycisków i postacie mają alpha; font Lilita One jest lokalny
i ma dołączoną licencję OFL. Źródła i generowanie opisano w
[provenance](../../assets/kingdom/REFERENCE_ART.md).

Banner zachowuje wskazany napis „Przyszła reklama” jako dekoracyjną rezerwację
miejsca. Zasady offline i istniejące deklaracje prywatności nadal obowiązują.
Licznik obok logo wyspy przedstawia rzeczywiste gwiazdki prestiżu. Odbiór,
rozbudowa i prestiż używają obecnego AppSession, cen i trwałego zapisu schema2.
Dolne zakładki pokazują wyspę, obecnych mieszkańców, istniejące dekoracje oraz
podgląd trzech światów i warunek prestiżu. Menu i logika planszy pozostają wspólne
dla nowych i wznowionych profili.

Gear Home przechodzi do prawego górnego rogu zgodnie z nową referencją. Zakładki
wyspy pozostają widoczne poza przewijaną treścią. Przy dużym tekście karty
budynków układają się pionowo, a długie treści okien przewijają się niezależnie
od przycisków. Zachowane są hit targets, reduced-motion, lifecycle oraz bramka
potwierdzenia zapisu każdego ruchu.

## Konsekwencje

Nowa wersja rozwojowa to 1.2.0+4. Historyczne opublikowane wydanie 1.1.0+3
pozostaje bez zmian. Zaktualizowane goldeny i pięć portretowych przykładów
kontrolują prezentację; testy gestów, zapisu, zakupów, prestiżu i resetu kontrolują
działanie. Pomiary hosta nie stanowią dowodu wydajności ani trwałości na Androidzie.
