# Google Play — checklista pierwszego wydania

**Stan weryfikacji wymagań:** 2026-10-15. Polityki podlegają zmianom: odczytaj na nowo przed wysłaniem aplikacji. Nie myl **gotowości technicznej** z gwarancją akceptacji przez Google.

## Wymagania bieżące

- **Target Android API 36+** dla nowych aplikacji od 2026-08-31 (Android 16). Ustaw i sprawdź faktyczny wynik buildu: https://support.google.com/googleplay/android-developer/answer/11926878?hl=pl
- Nowe **osobiste** konta Play Console utworzone po 2023-11-13: zamknięty test z co najmniej **12 testerami opt-in nieprzerwanie przez co najmniej 14 dni**, potem wniosek o dostęp produkcyjny. To nie jest automatyczne dopuszczenie: https://support.google.com/googleplay/android-developer/answer/14151465?hl=en-en
- Deklaracja grup wiekowych musi odzwierciedlać rzeczywiste przeznaczenie 10–16 i UX. Dla dzieci Families: https://support.google.com/googleplay/android-developer/answer/9867159?hl=pl
- Data safety + polityka prywatności są wymagane, także przy offline/no tracking: https://support.google.com/googleplay/android-developer/answer/10144311?hl=en
- Wskazówki podpisywania i AAB Flutter: https://docs.flutter.dev/deployment/android

## Do uzupełnienia przez właściciela

- [ ] Ostateczna nazwa po sprawdzeniu kolizji marki / znaków towarowych.
- [x] Docelowy `applicationId`: **`com.renvo.candyverse`**, zatwierdzony przez właściciela 2026-10-14. Konfiguracja i podpisany APK mają zatwierdzony identyfikator; nie sprawdzono jeszcze dostępności identyfikatora w Play Console.
- [x] Wydawca: **Renvo**, kontakt: **rochzaremba@gmail.com** (dane podane przez właściciela 2026-10-14).
- [ ] Publiczny, aktywny link do privacy policy bez placeholderów (może być statyczna strona GitHub Pages, nawet gdy repo z kodem jest prywatne).
- [ ] Klucz upload do podpisu `.aab`, przechowywany poza repo, backup klucza i haseł.
- [ ] Realne grafiki sklepu (ikona, feature graphic, screenshoty) zgodne z rzeczywistą grą i licencjami.
- [ ] Test account type / status oraz organizacja grupy testerów, jeśli zamknięte testy są wymagane.

## Release-gates dla agenta

1. `flutter doctor -v` i `flutter --version` w raporcie (nie zgaduj wersji).
2. `flutter pub get`, `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, `flutter test`.
3. Sprawdź finalny merged `AndroidManifest.xml`, zależności SDK, uprawnienia, połączenia sieciowe, orientację, edge-to-edge, min SDK i targetSdk.
4. Potwierdź brak reklam / trackerów / logowania, a jeśli realny projekt odbiega od opisu — aktualizuj dokumenty i uzyskaj decyzję.
5. Zbuduj `flutter build appbundle --release` z podpisem release po uzyskaniu klucza. Jeśli klucz niedostępny, nie twierdź, że masz podpisany plik publikacyjny.
6. Wygeneruj prawdziwe screenshoty urządzenia, sprawdź teksty PL/EN i politykę prywatności widoczną w ustawieniach.
7. Przekaż właścicielowi formularze do uzupełnienia: grupa docelowa, zawartość i IARC, Data safety, Ads = no, polityka prywatności i klasyfikacja.
8. Przeprowadź internal/closed test zgodnie z typem konta; dokumentuj feedback i poprawki.
9. **Nie klikaj publikacji produkcyjnej i nie podejmuj zobowiązań prawnych za wydawcę bez jego zgody.**

## FAQ

**Czy V1 bez reklam łatwiej zatwierdzić?** Nie ma gwarancji łatwiejszej weryfikacji. Usuwa jednak SDK reklamowe, zgody reklamowe i dodatkowe zobowiązania Families/ads. To decyzja o prostszej i bezpieczniejszej pierwszej wersji, nie sposób obejścia weryfikacji.

**Czy `flutter build appbundle` wystarczy?** Nie: do publikacji potrzebny jest prawidłowo podpisany AAB, konfiguracja aplikacji, materiały, polityka, deklaracje i wymagane testy.

**Czy 12 testerów wystarczy?** Wymóg dotyczy minimum opt-in; po testach wymagana może być ocena gotowości i osobny wniosek o dostęp produkcyjny. Zweryfikuj status w swoim Play Console.

## Bieżące przygotowanie2026-10-15

Konto właściciela **8799678699020536617**, osobiste, weryfikacja w toku.
Identyfikator nie stanowi dostępu API. Nie przesłano AAB do Play ani nie
zaakceptowano deklaracji/warunków w imieniu wydawcy.

- Kandydat1.0.0+1 ma podpisane APK/AAB. Audyt APK potwierdza SDK24/36,
  wyłączony backup/transfer, brak INTERNET i sześć bibliotek ELF64 z16KB alignment.
- Polityka PL/EN: [publiczny adres](https://rochzaremba.github.io/Candyverse-Block-Bloom/),
  źródło `public_pages/`; ta sama treść dostępna offline w Settings. Aktywność URL
  należy potwierdzić HTTP przed submission.
- Teksty PL/EN i autorskie grafiki: `assets/store/`; launcher/store512 w `assets/brand/`.
- Prywatny klucz: `/home/roch/.candyverse-signing/v1/`, poza Git; wymagany bezpieczny
  backup poza komputerem. Zachowaj certyfikat przy przejściu APK→Play (ADR-0014).
- Formularze: [Store declarations](STORE_DECLARATIONS.md). Nie zostały wysłane.
- Testy20min i smoke podpisanego entrypointu są w toku, bez deklaracji sukcesu.

Po weryfikacji konta: utworzyć wpis gry, zachować tożsamość podpisu, przesłać
zweryfikowany AAB na test internal/closed i wykonać wymagane etapy nowego konta
osobistego. Zakończenie testu12 osób/14 dni i dostęp produkcyjny wymagają
zewnętrznego czasu oraz rzeczywistego udziału testerów.
