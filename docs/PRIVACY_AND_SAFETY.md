# Privacy & Safety — zasady produktowe

> Wersja 2026-10-14. Przy publikacji sprawdź najnowsze zasady Google Play i przepisy dla obszarów dystrybucji. To checklista techniczno-produktowa, a nie zastępstwo porady prawnej.

## Grupa wiekowa i bezpieczeństwo

Gra projektowana również dla odbiorców 10–12 lat, zatem może podlegać Families. Nie deklaruj sztucznie wyższej grupy wieku po to, by obchodzić polityki. Ostateczne zaznaczenia wieku są odpowiedzialnością wydawcy i muszą odzwierciedlać realny UX, grafiki i treści.

Nie wolno projektować presji do częstego otwierania aplikacji: brak codziennych streaków, limitów wygasających prezentów, kar za brak logowania, losowego płatnego gacha, pseudo-losowych reklam lub fałszywych komunikatów pilności. Użytkownik zawsze może bez konsekwencji zakończyć sesję.

## V1 — dane i uprawnienia

Zakładamy: lokalny zapis postępu i ustawień; brak kont, backendu, reklam, analityki, geolokalizacji, push, identyfikatorów marketingowych, pobierania danych osobowych i nadmiarowych Android permissions. **Po implementacji przeprowadź faktyczny audyt `pubspec.lock`, Gradle, AndroidManifest (wraz z manifest merger), żądań sieciowych oraz SDK**.

Jeżeli rzeczywisty kod przeczy powyższym założeniom, napraw kod albo ujawnij zmianę w ADR i zaktualizuj politykę. Nie wypełniaj Play Data safety „z pamięci”.

### Przechowywanie danych

- Stan rozgrywki, saldo monet, stan wyspy i ustawienia lokalnie.
- W aplikacji wyraźny reset danych z potwierdzeniem.
- Odinstalowanie może usunąć postęp. Jeśli Android backup przywraca dane, należy ten przypadek sprawdzić i ujawnić; nie deklaruj bezpodstawnie zawsze całkowitego usunięcia.
- Nie przechowuj rzeczywistych danych dzieci. Same preferencje / game state nie muszą być danymi osobowymi, ale analizuj faktyczny kontekst i przepływy.

## Polityka prywatności

Wzory: [PL](../templates/PRIVACY_POLICY_PL.md), [EN](../templates/PRIVACY_POLICY_EN.md). **Wymagają uzupełnienia identyfikacji wydawcy, kontaktu, wersji gry i audytu SDK przed publicznym użyciem.** Google Play wymaga publicznie dostępnego, aktywnego URL oraz dostępu w aplikacji, także przy braku deklarowanej kolekcji danych. Nie publikuj wersji z placeholderami.

## Przyszłe reklamy (NIE w V1)

Reklamy to osobny etap i nowy ADR. Przed integracją: weryfikacja Families, certyfikacji SDK tam, gdzie dotyczy, reklam niepersonalizowanych dla dzieci, mechanizmów zgód, content rating, Data safety oraz zgodności kreacji z wiekiem. Nie umieszczaj reklam tak, by dzieci przypadkowo klikały w nie zamiast w sterowanie. **Nie dodawaj AdMob w ramach „przygotowania na przyszłość” do V1.**

## Źródła urzędowe (sprawdzone 2026-10-14)

- Google Play Families: https://support.google.com/googleplay/android-developer/answer/9893335?hl=en
- Target audience: https://support.google.com/googleplay/android-developer/answer/9867159?hl=pl
- User data & privacy: https://support.google.com/googleplay/android-developer/answer/10144311?hl=en
