# Visual Direction — Candyverse

## North Star

**Polished candy toy, not Material demo.** Maksimum przyjaznych kolorów, miękkich form i satysfakcjonujących mikroanimacji, przy bardzo czytelnej planszy. W świecie są galaretki, chmurki, cukierkowe drzewa i miękkie stworki. Nie robimy brutalnych motywów, groteski ani hiperbodźcowego migotania.

## Źródło tokenów

Wartości palety, promieni, czasów i limitów animacji są w [`../assets/design_tokens.json`](../assets/design_tokens.json). Używaj centralnego `AppTheme` z tokenami zamiast przypadkowych kolorów w widgetach.

### Wygląd

- 2D/2.5D, miękkie gradienty, cienie, delikatny specular highlight, jelly/glass-like blocks.
- Czyste pole gry i wyraźny kontrast między zajętym a wolnym polem; tło ma żyć, ale **nie utrudniać podejmowania ruchów**.
- Duże touch targets ~48dp minimum; UI po polsku i angielsku; w pionie; działa na telefonach ~320dp+ (zweryfikuj rzeczywistymi testami layoutu).
- Przyciski: nieskomplikowane, cukierkowe, z interakcją press/scale. Wyniki i pendingCoins zawsze czytelne.
- Nie zastępuj assetów generycznym emoji; własne figury/painter/SVG z licencją. Żadnych skradzionych ilustracji, klonów bohaterów znanych gier ani muzyki bez licencji.
- Docelowo trzy stany wizualne dla wyspy na obiekt + poziom 0, a nie tylko liczba w panelu.

## Ekrany i najważniejszy obraz

1. **Home** — logo, PLAY jako bohater pierwszego ekranu, fragment wyspy i 1–2 stworki w ruchu, rekord; bez reklam.
2. **Game** — górny pasek wyniku, **dominująca plansza 8×8**, pod nią trzy wyraźne klocki, drobna informacja o następnym ulepszeniu.
3. **Upgrade Choice** — przyciemnione tło, 2–3 duże karty z różnymi kolorami i czytelnymi opisami, możliwość ograniczenia animacji.
4. **Game Over** — wynik, monety, subtelna celebracja rekordu, Replay i Island. Żadnych fałszywych countdownów.
5. **Island** — jeden spójny widok sceny i obiektów. Każda rozbudowa widocznie zmienia świat. Stworki reagują na dotyk.
6. **Settings** — dźwięk, haptyka, ograniczony ruch, język, polityka prywatności, potwierdzony reset lokalnych danych.

## Feedback / animacja

| Akcja | Feedback | Zalecenie |
| --- | --- | --- |
| Podniesienie figury | skala ~1.05 i offset od palca | <150 ms |
| Preview poprawnego ruchu | jasny półprzezroczysty ghost w komórkach | stale dopóki drag |
| Preview błędnego ruchu | subtelne ostrzegawcze obramowanie | bez wstrząsania ekranu |
| Osadzenie bloku | squash & stretch | 140–220 ms |
| Czyszczenie linii | mikroglow → krótki burst → zniknięcie | 250–450 ms |
| Multi-clear | większy, ale ograniczony burst i score fly-up | nie blokować wejścia |
| Upgrade / zakup | scale pop, chmurka confetti, reakcja stworka | 200–450 ms |
| Idle scene | pływanie chmurek, mruganie / oddech | powoli, mały ruch |

Limity: unikać pełnoekranowych białych fleszy i błysków, brak efektów stroboskopowych. Zawsze respektuj reduced-motion (`MediaQuery.disableAnimations` / ustawienie gry) i mute.

## Performance

- Target 60 FPS na średniopółkowym urządzeniu, udokumentowany przez profiler.
- Ogranicz particle count (np. 40 jednocześnie) i koszt malowania (RepaintBoundary / painter caching).
- Nie animuj całych ekranów przy każdym ruchu i nie renderuj ciężkich shaderów bez profilu.
- Nie uruchamiaj animacji tła podczas background/pause.

## Weryfikacja wizualna

Przed zamknięciem PR UI: udokumentuj realny screenshot/golden test lub screenshot z emulatora; sprawdź mały ekran, polskie długie napisy, powiększony tekst, ograniczenie ruchu, brak overflow, czytelność bez dźwięku.

Nie oznaczaj P0 graficznego jako ukończonego, jeśli ekrany to nieostylowane szare formularze.
