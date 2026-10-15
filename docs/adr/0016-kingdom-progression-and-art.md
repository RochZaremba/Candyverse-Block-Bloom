# ADR-0016: Rozszerzenie Candy Kingdom, progresja i renderowane assety

**Status:** Accepted — jawne polecenie właściciela2026-10-15.

## Context

Wydanie rc.1 ma3 poziomy obiektów, brak dochodu pasywnego i grafikę wektorową.
Właściciel zamawia wiele poziomów, reset wyspy za gwiazdkę, dochód pasywny,
renderowaną oprawę z dostarczonej marki, animacje, nowe menu i domyślny EN.
Poprzednie ograniczenia produktowe nie blokują tego wyraźnie zamówionego etapu.

## Decision

Kontrakt w KINGDOM_EXPANSION:30 poziomów,6 etapów renderu, prestiż po3×30,
trwałe gwiazdki i +10% dochodu. Pure Dart ekonomia i schema2 z bezstratnym odczytem
schema1; znacznik czasu/reszta w pojedynczym atomowym snapshot. Rozliczenie przy
wczytaniu/resume i przed zmianą stawki, z testowalnym zegarem. Zero serwera i
brak codziennych limitów. Stara gra/RNG/nagrody pozostają niezależne od czasu.

Grafika rastrowa AI jest lokalna i opisana provenance; nie dodaje SDK ani runtime
AI. Atlas sprite'ów ogranicza liczbę plików i dekodowania. Jawnie wstępnie ładujemy
najważniejsze obrazy, stosujemy spójne opaque przejścia i dekoracyjne komunikaty.
Domyślny EN dotyczy nowych profili; nie nadpisujemy wyboru języka starych zapisów.

## Consequences

Nowy build/versionCode po testach; rc.1 i jego hashe zostają niezmienione.
Testy dawnych ograniczeń3 poziomów i startowego PL wymagają jawnej aktualizacji;
stare goldeny nie są wzorcem nowego kierunku artystycznego. Brak backendowego
zegara oznacza możliwość manipulowania czasem przez właściciela urządzenia.
Reset prestiżu ma osobne potwierdzenie i nie oznacza usunięcia profilu.
