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

Contenen la clau d'API de Firebase, així que **no es versionen** (són al `.gitignore`, DP-004). Cada persona
els ha de generar al seu ordinador la primera vegada (i si canvia la configuració de Firebase o es renova
la clau). `firebase.json` sí que es versiona: no té cap clau i indica a `flutterfire` on generar-los.
La CI no en necessita els reals: escriu versions de mostra (sense cap clau) abans d'`analyze`, perquè les proves
i el build de depuració no es connecten a Firebase.

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

## Enllaços dels correus (DP-031)

Els enllaços dels correus (verificació i contrasenya) obren la pàgina de Firebase
(`aprop-919ec.firebaseapp.com/__/auth/action`), que fa servir la clau d'API que Firebase té associada al
projecte. Aquesta clau no és la de l'app i no es pot canviar: si s'esborra, la pàgina diu que l'enllaç «ha
caducat o ja s'ha fet servir».

- **No esborreu aquesta clau** a Google Cloud → *APIs i serveis → Credencials*. Està restringida a llocs web
  (`aprop-919ec.firebaseapp.com`, `aprop-919ec.web.app`, `frontend-aprop.onrender.com`) i a les API
  Identity Toolkit i Token Service.
- Els correus surten d'un Gmail de l'equip (*Authentication → Templates → SMTP settings*).
- L'URL d'acció no es pot personalitzar amb el pla Spark (`EMAIL_TEMPLATE_UPDATE_NOT_ALLOWED`), ni tan sols
  amb SMTP propi.

## Recuperar la contrasenya

«Has oblidat la contrasenya?» del login obre `ForgotPasswordScreen`, que crida `sendPasswordResetEmail`
(Firebase envia el correu en català). L'enllaç obre la mateixa pàgina de Firebase que la verificació, on es
tria la contrasenya nova, i després es pot entrar a l'app amb ella. La pantalla no diu mai si el correu té
compte: el missatge és el mateix en tots dos casos (DP-047). Entre enviaments cal esperar 60 s.

## Backend: nom d'usuari (`POST /auth/sync`)

Després d'entrar a Firebase, l'app demana al backend l'usuari de la base de dades (`HttpUserSyncRepository`). El
primer cop el crea amb el nom d'usuari triat. L'adreça es passa en executar l'app:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

**Sense `API_BASE_URL`** (fins que hi hagi servidor), el nom d'usuari es desa al dispositiu
(`DemoUserSyncRepository`). El nom `laiasoler` hi està reservat per poder provar l'error de nom repetit.

## Què és provisional (DP-026, DP-028)

- El nom i els cognoms es desen al backend (`PATCH /users/me`) en un sol camp; l'app els separa pel primer espai.
- Només es pot entrar amb el correu: si s'escriu un nom d'usuari, l'app demana el correu.
- El contracte de `POST /auth/sync` és d'una branca del backend encara no fusionada.
