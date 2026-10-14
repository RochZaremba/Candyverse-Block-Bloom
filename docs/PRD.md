# PRD — Candyverse: Block & Bloom

**Wersja specyfikacji:** 0.1 · **Data:** 2026-10-14 · **Status:** zatwierdzone założenia V1, bez implementacji

## Problem i propozycja wartości

Gra mobilna, którą można zrozumieć w kilkanaście sekund: układanie kolorowych klocków na planszy, odblokowywanie niewielkich ulepszeń podczas podejścia i budowanie przytulnej cukierkowej wyspy między podejściami. Zabawa bazuje na ekspresyjnej grafice, wrażeniu sprawczości i rosnącej sprawności gracza — bez sztucznej presji.

## Odbiorcy

Przede wszystkim 10–16 lat, odpowiednia także dla dorosłych. Dla celów zgodności zakładamy obecność dzieci poniżej 13 lat; grupa w Play Console musi odpowiadać rzeczywistemu projektowi, a nie strategii ominięcia reguł.

## Jednozdaniowe MVP

**W pełni grywalne** 8×8 Block Puzzle z trzema run-only upgrade'ami oraz jedną żywą wyspą, na której można kupić i zobaczyć rozwój trzech obiektów oraz czterech postaci, z zapisem offline i dopracowaną grafiką.

## P0 — absolutnie wymagane w V1

- [ ] Ekrany: Home, Game, Upgrade Choice, Game Over, Island, Settings.
- [ ] Silnik 8×8 i zestawy trzech figur; drag & drop z podglądem, poprawne clear rows/columns, scoring, combo, game-over.
- [ ] Trzy prawdziwe wybieralne ulepszenia podczas runu (patrz [GDD](GAME_DESIGN.md)).
- [ ] Candy Coins zdobywane z gry i wydawane wyłącznie na rozbudowę wyspy.
- [ ] Jedna scena 2D/2.5D, trzy obiekty po trzy poziomy, cztery animowane stworki.
- [ ] Spójne grafiki, efekty cząsteczkowe, krótkie animacje, SFX + mute, haptyka + off, reduced-motion.
- [ ] Trwały zapis ustawień, ekonomii, stanu wyspy i aktywnego podejścia; bez podwójnego przyznawania monet.
- [ ] UI PL/EN; poprawne działanie w pionie na różnych telefonach.
- [ ] W pełni offline; polityka prywatności, bez zbędnych uprawnień; release-ready Android.
- [ ] Testy automatyczne, testy manualne i CI.

## P1 — opcjonalne tylko gdy P0 jest kompletne

- Drobne warianty skórek klocków i naklejek przy zachowaniu tej samej ekonomii.
- Opcjonalny lekki tutorial kontekstowy przy pierwszym ruchu.

## Poza zakresem V1

Reklamy/AdMob, IAP, backend, login, leaderboard online, multiplayer, czat, streaming assetów, analityka, konta, notyfikacje, daily streak, battle pass, energia, lootboxy, płatne losowania, wyzwania godzinowe, social features, 3D, więcej niż jedna wyspa, kilkadziesiąt postaci.

## Cele jakościowe (kryteria, nie obietnice)

- Rozgrywka zrozumiała bez długiego tekstu.
- Wszystkie ruchy planszy precyzyjne i czytelne, bez możliwych niedozwolonych stanów.
- Brak crashy w podstawowym 20-minutowym scenariuszu QA.
- Brak nieaktywnych przycisków, atrap postaci i niedziałającej ekonomii.
- 60 FPS jako cel na reprezentatywnym telefonie średniej klasy (sprawdzić w profilingu; mierzyć, nie deklarować na ślepo).
- Każdy nowy użytkownik może zdobyć i wydać pierwsze monety w rozsądnym czasie, bez konieczności długiego grindu.
- Zdrowa regrywalność: brak kary za niewchodzenie do gry i brak nieograniczonych automatycznych powiadomień.

## Kryteria wydania

Zobacz [Test Plan](TEST_PLAN.md) i [Release](RELEASE_GOOGLE_PLAY.md). Spełnienie checklisty technicznej nie gwarantuje zatwierdzenia przez Google. Właściciel dokonuje ostatecznych deklaracji prawnych i sklepowych.
