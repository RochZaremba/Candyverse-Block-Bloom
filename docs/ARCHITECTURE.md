# Architektura aplikacji

## Decyzje

Flutter stable + Dart; w V1 **bez Flame** (ADR-0001) — CustomPainter/Flutter animacje wystarczą do statycznej siatki 8×8. Jeśli profiler lub złożoność wykażą, że Flame upraszcza projekt, najpierw ADR.

### Zasada nadrzędna

**Pure Dart engine**: reguły rozgrywki i ekonomii nie mogą importować Fluttera ani widgetów. Ekrany prezentują stan; wszystkie mutacje stanu przechodzą przez testowalne akcje/reduktory. RNG można wstrzyknąć, akcje deterministycznie testować.

## Proponowana struktura po `flutter create`

```text
lib/
  main.dart
  app/app.dart
  core/config/game_balance.dart
  core/theme/app_theme.dart
  core/localization/
  game/domain/{board,piece,game_state,game_action,game_engine,random_source}.dart
  game/application/game_controller.dart
  game/presentation/{game_screen,board_widget,piece_tray,fx_layer}.dart
  upgrades/{upgrade_model,upgrade_rules,upgrade_screen}.dart
  island/{island_state,island_screen,characters,building_widget}.dart
  progress/{economy,progress_state}.dart
  storage/{save_model,save_repository}.dart
  settings/{settings_model,settings_screen}.dart
  shared/widgets/
test/
assets/
android/
```

Używaj katalogów tylko wtedy, gdy mają kod, nie twórz pustych hierarchii dla ozdoby. Preferuj prosty model `ChangeNotifier`/`ValueNotifier` albo uzasadnioną małą bibliotekę; nie dodawaj Riverpod/BLoC wyłącznie dla prestiżu.

## State model

`AppSaveV1` ma co najmniej:

```text
schemaVersion: 1
nextRunId: int
lastAwardedRunId: int?     // monotoniczna identyfikacja rozliczonego runu
wallet: int
bestScore: int
island: {buildingLevels: map, ...}
settings: {language, sound, haptics, reduceMotion}
activeRun: null | {
   runId, board, tray, rngState, score, streak, totalClearedLines,
   chosenUpgradeLevels, eraserUses, pendingCoins, pendingUpgradeChoices,
   phase // playing | upgrade | needsEraserDecision
}
```

Weryfikuj wczytywane dane (zakresy 0..8, non-negative balances, enumy, wersja schematu). Nie rób niewidocznej utraty progresji po błędnym parsowaniu: najlepiej zachowaj backup i pokaż obsługiwalny fallback.

## Storage / transaction semantics

Start z prostym `SharedPreferencesAsync`, **jeden spójny JSON pod jednym kluczem** jako całość aplikacji; użyj funkcji serializacji/deserializacji i adaptera repozytorium. Należy sprawdzić dostępność i aktualny API biblioteki.

Zasada finalizacji runu: pure function `completeRun(state, runId)` sprawdza czy `runId` nie był już nagrodzony, oblicza nagrodę i zwraca jeden nowy `AppSaveV1`. Repozytorium zapisuje cały snapshot pod jednym kluczem, przed przejściem UI do wyniku. Testuj powtórzenie `completeRun()` i symulację restore. Jeśli zapis się nie uda, nie zgłaszaj nagrody jako nieodwracalnie zatwierdzonej.

**Uwaga:** SharedPreferences nie jest gwarancją pełnej transakcyjności/durability przy katastrofalnym błędzie systemu. Nie deklaruj takich gwarancji. Dla wymagań wykraczających poza V1 zaproponuj ADR migracji do transakcyjnej bazy.

## Moduły i testy

- `GameEngine`: `placePiece`, `getLegalPlacements`, `clearLines`, `calculateScore`, `pickTray`, `isGameOver`.
- `UpgradeRules`: `availableUpgrades`, `applyUpgrade`, `useEraser`.
- `Economy`: `calculateRunCoins`, `completeRun`, `purchaseBuildingLevel`.
- `SaveRepository`: `load`, `save`, `migrate`; testy ze sztucznym backendem.
- UI: prezentacja, walidowane akcje, krótki feedback haptic/audio, lifecycle pause.

## Zaimplementowany kontrakt T-002

`lib/game/domain/` zawiera niezmienne `Board`, `Piece`, `GameState`, akcję `PlacePiece` oraz `GameEngine`. `Cell` to rekord `(row, col)` używany także dla offsetów masek. Plansza przechowuje `String?` jako identyfikator skina; `null` oznacza puste pole. Modele kopiują kolekcje i odrzucają nieprawidłowe dane.

`placePiece(state, action)` zwraca `PlacementResult`: nowy stan, akceptację, pola umieszczenia, metadane jednoczesnego czyszczenia oraz flagę refill. Odrzucony ruch zwraca dokładnie ten sam obiekt stanu, bez pobrania zestawu. `isGameOver(result.state)` sprawdza pozostałe figury już po clear/refill. To reguła bazowa; wyjątek erasera i fazy ulepszeń należą do T-006.

