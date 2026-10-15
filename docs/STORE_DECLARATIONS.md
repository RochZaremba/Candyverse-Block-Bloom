# Materiały do formularzy Play Console

Stan2026-10-15. To przygotowanie na podstawie kodu, nie formularze wysłane do
Google. Właściciel zatwierdza końcowe odpowiedzi, tożsamość i zgodność prawną.
Wymagany jest końcowy audyt podpisanego artefaktu, opisany w raporcie release.

| Formularz | Stan techniczny V1 / odpowiedź do sprawdzenia |
| --- | --- |
| App access | Cała funkcjonalność bez konta, hasła i dodatkowych instrukcji dostępu |
| Ads | Brak reklam i reklamowych SDK |
| Purchases | Brak IAP; Candy Coins wyłącznie za wyczyszczone linie, bez realnych pieniędzy |
| Data safety | Gra nie wysyła danych poza urządzenie; lokalny postęp i ustawienia przez DataStore, brak backendu i telemetrii |
| Account deletion | Gra nie tworzy kont; Settings oferuje potwierdzane usunięcie lokalnych danych |
| Target audience | Projekt obejmuje10–16 lat: uwzględnić10–12 oraz13–15 i16–17 zgodnie z rzeczywistym przeznaczeniem; nie zawyżać wieku w celu pominięcia Families |
| Content rating | Wypełnić aktualny kwestionariusz IARC; nie przypisywać samodzielnie oficjalnej oceny |
| Privacy | Dwujęzyczna polityka w `public_pages/index.html`; publiczny URL musi być faktycznie aktywny |
| Contact | Renvo, rochzaremba@gmail.com; dane identyfikacyjne konta uzupełnia właściciel |

W `pubspec.lock` zależności runtime to Flutter SDK i shared_preferences z
platformowymi implementacjami. Android używa DataStore oraz własnego SoundPool
do lokalnych WAV. `flutter_test`, `integration_test`, biblioteka test i fonty
golden nie są funkcjami produkcyjnego entrypointu. Finalny manifest i graf
Gradle są rozstrzygające dla obecności SDK/uprawnień.

Polityka obejmuje także możliwość napisania e-maila i zwykłe logi połączeń
hostingu strony. Nie należy mylić tych oddzielnych usług z transmisją danych
przez aplikację. Reset usuwa profil i lokalną kwarantannę, nie gwarantuje
usunięcia kopii utworzonych przez uprzywilejowane narzędzia systemowe.

Konto Play Console8799678699020536617 jest osobiste i pozostaje w trakcie
weryfikacji (potwierdzenie właściciela). Nie potwierdzono utworzenia wpisu aplikacji
ani nie przesłano wydania. Dla nowego konta osobistego Google wymaga co najmniej12 testerów opt-in nieprzerwanie14 dni,
następnie wniosku o dostęp produkcyjny. Konto organizacji wymaga rzeczywistych
danych organizacji; wybór nie służy obchodzeniu testów. Nie można wykonać
tych etapów samym buildem AAB.

Źródła Google sprawdzone2026-10-15:
[dane użytkowników](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en),
[Families](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en),
[testy nowych kont](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en),
[target API](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en).
