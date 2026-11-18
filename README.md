# AProp! · Frontend

Aplicació mòbil per descobrir i planificar activitats culturals a Catalunya. Projecte de FiveGuys per a PES, FIB–UPC.

## Estat actual

Logotip (**Taiga #262**): Inici i l’accés comparteixen `APropLogo`, amb un PNG transparent que s’integra
amb el fons crema, conserva la composició de la marca i evita el rectangle de la imatge original.
Detalls i comprovacions a [la guia de marca](docs/branding.md).

Base Flutter amb tema compartit, accés amb compte i navegació inferior entre Inici, Agenda, Descobreix, Avisos i Perfil. L'aplicació s'obre amb l'inici de sessió, que permet entrar o crear un compte (a Firebase, amb correu o Google; al mode demo, també amb nom d'usuari). Fins que no es verifica el correu, l'aplicació mostra la pantalla de verificació en lloc del contingut. Un cop dins, Inici mostra una capçalera fixa amb el logotip, els controls i la vista «Llista» seleccionada, seguida d'una llista paginada d'activitats del backend, o del repositori de demostració quan s'injecta. Inclou estats de càrrega, error amb reintent i llista buida. Perfil mostra el perfil propi i dona accés a Configuració.

A Android i web l'accés utilitza Firebase Auth, amb correu i Google; cal generar els fitxers locals de configuració abans de compilar (vegeu [la guia de Firebase](docs/firebase-auth.md)). El primer accés amb Google demana un nom d'usuari. A iOS i a les proves injectades amb `DemoAuthRepository`, l'accés és de demostració en memòria: `laiasoler` o `laia@aprop.cat`, contrasenya `Aprop2026!`. Aquest compte és fictici i no és una credencial de Firebase. La sincronització amb el backend necessita `API_BASE_URL`; sense URL es fa servir l'adaptador local descrit a la guia.

La llista d'Inici consumeix pàgines del backend des de la pàgina 0, amb «Carregar més activitats», actualització arrossegant, reintents sense perdre targetes i fotos remotes a llista/fitxa/previsualització del mapa. Dates i Categories es passen al servidor abans de paginar; la selecció múltiple combina consultes amb IDs de `/categories`. L'ordre estable, les dates desconegudes i la verificació en producció tenen límits explícits a DP-037/DP-038. Vegeu [la guia d'integració de la llista](docs/inici-list-backend.md) i [la dels filtres al servidor](docs/inici-server-filters.md).

Event details (**Taiga #75**) open when an event image or title is tapped. The screen loads the selected event by ID, shows its description and source or creator, and handles loading, missing events and errors with retry. Bottom navigation remains available; each section keeps its navigation history and returning to the list preserves its scroll position.

Enrollment (**Taiga #82**) works from list cards and event details: «M’hi apunto» → «Apuntant…» → «Apuntat ✓». Both views share the same state, duplicate taps are ignored, and failed requests display an error and allow retry. Demo enrollments are isolated by account and survive sign-out/sign-in during the same app run; they are lost when the application restarts. The shared repository exposes confirmed activity IDs to the calendar.

Agenda (**Taiga #39 / #84**) shows a monthly calendar of the user's own plans: a dot on days with plans, today outlined and the selected day in green. Selecting a day lists its plans immediately, with a specific message for empty days and loading/error states with retry; a plan's image or title opens its details inside Agenda.

Descobreix i cerca (**Taiga #96**) consulta `/events/recommended` per a «Per a tu», `/events/popular` per a «Destacats» i `/events/search` per a la cerca paginada des de 0, amb total real i «Carregar més activitats». Preferències buides es diferencien dels errors i no bloquegen els destacats. Un refresc fallit conserva les seccions/resultats confirmats, amb avís i reintent. Les targetes, detall i inscripcions continuen compartits amb Inici/Agenda. Demo conserva les seleccions dels mockups; «Persones» i la pantalla del test d’interessos continuen pendents. Contracte i límits de ranking a DP-041/DP-024 i [la guia HTTP](docs/discovery-backend.md).

Avisos (**Taiga #86**) consumeix la bústia HTTP del UUID real retornat pel perfil autenticat. Conserva els filtres «Tots», «Social», «Recordatoris» i «Recomanacions», ordre cronològic i agrupació per data. Els tipus es consulten a `/notificationtypes`, sense deduir-los d’IDs fixos. Obrir un avís confirma la lectura al servidor abans de navegar al detall compartit, sense apuntar-hi l’usuari. Inclou càrrega, buit global/per filtre, error, reintent i actualització. Un avís no desapareix si la seva activitat o persona ja no està disponible; els tipus desconeguts es conserven a «Tots». La resposta d’amistat continua només a Demo: les accions socials són fora de l’Sprint 1, segons confirmació de l’usuari. Generació automàtica, push, autorització per destinatari i política de zona horària necessiten confirmació/backend; Render no ha respost durant la verificació (DP-039). Vegeu [la integració d’Avisos](docs/notifications-backend.md) i [el traspàs al backend](docs/notifications-backend-handoff.md).

Perfil i Configuració (**Taiga #230**) consulten el compte autenticat amb `GET /users/me`, editen nom/nom d’usuari/biografia amb `PATCH /users/me`, pugen l’avatar de la galeria amb `POST /users/me/avatar` i consulten `GET /users/me/created-events`. «Mostrar els meus plans» es desa al servidor; la resta de preferències d’avisos es mostren pendents. Les operacions esperen confirmació i els errors de les activitats creades no amaguen el perfil. El mode HTTP mostra comptadors i XP reals, sense deduir assistència ni nivells/llindars del mockup. Historial confirmat, municipi, amistats, Calendar, test, idioma/tema i eliminació continuen pendents. El mode Demo conserva els exemples i l’edició local. Vegeu [la integració de Perfil](docs/profile-backend.md), [els mockups](docs/profile.md) i DP-040.

Date and category filters (**Taiga #87**) work in Inici with draft selection, Apply/Clear, inclusive day ranges and multiple categories. Applying a new selection requests page zero with those filters; further pages and refresh retain them. Category options come from the repository, with loading/error/retry states. The applied selection is shared by Map/List and survives returning from details or switching sections. The map still filters locally because its endpoint lacks filter parameters and category metadata; unknown categories are reported with an action to open the filtered list (DP-029/DP-038). See [the filtering guide](docs/activity-filters.md). Location filtering and voice input inside the assistant remain disabled. The map/list selector is available. Tapping «Apuntat» opens an unenrollment confirmation (DP-027). Event chat, creator profiles and original-source links remain unavailable. With API configuration, main.dart injects HTTP adapters for catalogue, enrollment and assistant. Demo adapters remain available; contract gaps and production verification are tracked separately (DP-010, DP-016, DP-037).

L’assistent cultural («Assistent», fig. 10) s’obre des del botó flotant d’Inici. La tasca **#261** amaga la barra de navegació inferior durant el flux del xat: l’espai queda disponible per als missatges i el camp de consulta. La fletxa i el retorn del sistema recuperen Inici amb la barra, els filtres i el desplaçament conservats. Les dreceres a altres seccions també restauren la barra. La conversa i les inscripcions continuen als ViewModels compartits, inclòs el retorn de la fitxa d’una recomanació. Les fitxes obertes des del xat mantenen aquest flux sense barra (DP-048); les obertes des de les seccions habituals conserven el menú. Detall a [l’arquitectura](docs/architecture.md).

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
