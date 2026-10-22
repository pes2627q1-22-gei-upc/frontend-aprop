# Firebase Auth: inici de sessió real

A **Android** i a la **web** (que només fem servir per desenvolupar), l'app fa servir Firebase Auth
(projecte `aprop-919ec`) per al registre amb correu i contrasenya, la verificació del correu i l'accés amb
Google. A iOS continua amb els comptes de demostració (`DemoAuthRepository`), perquè encara no està
configurat.

- **Android:** l'accés amb Google obre el selector de comptes del sistema (paquet `google_sign_in`).
- **Web:** Firebase obre una finestra emergent de Google (`signInWithPopup`). `localhost` ja és un domini
  autoritzat per defecte; si s'hi accedeix des d'un altre domini, s'ha d'afegir a *Authentication →
  Configuració → Dominis autoritzats*.

El codi és a `lib/features/auth/data/firebase_auth_repository.dart` i es tria a `lib/main.dart`.

## Fitxers de configuració

`flutterfire configure` genera dos fitxers. **Sense ells l'app no compila**:

- `lib/firebase_options.dart`
- `android/app/google-services.json`

Es versionen perquè el repo és privat (DP-004): amb un `git pull` n'hi ha prou. Només cal tornar-los a
generar si canvia la configuració de Firebase (una plataforma nova, una app nova...):

1. Demana accés al projecte de Firebase (rol Editor).
2. Instal·la [Node.js LTS](https://nodejs.org) i després `npm install -g firebase-tools`.
3. `firebase login` (a PowerShell, `firebase.cmd login`) amb el compte que té accés al projecte. Si el
   navegador obre un altre compte, fes servir `firebase login --no-localhost` i obre l'enllaç en una
   finestra d'incògnit.
4. `dart pub global activate flutterfire_cli`
5. Des de l'arrel del repo:

   ```bash
   dart pub global run flutterfire_cli:flutterfire configure --project=aprop-919ec --platforms=android,web --android-package-name=cat.fiveguys.aprop
   ```

## Accés amb Google a Android: empremta SHA-1 de cada ordinador

A Android, l'accés amb Google només funciona als ordinadors que tenen la seva **SHA-1 de depuració**
registrada a l'app Android de Firebase. Si no hi és, el selector de comptes falla. A la web no cal.

1. Obtén la SHA-1 (vegeu també `docs/google-maps.md`). Amb Windows en castellà o català, `keytool` falla si
   no es força l'anglès:

   ```bash
   keytool -J-Duser.language=en -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

2. Afegeix-la a la consola (*Configuració del projecte → Les teves apps → app Android → Afegeix una
   empremta digital*) o amb la CLI:

   ```bash
   firebase apps:android:sha:create <APP_ID> <SHA1> --project aprop-919ec
   ```

3. Torna a executar `flutterfire configure`: `google-services.json` ha d'incloure els clients OAuth que es
   creen en afegir la SHA-1.

## Què és provisional (DP-026)

El backend té `POST /auth/sync` en una branca encara no fusionada. Fins que no s'hi connecti l'app:

- el nom i els cognoms es desen al `displayName` de Firebase;
- el nom d'usuari es desa només al dispositiu, i encara no se'n comprova la unicitat;
- només es pot entrar amb el correu: si s'escriu un nom d'usuari, l'app demana el correu.
