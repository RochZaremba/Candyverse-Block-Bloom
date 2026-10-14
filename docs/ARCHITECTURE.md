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

## Android / platform

- Portrait, Android API target >= 36 wg stanu na 2026-10-14; `minSdk 24` jako preferencja, potwierdź dostępność zależności.
- Nie włączaj `INTERNET` w release bez rzeczywistej potrzeby.
- Pakiet `applicationId` pozostaje do decyzji właściciela przed publikacją; `com.example.*` tylko w fazie dev.
- Build signing secrets poza Git i CI logami.
- Publikacja jest osobnym etapem wymagającym weryfikacji przez właściciela.

## Wartość złożoności

Brak backendu, chatów, gamifikacji godzinowej, zdalnego configu, telemetry SDK, IAP i AdMob w V1. Codex nie powinien wprowadzać warstw na przyszłość. Rozszerzenie monetization jest osobnym ADR i releasem V1.1+.
