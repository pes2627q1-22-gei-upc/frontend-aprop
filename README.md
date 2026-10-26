# AProp! · Frontend

Aplicació mòbil per descobrir i planificar activitats culturals a Catalunya. Projecte de FiveGuys per a PES, FIB–UPC.

## Estat actual

Base Flutter amb tema compartit, accés amb compte i navegació inferior entre Inici, Agenda, Descobreix, Avisos i Perfil. L'aplicació s'obre amb l'inici de sessió, que permet entrar o crear un compte (a Firebase, amb correu o Google; al mode demo, també amb nom d'usuari). Fins que no es verifica el correu, l'aplicació mostra la pantalla de verificació en lloc del contingut. Un cop dins, Inici mostra una capçalera fixa amb el logotip, els controls i la vista «Llista» seleccionada, seguida d'una llista paginada d'activitats del backend, o del repositori de demostració quan s'injecta. Inclou estats de càrrega, error amb reintent i llista buida. Perfil mostra el perfil propi i dona accés a Configuració.

A Android i web l'accés utilitza Firebase Auth, amb correu i Google; cal generar els fitxers locals de configuració abans de compilar (vegeu [la guia de Firebase](docs/firebase-auth.md)). El primer accés amb Google demana un nom d'usuari. A iOS i a les proves injectades amb `DemoAuthRepository`, l'accés és de demostració en memòria: `laiasoler` o `laia@aprop.cat`, contrasenya `Aprop2026!`. Aquest compte és fictici i no és una credencial de Firebase. La sincronització amb el backend necessita `API_BASE_URL`; sense URL es fa servir l'adaptador local descrit a la guia.

