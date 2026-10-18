# AProp! · Frontend

Aplicació mòbil per descobrir i planificar activitats culturals a Catalunya. Projecte de FiveGuys per a PES, FIB–UPC.

## Estat actual

Base Flutter amb tema compartit, accés amb compte i navegació inferior entre Inici, Agenda, Descobreix, Avisos i Perfil. L'aplicació s'obre amb l'inici de sessió, que accepta el nom d'usuari o el correu, i permet crear un compte. Fins que no es verifica el correu, l'aplicació mostra la pantalla de verificació en lloc del contingut. Un cop dins, Inici mostra una capçalera fixa amb el logotip, els controls i la vista «Llista» seleccionada, seguida d'una llista desplaçable d'activitats de demostració. Inclou estats de càrrega, error amb reintent i llista buida. Perfil mostra provisionalment qui ha iniciat la sessió i el botó per tancar-la; Agenda, Descobreix i Avisos encara mostren textos provisionals.

L'accés funciona amb comptes de demostració en memòria, que es perden en tancar l'aplicació. Per provar-lo, entra amb `laiasoler` o `laia@aprop.cat` i la contrasenya `Aprop2026!`, o crea un compte nou. Els comptes nous queden pendents de verificar; com que no s'envia cap correu, «Ja l'he verificat» simula que s'ha obert l'enllaç. Firebase, l'alta de l'usuari al backend i l'accés amb Google estan pendents; el botó de Google es mostra desactivat.

Event details (**Taiga #75**) open when an event image or title is tapped. The screen loads the selected event by ID, shows its description and source or creator, and handles loading, missing events and errors with retry. Bottom navigation remains available; each section keeps its navigation history and returning to the list preserves its scroll position.

Enrollment (**Taiga #82**) works from list cards and event details: «M’hi apunto» → «Apuntant…» → «Apuntat ✓». Both views share the same state, duplicate taps are ignored, and failed requests display an error and allow retry. Demo enrollments are isolated by account and survive sign-out/sign-in during the same app run; they are lost when the application restarts. The shared repository exposes confirmed activity IDs for the calendar teammate, whose screen is still pending on this branch.

Location, date, category, map and assistant controls are still disabled. Unenrollment, event chat, creator profile and original-source links remain unavailable. The catalogue, authentication and enrollment use demo repositories; backend integration remains pending (DP-010 for enrollment).

See [the event details guide](docs/activity-details.md) and [the enrollment walkthrough](docs/event-enrollment.md) for the implementation flow and calendar integration contracts.

## Estructura

```text
lib/
  main.dart
  app/
    aprop_app.dart
    navigation/
    theme/
  core/
    widgets/
  features/
    activities/
      models/
      repositories/
      data/
      presentation/
        screens/
        view_models/
        widgets/
    auth/
      (mateixes capes que activities/)
assets/
  images/
  branding/
  icons/
test/
  widget_test.dart
  app/
  features/
    activities/
    auth/
docs/
  architecture.md
```

Llegeix [les regles d’arquitectura](docs/architecture.md) abans d’afegir codi. Els fitxers `.gitkeep` permeten conservar les carpetes encara buides a Git i es poden retirar quan hi hagi fitxers reals.

## Desenvolupament

Executa les ordres des de l’arrel del repositori, on hi ha `pubspec.yaml`:

```bash
flutter pub get
flutter devices
flutter run -d ID_DEL_DISPOSITIU
```

Substitueix `ID_DEL_DISPOSITIU` per l’identificador del teu Android. Per revisar la interfície ràpidament al navegador:

```bash
flutter run -d chrome
```

Android i iOS són els objectius mòbils. La web és una eina de desenvolupament i no substitueix la comprovació en mòbil.

Abans de publicar una PR:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Col·laboració

Treballa en una branca de funcionalitat i obre la PR cap a `develop`, amb revisió d’un altre membre. Utilitza el número real de Taiga; per a la llista, **#77**. Explica quines parts funcionen amb dades de demostració i quina integració continua pendent. La carpeta creada no implica que la funcionalitat estigui implementada.
