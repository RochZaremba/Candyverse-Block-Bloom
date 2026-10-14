# Test Plan i definition of done

## Quality gates PR

Po T-001, jeśli istnieje Flutter SDK:

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Na PR od T-004: co najmniej jeden widget test na główny flow. Na T-010/T-011 dodatkowo smoke test na fizycznym Androidzie/emulatorze i `flutter build appbundle` z odpowiednią konfiguracją (podpis dopiero gdy klucz dostarczony).

## Wymagane przypadki silnika

- T-002: legalne umieszczenie, zderzenie, przekroczenie krawędzi, brak zmiany stanu dla ruchu nielegalnego, clear 1 row/1 column, intersection clear raz, multi-line, game-over, pusta tray/refill po 3 sztukach.
- T-003: seeded RNG / replay, fairness generatora przy ograniczonej przestrzeni, score placement, combo reset, combo cap, Sugar Rush math.
- T-006: próg 5/10/15, queue przy wielu liniach, brak pustych kart, cap upgrades, eraser na pojedynczej zajętej komórce, zero reward za eraser, stan bez ruchów z dostępnym eraserem.
- T-008: coin balance, negative balance rejected, purchase next level, max level, insufficient funds, `completeRun` twice → award once, restore in the middle of run, interrupted save, malformed JSON/schema mismatch.

## Interakcje UI (ręczne / automatyczne)

1. Cold start → Home (PL/EN) → Play.
2. Drag block z ghost + nielegalna pozycja → brak utraty figury.
3. Ukończenie linii → efekt animacji/score/coin pending.
4. Milestone → wybór upgrade → faktyczna zmiana efektu.
5. Game over → raz nagroda → Replay oraz Island.
6. Upgrade Tree, House, Fountain → od razu inny wygląd.
7. Tap character → reakcja; ponowne uruchomienie → zachowana wyspa.
8. Pauza/tło → powrót → ta sama plansza i figury.
9. Mute/haptics/reduced motion/reset → działanie przełączników, reset z potwierdzeniem.
10. Back navigation / nowy run / minimalny ekran / skalowanie tekstu → brak overflow/crashy.

## Testy nieletnich i UX

- Brak reklam, zakupów, retencji wymuszanej karą, mechanizmów presji i nieproszonych powiadomień.
- Brak migotania/stroboskopów; pomniejszona liczba animacji działa.
- Brak tekstów zawstydzających przy porażce, brak przerwań w trakcie ważnego ruchu.
- Dobrze widoczne potwierdzenie resetu danych i konsekwencje braku chmury.

## Wizualny quality gate

- 6 ekranów nie przypomina gołego Material Scaffold.
- Te same tokeny i styl postaci w całej aplikacji.
- Postacie własne lub prawidłowo licencjonowane, minimum dwie animacje.
- Realne screenshoty ekranu 320–360 dp i dużego telefonu; złote testy z referencją, jeśli środowisko je wspiera.
- Czytelne linie/plansza, użyteczny touch target, kontrast wystarczający mimo pastelowej estetyki.

## Performance

Oceń na średniopółkowym sprzęcie: przynajmniej krótki profil animacji pełnego clear oraz wyspy. 60 FPS to **cel**, nie twierdzenie bez pomiaru. Sprawdź lifecycle, audio i wibracje. Profiling wyniku dołącz do PR T-010, albo zaznacz brak narzędzia.

## Release exit gate

Rzeczywisty podpisany AAB / brak klucza wskazany jako blocker, `targetSdk >= 36` zweryfikowany, testy manualne potwierdzone, Data safety i policy zweryfikowane przeciw rzeczywistym zależnościom, listing odpowiada grze, status dokumentacji aktualny.
