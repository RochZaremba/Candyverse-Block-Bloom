# ADR-0010: Kolejka wyborów runu i ograniczenie Rainbow Eraser

**Status:** Superseded for new runs by [ADR-0020](0020-roguelite-evolution.md); retained for legacy runs  
**Date:** 2026-10-14

## Context

T-006 wymaga utrzymania każdego przekroczonego progu 5 linii i odtworzenia wyborów po restore bez ponownego losowania. Limit dwóch użyć Rainbow Eraser dotyczy całego runu, również po zużyciu wcześniejszych użyć.

## Decision

Run posiada jawne fazy `playing`, `upgrade`, `needsEraserDecision`, `gameOver`. Po ruchu kolejka rośnie o różnicę całkowitych ilorazów liczby linii przez 5. Kolejkę rozpatrujemy przed sprawdzeniem braku ruchów, dzięki czemu wybór Rainbow Eraser może uratować planszę. Wybór zużywa jeden element kolejki; brak dostępnych ulepszeń usuwa pozostałą kolejkę.

Dostępne efekty to dokładnie Sugar Rush i Lucky Jelly (poziomy 0..2) oraz Rainbow Eraser. `eraserAcquired` liczy przyznane użycia w całym runie (0..2); `eraserUses` liczy pozostałe (0..eraserAcquired). Zużycie nie otwiera możliwości trzeciego przyznania. Eraser usuwa jedno zajęte pole bez clear, punktów, monet, combo ani RNG. Prezentacja potwierdza wskazane pole przed akcją domenową.

Kolejność dostępnych kart jest tasowana Fisher–Yates przez ten sam serializowalny RNG co refill; snapshot zawiera stan RNG **po** tasowaniu i konkretne `upgradeChoices`, liczbę oczekujących wyborów oraz fazę. Rozstrzygnięta faza upgrade nie losuje ponownie. Adapter jawnej trójki bez RNG używa stałego seeda wyłącznie jako deterministycznego fallbacku testowego.

UI blokuje umieszczanie klocków od momentu wejścia domeny w fazę upgrade i pokazuje karty po zakończeniu feedbacku usuwania linii. Reduced-motion pokazuje wybór od razu. Kolejne oczekujące wybory nie otwierają wejścia planszy pomiędzy kartami.

`pendingCoins = 5 * totalClearedLines * (4 + luckyJellyLevel) ~/ 4`; zaokrąglenie następuje raz na całym wyniku. T-006 wyłącznie prezentuje tę kwotę, a portfel i finalizacja należą do T-008.

## Consequences

Save T-008 musi przechowywać oba liczniki erasera, kolejkę i wylosowane opcje. Wybór ulepszenia świadomie zużywa RNG i wpływa na przyszłe refille; replay wymaga utrwalenia akcji wyboru. Nie można ponownie wywoływać losowania podczas wyświetlania modalnego wyboru.

## Alternatives rejected

Limit wyłącznie na pozostałe użycia — pozwalałby przyznawać eraser bez końca. Osobny RNG bez snapshotu — niestabilny restore. Sprawdzenie game over przed kolejką — blokuje ratunkowy wybór erasera.