W T-002 wprowadzono granicę `TraySource(Board)` dla jawnych trójek. T-003 dodaje produkcyjny generator opisany poniżej; callback pozostaje adapterem dla testów. Punktacja i snapshot RNG są już częścią stanu, a ekonomia/zapis będą dodane w kolejnych etapach.

`dart test test/game` sprawdza domenę w zwykłej maszynie Dart, a `flutter test` uruchamia także widget/golden Home. Pakiet `test` jest zależnością developerską, bez wpływu na zależności runtime aplikacji.

## Zaimplementowany kontrakt T-003

`GameEngine.seeded(seed: ...)` jest produkcyjną granicą startu runu; zachowano `GameEngine(traySource: ...)` dla jawnych trójek/testów. `GameState` zawiera teraz `score`, `streak`, `totalClearedLines`, `sugarRushLevel`, opcjonalny `rngState` oraz niezmienne `copyWith`. `PlacementResult.scoreDelta` udostępnia punkty bieżącego ruchu.

`RandomSource`/`SeededRandom` i `TrayGenerator` pozostają pure Dart. Każdy produkcyjny ruch odtwarza RNG ze stanu runu; tylko start/refill losują figury i skiny. Snapshot z T-008 musi przechowywać RNG, maski i skiny, bez ponownego losowania przy restore. `pickTray(board)` jest deterministycznym podglądem trójki z początkowego seeda, a nie akcją runu. `TraySource` nie serializuje stanu zewnętrznej funkcji. Balance jest kopiowany do niezmiennego snapshotu na wejściu silnika/generatora. Konkretny algorytm, wagi i kolejność mnożników opisuje ADR-0008.

## Zaimplementowany kontrakt T-004

`GameController` przedstawia snapshoty silnika poprzez `ChangeNotifier`; `fresh()` losuje seed przy starcie/retry (czas służy wyłącznie jako seed). `GameScreen` obsługuje drag figury z pierwszym polem 64 dp nad palcem, ghost legalnego i nielegalnego ruchu oraz alternatywę tap-select/tap-place. Przeciąganie jest wyłączne: drugi palec nie może zmienić figury ani wykonać tap-placement. Anulowanie gestu nie zmienia domeny. Lokalizacja podniesionej figury liczona jest względem Stack pod SafeArea.

Home otwiera realną grę. Wynik i liczba linii pochodzą z domeny; monety są tylko pending (bazowo 5 × linie), bez portfela przed T-008. Game-over zawiera retry i powrót do menu. Wyjście z aktywnego runu na razie wymaga potwierdzenia; trwałe resume/lifecycle snapshot zostanie dodane w T-008. Nie ma atrap ustawień, wyspy i kart upgrade. Testy obejmują drag, błędy, cancel, multi-touch, granice, refill, wynik, back i małe ekrany/tekst 2× oraz goldens na prawdziwych fontach.

## Zaimplementowany kontrakt T-005

`SettingsScope` i `FeedbackScope` znajdują się ponad MaterialApp, więc są wspólne dla wszystkich tras. `FeedbackService` bramkuje niezależnie dźwięk i haptykę, zatrzymuje audio przy mute/tle/dispose i nie blokuje akcji gry w razie błędu kanału. Android odtwarza trzy oryginalne WAV przez SoundPool; pakowanie WAV bez kompresji oraz lifecycle opisuje ADR-0009.

Zaakceptowany ruch tworzy `CandyFxEvent` i odpala cue place/clear. `FxLayer` jest nad samym gridem w IgnorePointer/RepaintBoundary; ma najwyżej 40 drobinek i czas z tokenów, respektuje ustawienie/OS reduced-motion oraz pause. Odrzucony ruch nie emituje FX/audio. Wspólny `showFeedbackSettings` działa z Home i aktywnej gry. Preferencje sesyjne zostaną zapisane w T-008; UI uczciwie informuje o obecnym ograniczeniu.

## Android / platform

- Portrait, Android API target >= 36 wg stanu na 2026-10-14; `minSdk 24` jako preferencja, potwierdź dostępność zależności.
- Nie włączaj `INTERNET` w release bez rzeczywistej potrzeby.
- Pakiet `applicationId` pozostaje do decyzji właściciela przed publikacją; `com.example.*` tylko w fazie dev.
- Build signing secrets poza Git i CI logami.
- Publikacja jest osobnym etapem wymagającym weryfikacji przez właściciela.

## Wartość złożoności

Brak backendu, chatów, gamifikacji godzinowej, zdalnego configu, telemetry SDK, IAP i AdMob w V1. Codex nie powinien wprowadzać warstw na przyszłość. Rozszerzenie monetization jest osobnym ADR i releasem V1.1+.