La llista d'Inici consumeix pàgines del backend des de la pàgina 0, amb «Carregar més activitats», actualització arrossegant, reintents sense perdre targetes i fotos remotes a llista/fitxa/previsualització del mapa. Els filtres continuen locals sobre les pàgines carregades; la connexió de filtres al servidor és la tasca següent. L'ordre estable, les dates desconegudes i la verificació en producció tenen límits explícits a DP-037. Vegeu [la guia d'integració de la llista](docs/inici-list-backend.md).

Event details (**Taiga #75**) open when an event image or title is tapped. The screen loads the selected event by ID, shows its description and source or creator, and handles loading, missing events and errors with retry. Bottom navigation remains available; each section keeps its navigation history and returning to the list preserves its scroll position.

Enrollment (**Taiga #82**) works from list cards and event details: «M’hi apunto» → «Apuntant…» → «Apuntat ✓». Both views share the same state, duplicate taps are ignored, and failed requests display an error and allow retry. Demo enrollments are isolated by account and survive sign-out/sign-in during the same app run; they are lost when the application restarts. The shared repository exposes confirmed activity IDs to the calendar.

Agenda (**Taiga #39 / #84**) shows a monthly calendar of the user's own plans: a dot on days with plans, today outlined and the selected day in green. Selecting a day lists its plans immediately, with a specific message for empty days and loading/error states with retry; a plan's image or title opens its details inside Agenda.

Descobreix i cerca (**Taiga #96**) incorpora «Per a tu», «Destacats» i una vista de cerca d’activitats. Reutilitza les targetes i les inscripcions compartides: obrir una fitxa conserva la consulta i el desplaçament, i apuntar-se actualitza també Inici i Agenda. La cerca demo ignora accents i majúscules; inclou espera mentre s’escriu, enviament amb el teclat, esborrat, recompte, càrrega, buit i error amb reintent. Les seleccions són exemples dels mockups, sense personalització real; «Persones» continua desactivat (DP-024). Vegeu [la guia del flux i l’arquitectura](docs/discovery.md).

Avisos (**Taiga #86**) mostra la bústia rebuda amb filtres «Tots», «Social», «Recordatoris» i «Recomanacions», ordre cronològic i agrupació per data. Obrir un avís el marca com a llegit després de confirmar-ho; els avisos d'activitats obren el detall compartit sense apuntar-hi l'usuari. Les sol·licituds permeten simular «Acceptar» o «Rebutjar», amb error i reintent. Els estats es conserven per compte durant la mateixa execució. Inclou càrrega, buit global/per filtre, error i actualització arrossegant la llista. Els perfils, l'API, les amistats reals, l'enviament push i la programació de recordatoris continuen pendents (DP-023). Els exemples són avisos històrics dels mockups, no recordatoris generats pels plans de l'usuari.

Perfil i Configuració (**Taiga #230 Frontend perfil**) segueixen els mockups aportats: identitat de la sessió, estadístiques/nivells demo, pestanyes «Plans fets» / «Creats per mi», quadrícula amb accés a les fitxes, edició de biografia/municipi i opció de copiar el nom d’usuari. Les activitats creades es relacionen per `ActivityCreator.userId`, mai pel nom. Configuració desa preferències en memòria per compte i permet tancar la sessió amb gestió d’errors. Calendar mostra «No connectat»; idioma/tema fosc, bloquejos, test i eliminació de compte continuen pendents. Els comptes nous no hereten els exemples de Laia. Vegeu [la guia de Perfil](docs/profile.md) i DP-032/DP-033.

Date and category filters (**Taiga #87**) now work in Inici with draft selection, Apply/Clear, inclusive day ranges and multiple categories. The applied selection is shared by Map/List and survives returning from details or switching sections. Filtering is local to loaded pages and map areas; server-side filtering and complete map category metadata remain pending (DP-035, DP-029). See [the filtering guide](docs/activity-filters.md). Location filtering and voice input inside the assistant remain disabled. The map/list selector is available. Tapping «Apuntat» opens an unenrollment confirmation (DP-027). Event chat, creator profiles and original-source links remain unavailable. With API configuration, main.dart injects HTTP adapters for catalogue, enrollment and assistant. Demo adapters remain available; contract gaps and production verification are tracked separately (DP-010, DP-016, DP-037).

The cultural assistant («Assistent», Fig. 10) opens from the Inici header, displays differentiated user/assistant bubbles, interprets activity type, municipality and date intervals, and renders matching recommendations with the standard `ActivityCard` synchronized with `EnrollmentViewModel`. Returning from an activity detail preserves the conversation.

Crear activitat (**Taiga #31**): el botó «Crear activitat» d'Inici obre un formulari per publicar una activitat no oficial amb títol, descripció, una categoria, data i hora d'inici, municipi, indicacions i preu opcionals, i una imatge de portada (una plantilla per defecte que es pot canviar). En publicar s'obre la fitxa, la persona creadora hi queda apuntada i l'activitat surt a la llista amb «Publicat per». Funciona amb dades de demostració; consulta [la guia](docs/create-activity.md).

Mapa d'Inici (**Taiga #21**): el selector «Mapa / Llista» mostra les activitats en un mapa de Google amb marcadors diferents per a les oficials, les d'usuaris i les d'amistats, agrupats amb un número quan són a prop. Tocar-ne un mostra una targeta amb «Veure activitat». Sense clau de Google Maps el mapa surt en gris; consulta [la guia](docs/inici-map.md).

See [the event details guide](docs/activity-details.md), [the enrollment walkthrough](docs/event-enrollment.md) and [the calendar guide](docs/calendar.md) for the implementation flows.

Vegeu també la [guia d'Avisos](docs/notifications.md), amb el flux del codi, les proves i els límits de la demostració.

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
    assistant/
      (mateixes capes que activities/)
    auth/
      (mateixes capes que activities/)
    notifications/
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
    assistant/
    auth/
    notifications/
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

Els mapes necessiten una clau de Google Maps: a Android, a `android/local.properties`; a la web, a `web/maps_key.js` (executa amb `--web-port 5000`). Sense clau el mapa no es veu. Vegeu [Google Maps](docs/google-maps.md).

Android i iOS són els objectius mòbils. La web és una eina de desenvolupament i no substitueix la comprovació en mòbil.

Abans de publicar una PR:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Col·laboració

Treballa en una branca de funcionalitat i obre la PR cap a `develop`, amb revisió d’un altre membre. Utilitza el número real de Taiga; per a la llista, **#77**. Explica quines parts funcionen amb dades de demostració i quina integració continua pendent. La carpeta creada no implica que la funcionalitat estigui implementada.
