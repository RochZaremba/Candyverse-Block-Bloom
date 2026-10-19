# Instrukcje dla agentów — Candyverse

**Czytaj przy KAŻDEJ nowej sesji i po kompakcji kontekstu.** Projekt ma działać w wielu sesjach i z wieloma agentami bez utraty decyzji. Odpowiadaj użytkownikowi po polsku; kod, commity i techniczne nazwy mogą być po angielsku.

## Przywrócenie kontekstu (obowiązkowo)

1. `git status --short --branch`, `git log -5 --oneline`, `git remote -v`.
2. Czytaj kolejno: `README.md` → `docs/INDEX.md` → `docs/STATUS.md` → `docs/ROADMAP.md`.
3. Przed zmianą logiki czytaj `docs/GAME_DESIGN.md`; przed UI `docs/VISUAL_DIRECTION.md`; przed architekturą właściwe ADR-y.
4. Wybierz **jedno** zadanie z `docs/ROADMAP.md`, uwzględniając zależności i obecny kod.
5. Przed edycją sprawdź działające testy i niezacommitowane zmiany. Nie nadpisuj pracy użytkownika lub innego agenta.
6. Po zakończeniu każdej sesji zaktualizuj `docs/STATUS.md` (realny stan, ostatni commit/PR, testy, kolejny krok, blokery).

## Hierarchia źródeł prawdy

- Zamrożony zakres i ograniczenia: `docs/PRD.md`.
- Dokładne zasady gry i ekonomii: `docs/GAME_DESIGN.md`.
- Techniczne decyzje: zaakceptowane `docs/adr/*.md`.
- Styl, animacje, dostępność: `docs/VISUAL_DIRECTION.md` i `assets/design_tokens.json`.
- Przebieg wykonania: `docs/ROADMAP.md` (zadania) i `docs/STATUS.md` (stan rzeczywisty).
- Aktualny kod jest źródłem prawdy wyłącznie o implementacji; rozbieżności z kontraktem **naprawiaj lub opisuj, nie ukrywaj**.

Nie zmieniaj po cichu ADR/PRD, żeby dopasować dokumentację do błędnego kodu. Nową decyzję zapisz jako kolejny ADR, z uzasadnieniem i konsekwencjami; decyzje biznesowe eskaluj do właściciela.

## Nienaruszalne zasady V1

- Android, Flutter stable, offline-first, bez backendu / reklam / IAP / loginu / analityki / push / sieci społecznościowych.
- Plansza 8×8, zestawy trzech elementów, trzy ulepszenia run-only, jedna wyspa z trzema ulepszanymi obiektami i czterema bohaterami.
- Estetyka bardzo kolorowa, cukierkowa, **spójna i dopracowana**; brak generycznych placeholderów i emoji udających grafikę.
- Grupą docelową są również osoby poniżej 13 lat: brak presji czasowej, streaków dniowych, kar za przerwy, dark patterns, stroboskopów i trików z reklamami.
- Logika silnika to czysty Dart niezależny od UI; sterowalne RNG i testy brzegowe; wynik i nagrody deterministyczne.
- Minimalne uprawnienia Androida, zasady danych deklarowane na podstawie audytu kodu i SDK.

## Kiedy wolno rozszerzać zakres?

Tylko jeśli to **konieczna** poprawka do stabilności, dostępności albo wymogów sklepu. W innym wypadku dodaj pomysł do `docs/POST_V1.md` i nie implementuj w tej iteracji.

## Workflow Git / GitHub

- `main` pozostaje stabilny. Pracuj w branchu `feat/<opis>`, `fix/<opis>`, `chore/<opis>`, `docs/<opis>`.
- Małe, logiczne commity w stylu Conventional Commits. Nie czekaj do końca całego projektu z pierwszym commitem.
- Jeden pionowy, testowalny fragment funkcjonalności na PR; używaj `.github/PULL_REQUEST_TEMPLATE.md`.
- Przed PR: format, analyze, unit/widget tests, a w fazie release także build i manualny smoke test.
- Twórz i pushuj PR-y wyłącznie gdy GitHub/CLI/remote rzeczywiście dostępne. Merge po zielonych kontrolach i wymaganych review, tylko z uprawnieniami; nie obchodź branch protection.
- Nie twierdź, że CI, test lub merge wykonał się, jeśli brak potwierdzenia narzędziowego.
- Unikaj równoległych zmian w tych samych plikach: agent-koordynator dzieli pracę modułami i integruje po testach.

## Definicja ukończenia pojedynczego zadania

1. Kod spełnia kryteria akceptacji przypisanego `T-xxx`.
2. Odpowiednie testy są napisane i uruchomione, lub dokładnie zaznaczono brak środowiska testowego.
3. Brak nieaktywnych guzików i udawanych funkcjonalności.
4. `docs/STATUS.md` zaktualizowany; numer commita i PR podane, jeśli powstały.
5. Nie naruszono zasad prywatności / dostępności / zakresu.

## Ostatni komunikat każdej sesji

Zwięźle podaj: **zrobione / sprawdzone komendy i wyniki / branch-commit-PR / niedokończone / jedno konkretne następne zadanie**. Zostaw repo w stanie, z którego nowy agent może kontynuować bez rozmowy źródłowej.

## Zatwierdzone rozszerzenie po rc.1

Właściciel2026-10-15 jawnie zamówił Candy Kingdom:30 poziomów, prestiż/gwiazdki,
pasywny dochód, renderowane assety i nowy UX/EN. Dla T-012–T-018 stosuj
`docs/KINGDOM_EXPANSION.md` i ADR-0016 zamiast historycznych limitów V1
(3 poziomy, brak dochodu pasywnego, dawne postacie). Pozostałe zasady offline,
prywatności, dostępności i testów obowiązują. To zgoda na wskazany zakres,
nie na dalsze niezlecone funkcje.

## Roguelite Evolution — zamówienie 2026-10-18

Właściciel jawnie zamówił12 ulepszeń,3 ścieżki i4 synergie (T-021).
Stosuj `docs/adr/0020-roguelite-evolution.md` zamiast limitu3 efektów dla nowych
runów. Stare runy zachowują reguły legacy; zapisy schema1/2 migrują do3.
Zasady offline, brak presji czasu i idempotentne nagrody pozostają wymagane.
